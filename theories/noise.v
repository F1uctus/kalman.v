(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Конечная вероятностная модель шумов фильтра Калмана.

  Одношаговый шум: четырёхточечное симметричное распределение со значениями плюс
  минус $α$ и плюс минус $β$ на шестнадцати равновероятных исходах 'I_16
  (значениям $α$ и минус $α$ отвечают по пять исходов, значениям $β$ и минус $β$
  по три). Среднее равно нулю, второй момент равен $(5 α^2 + 3 β^2) / 8$;
  подбором $α$ и $β$ второй момент совпадает с заданной скалярной ковариацией
  шума.

  Совместная модель процесса шумов: равномерное распределение на функциях из
  конечного горизонта 'I_T в пространство исходов одного шага. Такое
  распределение равно произведению одношаговых равномерных распределений;
  частные распределения каждой координаты равномерны. Ключевая лемма
  `sum_path_coord` (сумма значений функции одной координаты по всем траекториям)
  выводится из тождества `bigA_distr_bigA`.

  Распределения берутся из infotheo (`probability.fdist`, `fdist_uniform`);
  ожидание `Exp` определено в `expectation.v` формулой оператора `Ex` из
  infotheo.
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix.
From mathcomp.algebra_tactics Require Import ring.
From infotheo.probability Require Import fdist.
From Kalman Require Import expectation kalman.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Local Open Scope ring_scope.
Local Open Scope fdist_scope.

Section FourPoint.

  Variable ℂ : numFieldType.
  Variables α β : ℂ.

  (* Значение шума по исходу одного шага. *)
  Definition noise_val (i : 'I_16) : ℂ :=
    if (i < 5)%N then α else if (i < 10)%N then - α
    else if (i < 13)%N then β else - β.

  (* Равномерное распределение на шестнадцати исходах. *)
  Definition noise_dist : fdist ℂ 'I_16 := fdist_uniform (card_ord 16).

  (* Сумма значений по всем исходам равна нулю. *)
  Lemma sum_noise_val : \sum_(i < 16) noise_val i = 0.
  Proof.
    rewrite !big_ord_recl big_ord0 /noise_val /=.
    by ring.
  Qed.

  (* Сумма квадратов значений: десять раз $α^2$ и шесть раз $β^2$. *)
  Lemma sum_noise_val2 :
    \sum_(i < 16) (noise_val i) ^+ 2 = 10%:R * α ^+ 2 + 6%:R * β ^+ 2.
  Proof.
    rewrite !big_ord_recl big_ord0 /noise_val /=.
    by rewrite !sqrrN; ring.
  Qed.

  (* Одношаговый шум как случайный вектор размерности один. *)
  Definition noise_rv (i : 'I_16) : 'cV[ℂ]_1 := (noise_val i)%:M.

  (* Нулевое среднее одношагового шума. *)
  Lemma noise_mean : Exp noise_dist noise_rv = 0.
  Proof.
    rewrite /Exp.
    under eq_bigr do
      rewrite fdist_uniformE card_ord /noise_rv -scalemx1 scalerA.
    by rewrite -scaler_suml -mulr_sumr sum_noise_val mulr0 scale0r.
  Qed.

  (* Второй момент одношагового шума. *)
  Lemma noise_second_moment :
    \sum_(i < 16) noise_dist i * (noise_val i) ^+ 2 =
      (5%:R * α ^+ 2 + 3%:R * β ^+ 2) / 8%:R.
  Proof.
    under eq_bigr do rewrite fdist_uniformE card_ord.
    rewrite -mulr_sumr sum_noise_val2.
    have n16 : (16%:R : ℂ) != 0 by rewrite pnatr_eq0.
    have n8 : (8%:R : ℂ) != 0 by rewrite pnatr_eq0.
    by field.
  Qed.

End FourPoint.

Section PathSpace.

  Variable ℂ : numFieldType.

  (* Горизонт процесса; индексы шагов лежат в 'I_T. *)
  Variable T : nat.

  (* Пространство исходов одного шага. *)
  Variable A : finType.
  Hypothesis cardA_gt0 : (0 < #|A|)%N.

  (*
    Покоординатная сумма по пространству траекторий исходов.

    По тождеству `bigA_distr_bigA` сумма значений функции от одной координаты по
    всем траекториям распадается в произведение: по координате j суммируются
    значения h, по каждой из остальных T - 1 координат суммируется единица, что
    даёт множитель `#|A| ^ T.-1`.
  *)
  Lemma sum_path_coord (h : A -> ℂ) (j : 'I_T) :
    \sum_(t : {ffun 'I_T -> A}) h (t j) =
      (#|A| ^ T.-1)%:R * \sum_(a : A) h a.
  Proof.
    pose F := fun (i : 'I_T) (a : A) => if i == j then h a else (1 : ℂ).
    have rhsE : \sum_(t : {ffun 'I_T -> A}) \prod_(i : 'I_T) F i (t i) =
                \sum_(t : {ffun 'I_T -> A}) h (t j).
      apply: eq_bigr => t _.
      rewrite (bigD1 j) //= /F eqxx big1 ?mulr1 // => i ij.
      by rewrite (negbTE ij).
    have lhsE : \prod_(i : 'I_T) \sum_(a : A) F i a =
                (#|A| ^ T.-1)%:R * \sum_(a : A) h a.
      rewrite (bigD1 j) //=.
      have -> : \sum_(a : A) F j a = \sum_(a : A) h a.
        by apply: eq_bigr => a _; rewrite /F eqxx.
      rewrite mulrC; congr (_ * _).
      have -> : \prod_(i : 'I_T | i != j) \sum_(a : A) F i a =
                \prod_(i : 'I_T | i != j) #|A|%:R.
        apply: eq_bigr => i ij.
        under eq_bigr do rewrite /F (negbTE ij).
        by rewrite sumr_const.
      rewrite prodr_const natrX.
      suff -> : #|[pred i : 'I_T | i != j]| = T.-1 by [].
      have -> : #|[pred i : 'I_T | i != j]| = #|predC1 j|.
        by apply: eq_card => i; rewrite !inE.
      by rewrite cardC1 card_ord.
    by rewrite -rhsE -bigA_distr_bigA lhsE.
  Qed.

  (* Мощность пространства траекторий в форме, требуемой fdist_uniform. *)
  Lemma card_path : #|{ffun 'I_T -> A}| = ((#|A| ^ T).-1).+1.
  Proof.
    by rewrite card_ffun card_ord prednK // expn_gt0 cardA_gt0.
  Qed.

  (* Равномерные распределения на траекториях и на исходах одного шага. *)
  Definition path_dist : fdist ℂ {ffun 'I_T -> A} := fdist_uniform card_path.
  Definition step_dist : fdist ℂ A := fdist_uniform (esym (prednK cardA_gt0)).

  (*
    Маргинал координаты: ожидание функции одной координаты траектории равно
    ожиданию против одношагового равномерного распределения.
  *)
  Lemma Exp_path_coord r c (g : A -> 'M[ℂ]_(r, c)) (j : 'I_T) :
    Exp path_dist (fun t => g (t j)) = Exp step_dist g.
  Proof.
    have T_gt0 : (0 < T)%N by case: j => j' hj'; exact: leq_ltn_trans hj'.
    apply/matrixP => e1 e2.
    rewrite /Exp !summxE.
    under eq_bigr do rewrite !mxE fdist_uniformE card_ffun !card_ord.
    under [in RHS]eq_bigr do rewrite !mxE fdist_uniformE.
    rewrite -mulr_sumr (sum_path_coord (fun a => g a e1 e2) j).
    rewrite -[in RHS]mulr_sumr mulrA; congr (_ * _).
    have expA_neq0 : ((#|A| ^ T.-1)%:R : ℂ) != 0.
      by rewrite pnatr_eq0 -lt0n expn_gt0 cardA_gt0.
    have -> : (#|A| ^ T)%N = (#|A| * #|A| ^ T.-1)%N.
      by rewrite -{1}(prednK T_gt0) expnS.
    by rewrite natrM invfM -mulrA mulVf // mulr1.
  Qed.

  (*
    Шум шага k как функция траектории: координата k при $k < T$, ноль вне
    горизонта.
  *)
  Definition path_rv r c (g : A -> 'M[ℂ]_(r, c)) (k : nat) :
      {ffun 'I_T -> A} -> 'M[ℂ]_(r, c) :=
    fun t => if insub k is Some j then g (t j) else 0.

  (* Нулевое одношаговое среднее переносится на каждый шаг процесса. *)
  Lemma Exp_path_rv_zero r c (g : A -> 'M[ℂ]_(r, c)) (k : nat) :
    Exp step_dist g = 0 -> Exp path_dist (path_rv g k) = 0.
  Proof.
    move=> g0; rewrite /path_rv.
    case: insubP => [j _ _ | _].
    - by rewrite Exp_path_coord g0.
    - exact: Exp_zero.
  Qed.

End PathSpace.

Section KalmanNoiseModel.

  (*
    Конкретная модель шумов для фильтра Калмана со скалярными шумами
    $(m = p = 1)$: пространство траекторий исходов на горизонте 2T, чётные
    координаты питают шум управления, нечётные шум измерения. Все вероятностные
    гипотезы теоремы `kalman.unbiased` дискретной моделью выполнены, что
    показывает следствие `model_unbiased`.
  *)

  Variable ℂ : numClosedFieldType.
  Variable n : nat.
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, 1)) (H : 'M[ℂ]_(1, n)).
  Variables (Q : 'M[ℂ]_1) (R : 'M[ℂ]_1).

  (* Параметры четырёхточечных распределений шумов. *)
  Variables αw βw αv βv : ℂ.

  (* Горизонт процесса. *)
  Variable T : nat.

  Lemma card16 : (0 < #|'I_16|)%N.
  Proof.
    by rewrite card_ord.
  Qed.

  (* Пространство траекторий исходов и его равномерное распределение. *)
  Definition model_Ω : finType := {ffun 'I_(T.*2) -> 'I_16}.
  Definition model_μ : fdist ℂ model_Ω := path_dist ℂ (T.*2) card16.

  (* Шумы как случайные процессы: координаты чередуются. *)
  Definition model_w (k : nat) : model_Ω -> 'cV[ℂ]_1 :=
    path_rv (noise_rv αw βw) k.-1.*2.
  Definition model_v (k : nat) : model_Ω -> 'cV[ℂ]_1 :=
    path_rv (noise_rv αv βv) k.-1.*2.+1.

  (* Одношаговые распределения совпадают с noise_dist. *)
  Lemma step_dist_noiseE : step_dist ℂ card16 = noise_dist ℂ.
  Proof.
    by apply/val_inj/ffunP => i; rewrite !fdist_uniformE.
  Qed.

  Lemma model_w_zero k : Exp model_μ (model_w k) = 0.
  Proof.
    by apply: Exp_path_rv_zero; rewrite step_dist_noiseE noise_mean.
  Qed.

  Lemma model_v_zero k : Exp model_μ (model_v k) = 0.
  Proof.
    by apply: Exp_path_rv_zero; rewrite step_dist_noiseE noise_mean.
  Qed.

  (*
    Несмещённость фильтра Калмана для конкретной модели шумов.

    Начальное состояние нулевое, поэтому начальная ошибка равна нулю
    тождественно; все остальные гипотезы теоремы `unbiased` (нулевое среднее
    шумов на каждом шаге) доказаны выше из равномерности распределения на
    траекториях исходов.
  *)
  Corollary model_unbiased u y Ps :
    (forall j ω, y j ω = H *m x_true F G 0 model_w u j ω + model_v j ω) ->
    forall k,
      Exp model_μ (x_err F G H Q R 0 model_w u y Ps k) = 0.
  Proof.
    move=> Hzm.
    apply: unbiased.
    - exact: model_w_zero.
    - exact: model_v_zero.
    - exact: Hzm.
    - rewrite (eq_Exp (Y := fun _ : model_Ω => 0)) ?Exp_zero // => ω.
      by rewrite /x_err /= subrr.
  Qed.

End KalmanNoiseModel.
