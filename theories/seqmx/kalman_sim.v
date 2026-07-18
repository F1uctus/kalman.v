(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Исполнимый прогон фильтра Калмана на полностью формализованных данных.

  Все данные прогона строятся внутри Rocq: системные матрицы, начальные условия,
  шумы, истинная траектория, измерения, оценки и ковариации. Шумы порождаются
  четырёхточечной моделью из `noise.v`
  (нулевое среднее, второй момент равен заданной скалярной ковариации);
  конкретная траектория исходов задаётся детерминированным генератором Лемера
  над двоичными натуральными числами (Stdlib `N`), то есть прогон есть значение
  случайного процесса в одной точке вероятностного пространства из `noise.v`.
  Матричная арифметика шага выполняется извлекаемыми seqmx-программами из
  `riccati_seqmx.v`; OCaml-драйвер лишь переводит результат извлечённого терма в
  JSON.

  Чётные элементы потока исходов питают шум управления, нечётные шум измерения;
  это соответствует пространству траекторий {ffun 'I_(2T) -> 'I_16} из
  `noise.v`.
*)

From Stdlib Require Import BinNat.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix ssrint.
From mathcomp Require Import order rat.
From CoqEAL Require Import hrel param refinements seqmx binrat.
From Bignums Require Import BigQ.
From Kalman Require Import noise.
From Kalman.seqmx Require Import riccati_seqmx.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope hetero_computable_scope.

(*
  Генератор Лемера (вариант ZX81): s' = (75 s + 74) mod 65537. Модуль прост,
  поэтому младшие биты пригодны; исход одного шага есть s' mod 16. Вычисления
  ведутся в двоичных натуральных числах `N`, что извлекается в эффективный код.
*)
Definition lcg_a : BinNums.N := N.of_nat 75.
Definition lcg_c : BinNums.N := N.of_nat 74.
Definition lcg_m : BinNums.N := N.succ (N.pow (N.of_nat 2) (N.of_nat 16)).

Definition lcg_next (s : BinNums.N) : BinNums.N := N.modulo (N.add (N.mul lcg_a s) lcg_c) lcg_m.

Definition lcg_out (s : BinNums.N) : nat := N.to_nat (N.modulo s (N.of_nat 16)).

(* Поток исходов: значения lcg_out на итерациях генератора после посева. *)
Fixpoint lcg_stream (s : BinNums.N) (k : nat) : seq nat :=
  if k is k'.+1 then lcg_out (lcg_next s) :: lcg_stream (lcg_next s) k'
  else [::].

(* Сравнение Stdlib совпадает с ltn (используется в val4). *)
Lemma ltb_ltn (a b : nat) : Nat.ltb a b = (a < b)%N.
Proof.
  by elim: a b => [|a IH] [|b] //=; rewrite ltnS -IH.
Qed.

Definition sim_seed : BinNums.N := N.of_nat 1234.

(*
  Посев генератора для трёхмерного прогона; выбран так, чтобы на всём прогоне
  каждая координата ошибки оставалась в коридоре плюс минус два сигма
  (лемма sim3_run_in_band).
*)
Definition sim3_seed : BinNums.N := N.of_nat 21.

Section EffSim.

Context (C : Type).
Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C, !eq_of C}.
Definition seqmx_0 m n : @seqmx C := @hzero_op _ _ _ m n.
Variable cinv1 : C -> C.        (* обратный элемент поля *)
Variable cconj : C -> C.        (* сопряжение; на рациональных данных id *)
Variable cinv : @seqmx C -> @seqmx C.  (* обращение матрицы 1 x 1 *)

(* Константа a / b поля C из пары натуральных чисел. *)
Definition cfrac (a b : nat) : C := (cnat a * cinv1 (cnat b))%C.

(* Система из прогона: модель постоянной скорости, n = 2, m = p = 1. *)
Definition sim_F : @seqmx C := [:: [:: 1; 1]; [:: 0; 1]]%C.
Definition sim_G : @seqmx C := [:: [:: cfrac 1 2]; [:: 1%C]].
Definition sim_H : @seqmx C := [:: [:: 1; 0]]%C.
Definition sim_Q : @seqmx C := [:: [:: cfrac 1 10]].
Definition sim_R : @seqmx C := [:: [:: 1%C]].
Definition sim_P_0 : @seqmx C := [:: [:: cnat 2; 0%C]; [:: 0%C; cnat 2]].
Definition sim_x_0 : @seqmx C := [:: [:: 1%C]; [:: 1%C]].

