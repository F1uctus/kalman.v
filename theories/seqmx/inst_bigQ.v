(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Инстанцирование исполнимых программ на рациональных числах `bigQ` библиотеки
  Bignums.

  Двоичная арифметика `bigQ` даёт точные вычисления, пригодные для длинных
  прогонов внутри Rocq. Тип `bigQ` не является `comUnitRingType`, поэтому
  операции слоя CoqEAL берутся из `CoqEAL.binrat`, а связь со спецификацией
  устанавливается не напрямую, а через гетерогенное отношение.

  Мост параметричности $"rat" -> "bigQ"$ через RseqmxC r_ratBigQ.

  Уточнение из `riccati.v` доказано на одном кольце (`Rseqmx`, поле = rat).
  Здесь оно поднимается до гетерогенного отношения `RseqmxC r_ratBigQ`,
  связывающего абстрактную матрицу `'M[rat]` напрямую с seqmx-программой над
  `bigQ`. Композиция (`RseqmxC rAC = Rseqmx \o list_R (list_R rAC)`) выполняется
  через те же экземпляры `RseqmxC_*` библиотеки CoqEAL и поэлементные уточнения
  `binrat` (`refine_ratBigQ_*`). Раздел `BridgeBigQ` зеркалит `RefineRiccati`,
  но с `Rseqmx -> RseqmxC`.

  Итоговая теорема `riccati_iter_seqmxC` устанавливает, что итерация шага
  Риккати над `bigQ` уточняет абстрактную `rat`-итерацию спецификации.

  Раздел `BigQSim` содержит точные прогоны фильтра и формальные проверки того,
  что ошибка оценки остаётся в коридоре плюс минус два сигма.
*)