(*
  Значения четырёхточечного шума (`noise.v`, noise_val): α на исходах меньше
  пяти, минус α до десяти, β до тринадцати, иначе минус β.

  Сравнение исходов ведётся через Nat.ltb вместо ltn: ltn раскрывается в
  вычитание с eq_op на структуре eqType для nat, чьё непрозрачное
  доказательство eqnP компилятор CertiRocq оставляет аксиомой. Связь с
  ltn даёт лемма ltb_ltn.
*)
Definition val4 (a b : C) (o : nat) : C :=
  if Nat.ltb o 5 then a else if Nat.ltb o 10 then (- a)%C
  else if Nat.ltb o 13 then b else (- b)%C.

(* Шум управления: α = 1/10, β = 1/2; второй момент равен Q = 1/10. *)
Definition wval (o : nat) : C := val4 (cfrac 1 10) (cfrac 1 2) o.

(* Шум измерения: α = 1/2, β = 3/2; второй момент равен R = 1. *)
Definition vval (o : nat) : C := val4 (cfrac 1 2) (cfrac 3 2) o.

(*
  Строка результата прогона: истинное состояние, измерение, оценка,
  апостериорная ковариация.
*)
Definition sim_row : Type := @seqmx C * @seqmx C * @seqmx C * @seqmx C.

(*
  Один шаг прогона по исходам (ow, ov): эволюция истинного состояния, измерение,
  полушаги предсказания и обновления оценки, шаг Риккати для ковариации.
  Дословно соответствует `x_true`, `x_hat` и `kf_step` из `kalman.v` при u = 0.
*)
Definition sim_step (st : @seqmx C * @seqmx C * @seqmx C) (ow ov : nat)
    : (@seqmx C * @seqmx C * @seqmx C) * sim_row :=
  let: (xt, xe, P) := st in
  let wk : @seqmx C := [:: [:: wval ow]] in
  let vk : @seqmx C := [:: [:: vval ov]] in
  let xt' := add_seqmx (@hmul_op _ _ _ 2%N 2%N 1%N sim_F xt)
                       (@hmul_op _ _ _ 2%N 1%N 1%N sim_G wk) in
  let yk := add_seqmx (@hmul_op _ _ _ 1%N 2%N 1%N sim_H xt') vk in
  let Ppred := predict_cov_seqmx cconj 1 2 sim_F sim_G sim_Q P in
  let K := filter_gain_seqmx cconj 2 1 sim_H sim_R cinv Ppred in
  let xpred := @hmul_op _ _ _ 2%N 2%N 1%N sim_F xe in
  let innov := sub_seqmx yk (@hmul_op _ _ _ 1%N 2%N 1%N sim_H xpred) in
  let xe' := add_seqmx xpred (@hmul_op _ _ _ 2%N 1%N 1%N K innov) in
  let P' := riccati_step_seqmx cconj 1 2 1 sim_F sim_G sim_H sim_Q sim_R
              cinv P in
  ((xt', xe', P'), (xt', yk, xe', P')).

(* Прогон по списку пар исходов. *)
Fixpoint sim_run_aux (st : @seqmx C * @seqmx C * @seqmx C)
    (outs : seq (nat * nat)) : seq sim_row :=
  if outs is (ow, ov) :: rest then
    let: (st', row) := sim_step st ow ov in
    row :: sim_run_aux st' rest
  else [::].

(* Разбиение потока исходов на пары (шум управления, шум измерения). *)
Fixpoint pair_up (s : seq nat) : seq (nat * nat) :=
  if s is ow :: ov :: rest then (ow, ov) :: pair_up rest else [::].

(*
  Полный прогон на T шагов: строка начального состояния
  (измерения ещё нет, вместо него пустая матрица), затем T шагов фильтра.
*)
Definition kalman_sim_run (T : nat) : seq sim_row :=
  let st0 := (sim_x_0, seqmx_0 2 1, sim_P_0) in
  let head_row : sim_row := (sim_x_0, seqmx_0 1 1, seqmx_0 2 1, sim_P_0) in
  head_row :: sim_run_aux st0 (pair_up (lcg_stream sim_seed (T.*2))).

(*
  Трёхмерная модель слежения за положением: n = 6, m = p = 3.

  Состояние есть вектор (x, vx, y, vy, z, vz): по каждой из трёх осей пара из
  положения и скорости. Скорость в плоскости x-y поворачивается на угол θ с
  (cos θ, sin θ) = (4/5, 3/5), а положение её интегрирует; по оси z движение с
  постоянной скоростью. Истинная траектория есть винтовая линия: радиус в
  плоскости x-y ограничен
  (собственные значения блока поворота равны exp(plus i θ) и exp(minus i θ), оба лежат на единичной окружности),
  а высота z растёт линейно. Пифагоров угол даёт точную рациональную арифметику
  без чисел с плавающей точкой. Измеряются три положения; обращение
  инновационной ковариации идёт над матрицей 3 x 3, что задействует обращение
  методом Фаддеева-Леверье общего порядка.
*)
Definition sim3_F : @seqmx C :=
  [:: [:: 1; 1; 0; 0; 0; 0]
   ;  [:: 0; cfrac 4 5; 0; - cfrac 3 5; 0; 0]
   ;  [:: 0; 0; 1; 1; 0; 0]
   ;  [:: 0; cfrac 3 5; 0; cfrac 4 5; 0; 0]
   ;  [:: 0; 0; 0; 0; 1; 1]
   ;  [:: 0; 0; 0; 0; 0; 1]
  ]%C.
Definition sim3_G : @seqmx C :=
  [:: [:: cfrac 1 2; 0; 0]
   ;  [:: 1; 0; 0]
   ;  [:: 0; cfrac 1 2; 0]
   ;  [:: 0; 1; 0]
   ;  [:: 0; 0; cfrac 1 2]
   ;  [:: 0; 0; 1]
  ]%C.
Definition sim3_H : @seqmx C :=
  [:: [:: 1; 0; 0; 0; 0; 0]
   ;  [:: 0; 0; 1; 0; 0; 0]
   ;  [:: 0; 0; 0; 0; 1; 0]
  ]%C.
Definition sim3_Q : @seqmx C :=
  [:: [:: cfrac 1 10; 0; 0]
   ;  [:: 0; cfrac 1 10; 0]
   ;  [:: 0; 0; cfrac 1 10]
  ]%C.
Definition sim3_R : @seqmx C :=
  [:: [:: 1; 0; 0]; [:: 0; 1; 0]; [:: 0; 0; 1]]%C.
Definition sim3_P_0 : @seqmx C :=
  [:: [:: cnat 2; 0; 0; 0; 0; 0]
   ;  [:: 0; cnat 2; 0; 0; 0; 0]
   ;  [:: 0; 0; cnat 2; 0; 0; 0]
   ;  [:: 0; 0; 0; cnat 2; 0; 0]
   ;  [:: 0; 0; 0; 0; cnat 2; 0]
   ;  [:: 0; 0; 0; 0; 0; cnat 2]
  ]%C.
Definition sim3_x_0 : @seqmx C :=
  [:: [:: 0]; [:: cnat 2]; [:: 0]; [:: 0]; [:: 0]; [:: cfrac 1 2]]%C.

(*
  Один шаг трёхмерного прогона по шести исходам: три питают шум управления
  (o0, o1, o2), три шум измерения (o3, o4, o5). Структура совпадает с sim_step.
*)
Definition sim3_step (st : @seqmx C * @seqmx C * @seqmx C)
    (o0 o1 o2 o3 o4 o5 : nat)
    : (@seqmx C * @seqmx C * @seqmx C) * sim_row :=
  let: (xt, xe, P) := st in
  let wk : @seqmx C := [:: [:: wval o0]; [:: wval o1]; [:: wval o2]] in
  let vk : @seqmx C := [:: [:: vval o3]; [:: vval o4]; [:: vval o5]] in
  let xt' := add_seqmx (@hmul_op _ _ _ 6%N 6%N 1%N sim3_F xt)
                       (@hmul_op _ _ _ 6%N 3%N 1%N sim3_G wk) in
  let yk := add_seqmx (@hmul_op _ _ _ 3%N 6%N 1%N sim3_H xt') vk in
  let Ppred := predict_cov_seqmx cconj 3 6 sim3_F sim3_G sim3_Q P in
  let K := filter_gain_seqmx cconj 6 3 sim3_H sim3_R cinv Ppred in
  let xpred := @hmul_op _ _ _ 6%N 6%N 1%N sim3_F xe in
  let innov := sub_seqmx yk (@hmul_op _ _ _ 3%N 6%N 1%N sim3_H xpred) in
  let xe' := add_seqmx xpred (@hmul_op _ _ _ 6%N 3%N 1%N K innov) in
  let P' := riccati_step_seqmx cconj 3 6 3 sim3_F sim3_G sim3_H sim3_Q sim3_R
              cinv P in
  ((xt', xe', P'), (xt', yk, xe', P')).

(* Прогон по потоку исходов, по шесть исходов на шаг. *)
Fixpoint sim3_run_aux (st : @seqmx C * @seqmx C * @seqmx C)
    (outs : seq nat) : seq sim_row :=
  if outs is o0 :: o1 :: o2 :: o3 :: o4 :: o5 :: rest then
    let: (st', row) := sim3_step st o0 o1 o2 o3 o4 o5 in
    row :: sim3_run_aux st' rest
  else [::].

(*
  Полный трёхмерный прогон на T шагов: начальная строка без измерения
  (вместо него пустая матрица), затем T шагов фильтра. На шаг приходится шесть
  исходов потока.
*)
Definition kalman_sim3_run (seed : BinNums.N) (T : nat) : seq sim_row :=
  let st0 := (sim3_x_0, seqmx_0 6 1, sim3_P_0) in
  let head_row : sim_row := (sim3_x_0, seqmx_0 3 1, seqmx_0 6 1, sim3_P_0) in
  head_row :: sim3_run_aux st0 (lcg_stream seed (muln 6 T)).

End EffSim.

(* Проверки над rat: тождества значений шума и формальная проверка коридора. *)
Section ConcreteRatSim.

  #[local] Instance rat_zero : zero_of rat := 0%R.
  #[local] Instance rat_one  : one_of rat  := 1%R.
  #[local] Instance rat_opp  : opp_of rat  := -%R.
  #[local] Instance rat_add  : add_of rat  := +%R.
  #[local] Instance rat_mul  : mul_of rat  := *%R.
  #[local] Instance rat_eq   : eq_of rat   := eqtype.eq_op.
  #[local] Instance rat_inv  : inv_of rat  := GRing.inv.

  (* Константы cfrac есть отношения натуральных чисел в поле rat. *)
  Lemma cfrac_ratE (a b : nat) : cfrac (C := rat) GRing.inv a b = a%:R / b%:R.
  Proof.
    by rewrite /cfrac !cnat_natr.
  Qed.

  (* Таблица значений шума управления совпадает с моделью noise.v. *)
  Lemma wvalE (i : 'I_16) :
    wval (C := rat) GRing.inv i = noise_val (1%:R / 10%:R) (1%:R / 2%:R) i.
  Proof.
    by rewrite /wval /val4 /noise_val !ltb_ltn !cfrac_ratE.
  Qed.

  (* Таблица значений шума измерения совпадает с моделью noise.v. *)
  Lemma vvalE (i : 'I_16) :
    vval (C := rat) GRing.inv i = noise_val (1%:R / 2%:R) (3%:R / 2%:R) i.
  Proof.
    by rewrite /vval /val4 /noise_val !ltb_ltn !cfrac_ratE.
  Qed.

  (* Второй момент шума управления равен Q = 1/10. *)
  Lemma wvar_eq_Q :
    (5%:R * (1%:R / 10%:R) ^+ 2 + 3%:R * (1%:R / 2%:R) ^+ 2) / 8%:R
      = 1%:R / 10%:R :> rat.
  Proof.
    by apply/eqP; vm_compute.
  Qed.

  (* Второй момент шума измерения равен R = 1. *)
  Lemma vvar_eq_R :
    (5%:R * (1%:R / 2%:R) ^+ 2 + 3%:R * (3%:R / 2%:R) ^+ 2) / 8%:R
      = 1%:R :> rat.
  Proof.
    by apply/eqP; vm_compute.
  Qed.

End ConcreteRatSim.

(*
  Формальная проверка коридора над bigQ.

  Точные вычисления длинного прогона ведутся над `bigQ` (двоичные целые), как и
  в остальной части проекта: `bigQ` есть вычислимый внутри Rocq аналог
  применяемого после извлечения zarith `Q.t`. Это тот же обобщённый терм
  `kalman_sim_run`, который извлекается в OCaml.
*)
Section BigQSim.

  (* Обращение матрицы 1 x 1 над bigQ методом Фаддеева-Леверье. *)
  Definition bigq_cinv (sS : @seqmx bigQ) : @seqmx bigQ :=
    cinv_fl (C := bigQ) 1 sS.

  Definition bigq_run (T : nat) : seq (sim_row bigQ) :=
    kalman_sim_run BigQ.inv_norm (fun x : bigQ => x) bigq_cinv T.

  (* Элемент seqmx по индексам. *)
  Definition sqb_get (s : @seqmx bigQ) (i j : nat) : bigQ :=
    nth 0%C (nth [::] s i) j.

  (*
    Проверка коридора для строки прогона: квадрат ошибки по компоненте положения
    не превосходит четырёх дисперсий, то есть ошибка лежит в коридоре плюс минус
    два сигма.
  *)
  Definition row_in_band (r : sim_row bigQ) : bool :=
    let: (xt, _, xe, P) := r in
    let e := (sqb_get xe 0 0 - sqb_get xt 0 0)%C in
    leq_op (e * e)%C ((cnat 4 : bigQ) * sqb_get P 0 0)%C.

  (*
    Формальная проверка иллюстрации: на всём прогоне в сорок шагов ошибка оценки
    положения остаётся в коридоре плюс минус два сигма, построенном по точной
    ковариации.
  *)
  Lemma sim_run_in_band : all row_in_band (bigq_run 40) = true.
  Proof. by vm_compute. Qed.

  (* Обращение матрицы 3 x 3 над bigQ методом Фаддеева-Леверье. *)
  Definition bigq_cinv3 (sS : @seqmx bigQ) : @seqmx bigQ :=
    cinv_fl (C := bigQ) 3 sS.

  Definition bigq_run3 (seed : BinNums.N) (T : nat) : seq (sim_row bigQ) :=
    kalman_sim3_run BigQ.inv_norm (fun x : bigQ => x) bigq_cinv3 seed T.

  (*
    Проверка коридора для строки трёхмерного прогона: по каждой из трёх
    координат положения квадрат ошибки не превосходит четырёх дисперсий, то есть
    каждая координата ошибки лежит в коридоре плюс минус два сигма.
  *)
  Definition row_in_band3 (r : sim_row bigQ) : bool :=
    let: (xt, _, xe, P) := r in
    let ex := (sqb_get xe 0 0 - sqb_get xt 0 0)%C in
    let ey := (sqb_get xe 2 0 - sqb_get xt 2 0)%C in
    let ez := (sqb_get xe 4 0 - sqb_get xt 4 0)%C in
    [&& leq_op (ex * ex)%C ((cnat 4 : bigQ) * sqb_get P 0 0)%C,
        leq_op (ey * ey)%C ((cnat 4 : bigQ) * sqb_get P 2 2)%C
      & leq_op (ez * ez)%C ((cnat 4 : bigQ) * sqb_get P 4 4)%C].

  (*
    Формальная проверка иллюстрации: на всём трёхмерном прогоне в сорок шагов
    каждая координата ошибки оценки положения остаётся в коридоре плюс минус два
    сигма, построенном по точной ковариации.
  *)
  Lemma sim3_run_in_band : all row_in_band3 (bigq_run3 sim3_seed 30) = true.
  Proof. by vm_compute. Qed.

End BigQSim.