From Stdlib Require Import BinNat.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx binint binrat.
From Bignums Require Import BigQ.
From Kalman Require Import mxnotation riccati_def.
From Kalman.seqmx Require Import support inverse riccati sim.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section BridgeBigQ.

  Notation RC a b := (RseqmxC r_ratBigQ (nat_Rxx a) (nat_Rxx b)).

  Variable conj : rat -> rat.
  Variable conjC : bigQ -> bigQ.
  Context (rconj : refines (r_ratBigQ ==> r_ratBigQ) conj conjC).

  Lemma refinesC_ctr (a b : nat) (A : 'M[rat]_(a, b)) (sA : @seqmx bigQ)
      (rA : refines (RC a b) A sA) :
    refines (RC b a) (map_mx conj A^T) (ctr_seqmx conjC a b sA).
  Proof.
    rewrite /ctr_seqmx.
    exact: (refines_apply
              (refines_apply (refine_map_seqmx r_ratBigQ r_ratBigQ b a) rconj)
              (refines_apply (refine_trseqmx r_ratBigQ a b) rA)).
  Qed.

  Lemma refinesC_mulmx (a b c : nat) (X : 'M[rat]_(a, b)) (Y : 'M[rat]_(b, c))
      (sX sY : @seqmx bigQ)
      (rX : refines (RC a b) X sX) (rY : refines (RC b c) Y sY) :
    refines (RC a c) (X *m Y) (@hmul_op _ _ _ a b c sX sY).
  Proof.
    exact: refines_apply.
  Qed.

  Lemma refinesC_addmx (a b : nat) (X Y : 'M[rat]_(a, b)) (sX sY : @seqmx bigQ)
      (rX : refines (RC a b) X sX) (rY : refines (RC a b) Y sY) :
    refines (RC a b) (X + Y) (add_seqmx sX sY).
  Proof.
    exact: refines_apply.
  Qed.

  Lemma refinesC_oppmx (a b : nat) (X : 'M[rat]_(a, b)) (sX : @seqmx bigQ)
      (rX : refines (RC a b) X sX) :
    refines (RC a b) (- X) (opp_seqmx sX).
  Proof.
    exact: refines_apply.
  Qed.

Section System.

  Variables (m n p : nat).
  Variables (F : 'M[rat]_n) (G : 'M[rat]_(n, m)) (H : 'M[rat]_(p, n)).
  Variables (Q : 'M[rat]_m) (R_m : 'M[rat]_p).
  Variables (sF sG sH sQ sR_m : @seqmx bigQ).

  Hypothesis rF : refines (RC n n) F sF.
  Hypothesis rG : refines (RC n m) G sG.
  Hypothesis rH : refines (RC p n) H sH.
  Hypothesis rQ : refines (RC m m) Q sQ.
  Hypothesis rR_m : refines (RC p p) R_m sR_m.

  Variable cinv : @seqmx bigQ -> @seqmx bigQ.

  Hypothesis cinv_correct : forall (S : 'M[rat]_p) (sS : @seqmx bigQ),
    refines (RC p p) S sS -> refines (RC p p) (invmx S) (cinv sS).

  Lemma predict_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC n n)
      (predict_cov conj F G Q P) (predict_cov_seqmx conjC m n sF sG sQ sP).
  Proof.
    rewrite /predict_cov /predict_cov_seqmx.
    have rX := refinesC_mulmx (refinesC_mulmx rF rP) (refinesC_ctr rF).
    have rY := refinesC_mulmx (refinesC_mulmx rG rQ) (refinesC_ctr rG).
    exact: refines_apply.
  Qed.

  Lemma innov_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC p p)
      (innov_cov conj H R_m P) (innov_cov_seqmx conjC n p sH sR_m sP).
  Proof.
    rewrite /innov_cov /innov_cov_seqmx.
    have rX := refinesC_mulmx (refinesC_mulmx rH rP) (refinesC_ctr rH).
    exact: refines_apply.
  Qed.

  Lemma filter_gain_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC n p)
      (filter_gain conj H R_m P)
      (filter_gain_seqmx conjC n p sH sR_m cinv sP).
  Proof.
    rewrite /filter_gain /filter_gain_seqmx.
    have rinv := cinv_correct (innov_cov_seqmxC rP).
    exact: (refinesC_mulmx (refinesC_mulmx rP (refinesC_ctr rH)) rinv).
  Qed.

  Lemma update_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC n n)
      (update_cov conj H R_m P)
      (update_cov_seqmx conjC n p sH sR_m cinv sP).
  Proof.
    rewrite /update_cov /update_cov_seqmx.
    have rK := filter_gain_seqmxC rP.
    have rKH := refinesC_mulmx rK rH.
    have r1 : refines (RC n n) 1%:M (iseqmx1 n) by rewrite iseqmx1E; tc.
    have rsub := refinesC_addmx r1 (refinesC_oppmx rKH).
    exact: (refinesC_mulmx rsub rP).
  Qed.

  Lemma riccati_step_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC n n)
      (riccati_step conj F G H Q R_m P)
      (riccati_step_seqmx conjC m n p sF sG sH sQ sR_m cinv sP).
  Proof.
    rewrite /riccati_step /riccati_step_seqmx.
    exact: (update_cov_seqmxC (predict_cov_seqmxC rP)).
  Qed.

  Lemma riccati_iter_seqmxC (k : nat) (P_0 : 'M[rat]_n) (sP_0 : @seqmx bigQ)
      (rP_0 : refines (RC n n) P_0 sP_0) :
    refines (RC n n)
      (iter k (riccati_step conj F G H Q R_m) P_0)
      (iter k (riccati_step_seqmx conjC m n p sF sG sH sQ sR_m cinv) sP_0).
  Proof.
    elim: k => [|k IHk] /=; first exact: rP_0.
    exact: (riccati_step_seqmxC IHk).
  Qed.

  End System.

End BridgeBigQ.

(*
  Формальная проверка коридора над bigQ.

  Точные вычисления длинного прогона ведутся над `bigQ` (двоичные целые), как и
  в остальной части проекта: `bigQ` есть вычислимый внутри Rocq аналог
  применяемого после извлечения zarith `Q.t`. Это тот же обобщённый терм
  `kalman_sim_run`, который инстанцируется в `inst_Q.v`.
*)
Section BigQSim.

  (* Обращение матрицы $1 times 1$ над bigQ методом Фаддеева-Леверье. *)
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

  (* Обращение матрицы $3 times 3$ над bigQ методом Фаддеева-Леверье. *)
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
    Формальная проверка иллюстрации: на всём трёхмерном прогоне в тридцать шагов
    каждая координата ошибки оценки положения остаётся в коридоре плюс минус два
    сигма, построенном по точной ковариации.
  *)
  Lemma sim3_run_in_band : all row_in_band3 (bigq_run3 sim3_seed 30) = true.
  Proof. by vm_compute. Qed.

End BigQSim.
