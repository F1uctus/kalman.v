(*  Спектральный радиус через Schur-разложение.                          *)
(*                                                                         *)
(*  Над `numClosedFieldType` каждая квадратная матрица унитарно            *)
(*  подобна верхне-треугольной (теорема Schur, mathcomp 2.x                *)
(*  `algebra/spectral.v`).  Диагональ T = U A U† содержит собственные      *)
(*  значения A; spec_rad A := max_i ‖T_ii‖ — спектральный радиус.          *)
(*                                                                         *)
(*  Здесь введено Prop-предикат `spec_rad_lt1 A` (свидетельство            *)
(*  Schur-разложения, у которого вся диагональ строго внутри открытого     *)
(*  единичного диска) и доказана достаточность Фробениусова сжатия:       *)
(*                                                                         *)
(*    frob_sq A < 1 -> spec_rad_lt1 A.                                     *)
(*                                                                         *)
(*  Это первая ступень книжного пути Kailath–Sayed–Hassibi App. E:         *)
(*  Шуровость — настоящее условие сходимости итераций A^k, более слабое   *)
(*  чем frob_sq A < 1, но достаточное для всей машинерии DARE.            *)
(*                                                                         *)
(*  Дальнейшие сессии (S20, S21): сходимость A^+k → 0 при spec_rad_lt1 A   *)
(*  и теорема инверсии Ляпунова.                                          *)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra archimedean.
From mathcomp.algebra Require Import sesquilinear spectral mxred.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype.
From Kalman Require Import mxnotation mxherm mxdefinite mxfrob mxtopo.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Import numFieldTopology.Exports.
Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* ================================================================== *)
(*  Унитарная инвариантность Фробениусова квадрата                     *)
(* ================================================================== *)

Section FrobUnitary.
Variable (ℂ : numClosedFieldType).

(* Унитарная U слева: frob_sq (U M) = frob_sq M.                       *)
Lemma frob_sq_unitary_left n m (U : 'M[ℂ]_n) (M : 'M[ℂ]_(n, m)) :
  U \is unitarymx -> frob_sq (U *m M) = frob_sq M.
Proof.
move=> hU.
have hUCU : U^t* *m U = 1%:M.
  rewrite -invmx_unitary //.
  by apply: mulVmx; exact: unitarymx_unit.
rewrite /frob_sq trmxC_mul -[(M^t* *m U^t*) *m _]mulmxA.
by rewrite [U^t* *m _]mulmxA hUCU mul1mx.
Qed.

(* Унитарная U справа: frob_sq (M U) = frob_sq M.                      *)
Lemma frob_sq_unitary_right n m (U : 'M[ℂ]_n) (M : 'M[ℂ]_(m, n)) :
  U \is unitarymx -> frob_sq (M *m U) = frob_sq M.
Proof.
move=> hU.
rewrite -[in RHS]frob_sq_trmxC -[in LHS]frob_sq_trmxC.
rewrite trmxC_mul.
apply: frob_sq_unitary_left.
by rewrite trmxC_unitary.
Qed.

(* Сопряжение унитарным с двух сторон: frob_sq (U M U†) = frob_sq M.   *)
Lemma frob_sq_conj_unitary n (U M : 'M[ℂ]_n) :
  U \is unitarymx -> frob_sq (U *m M *m U^t*) = frob_sq M.
Proof.
move=> hU.
rewrite frob_sq_unitary_right; first exact: frob_sq_unitary_left.
by rewrite trmxC_unitary.
Qed.

End FrobUnitary.

(* ================================================================== *)
(*  Оценка модуля диагонального элемента через Фробениусов квадрат     *)
(* ================================================================== *)

Section DiagBound.
Variable (ℂ : numClosedFieldType).

(* Для каждого диагонального элемента M_ii: ‖M_ii‖² ≤ frob_sq M.        *)
(* Тривиально через frob_sqE: \sum_{i,j} M_ij^* M_ij ≥ единичное       *)
(* слагаемое M_ii^* M_ii = ‖M_ii‖².                                    *)
Lemma diag_normCK_le_frob_sq n (M : 'M[ℂ]_n) (i : 'I_n) :
  `|M i i| ^+ 2 <= frob_sq M.
Proof.
rewrite normCKC frob_sqE.
have h_nn : forall j k : 'I_n, 0 <= (M k j)^* * M k j.
  by move=> j k; rewrite mulrC; exact: mul_conjC_ge0.
rewrite (bigD1 i) //=.
rewrite (bigD1 i) //=.
(* Цель: X ≤ (X + S_inner) + S_outer; разделяем lerD на две части. *)
rewrite -[X in X <= _]addr0.
apply: lerD; last by apply: sumr_ge0=> j _; apply: sumr_ge0=> k _; exact: h_nn.
rewrite lerDl.
by apply: sumr_ge0=> k _; exact: h_nn.
Qed.

End DiagBound.

(* ================================================================== *)
(*  Спектральный радиус: формулировка через Schur                      *)
(* ================================================================== *)

Section SpecRad.
Variable (ℂ : numClosedFieldType).

(* `spec_rad_lt1 A` — существование Schur-разложения с диагональю      *)
(* строго внутри открытого единичного диска.  Не утверждает максимум   *)
(* (это потребовало бы `bigmax`), но достаточно для downstream:        *)
(* спектральный анализ через любую конкретную трёхугольную форму.      *)
Definition spec_rad_lt1 n (A : 'M[ℂ]_n) : Prop :=
  exists U T : 'M[ℂ]_n,
    [/\ U \is unitarymx,
        A = U^t* *m T *m U,
        is_trig_mx T &
        forall i : 'I_n, `|T i i| < 1].

(* ================================================================== *)
(*  Главная теорема: Фробениусово сжатие => Шуровость                   *)
(* ================================================================== *)

(* Для n.+1: устраняем граничный случай n = 0 (Schur требует n > 0).   *)
Theorem frob_sq_contract_spec_rad_lt1 n (A : 'M[ℂ]_n.+1) :
  frob_sq A < 1 -> spec_rad_lt1 A.
Proof.
move=> Ac.
(* Шаг 1: Schur даёт unitary U и трёхугольную conjmx U A.              *)
have HSchur : (0 < n.+1)%N := isT.
have [U Uunit Atrig] := Schur A HSchur.
(* Atrig : is_trig_mx (conjmx U A);  conjmx U A = U A U† при U unitary *)
have HTeq : conjmx U A = U *m A *m U^t* := conjymx A Uunit.
set T := conjmx U A.
(* Шаг 2: A = U† T U (обратное Schur-разложение).                       *)
have hUUC : U *m U^t* = 1%:M by apply/unitarymxP.
have hUCU : U^t* *m U = 1%:M.
  rewrite -invmx_unitary //.
  by apply: mulVmx; exact: unitarymx_unit.
have HAdec : A = U^t* *m T *m U.
  rewrite /T HTeq.
  have ->: U^t* *m (U *m A *m U^t*) *m U
         = U^t* *m U *m A *m U^t* *m U
    by rewrite !mulmxA.
  rewrite hUCU mul1mx -mulmxA hUCU.
  by rewrite mulmx1.
(* Шаг 3: frob_sq T = frob_sq A (унитарная инвариантность).             *)
have HfrobEq : frob_sq T = frob_sq A.
  by rewrite /T HTeq; exact: frob_sq_conj_unitary.
(* Шаг 4: для каждого i диагональный элемент в модуле < 1.              *)
exists U, T; split=> //.
move=> i.
have Hsq : `|T i i| ^+ 2 < 1.
  have step1 : `|T i i| ^+ 2 <= frob_sq T := diag_normCK_le_frob_sq T i.
  rewrite HfrobEq in step1.
  exact: le_lt_trans step1 Ac.
(* ‖T i i‖² < 1 => ‖T i i‖ < 1 — через mono `ltr_pXn2r` на Num.nneg. *)
rewrite -(@ltr_pXn2r _ 2 isT _ _ _ _) ?nnegrE //.
by rewrite expr1n; exact: Hsq.
Qed.

End SpecRad.

(* ================================================================== *)
(*  Степени матрицы при Schur-стабильности (Session 20, ступень 1)     *)
(* ================================================================== *)
(*  Алгебраическая часть пути к сходимости A^+k → 0 при spec_rad_lt1 A: *)
(*  субмультипликативность Фробениуса, оценка степени, выражение         *)
(*  A^+k через Schur-конъюгацию T^+k.  Конкретное предельное             *)
(*  утверждение `A^+k @ \oo --> 0` требует архимедова замыкания          *)
(*  (для доказательства `r^+k → 0` при `0 ≤ r < 1`) и выносится в       *)
(*  отдельную ступень (Session 20.5 / 21).                              *)

Section SchurPow.
Variable (ℂ : numClosedFieldType).

(* Субмультипликативность Фробениусова квадрата:                       *)
(*   frob_sq (A *m B) ≤ frob_sq A * frob_sq B.                          *)
(* Доказательство: \tr ((AB)† AB) = \tr (B† (A† A) B);                  *)
(*   `tr_conj_frob_le` с Fm := B†, M := A† A (PSD по psd_frob) даёт    *)
(*   `\tr (B† (A† A) (B†)†) ≤ frob_sq B† * \tr (A† A)`.                 *)
(*   `(B†)† = B` (trmxCK) и `frob_sq B† = frob_sq B`                    *)
(*   (frob_sq_trmxC), `\tr (A† A) = frob_sq A` (по определению).        *)
Lemma frob_sq_mulmx_le n m p
    (A : 'M[ℂ]_(n, m)) (B : 'M[ℂ]_(m, p)) :
  frob_sq (A *m B) <= frob_sq A * frob_sq B.
Proof.
rewrite /frob_sq trmxC_mul.
have step : B^t* *m A^t* *m (A *m B) = B^t* *m (A^t* *m A) *m B
  by rewrite !mulmxA.
rewrite step.
have H := tr_conj_frob_le (B^t*) (psd_frob A).
rewrite trmxCK frob_sq_trmxC in H.
by apply: (le_trans H); rewrite mulrC.
Qed.

(* Оценка нормы Фробениуса степени:                                     *)
(*   frob_sq (A ^+ k.+1) ≤ (frob_sq A) ^+ k.+1.                          *)
(* Индукция по k через субмультипликативность.  Граничный случай k = 0 *)
(* отсутствует (для k = 0: A^0 = 1, frob_sq 1 = n.+1 в общем случае,   *)
(* в то время как (frob_sq A)^0 = 1).                                   *)
Lemma frob_sq_exp_le n (A : 'M[ℂ]_n.+1) k :
  frob_sq (A ^+ k.+1) <= (frob_sq A) ^+ k.+1.
Proof.
elim: k => [|k IHk]; first by rewrite !expr1.
have rew_pow : A ^+ k.+2 = A *m A ^+ k.+1 by rewrite exprS mulmxE.
rewrite rew_pow.
have step1 : frob_sq (A *m A ^+ k.+1) <= frob_sq A * frob_sq (A ^+ k.+1)
  := frob_sq_mulmx_le A (A ^+ k.+1).
apply: (le_trans step1).
rewrite [in X in _ <= X]exprS.
by rewrite ler_wpM2l ?frob_sq_ge0 // IHk.
Qed.

(* Schur-конъюгация коммутирует со степенями:                          *)
(*   при unitary U и A = U† T U выполнено A^+k = U† T^+k U.             *)
(* Доказательство: индукция по k; шаг использует `U *m U† = 1%:M`       *)
(* для «съёживания» среднего фрагмента (U *m U†) в произведении.        *)
Lemma schur_exp_conj n (U A T : 'M[ℂ]_n) (k : nat) :
  U \is unitarymx -> A = U^t* *m T *m U ->
  A ^+ k = U^t* *m T ^+ k *m U.
Proof.
move=> hU hA.
have hUU : U *m U^t* = 1%:M by apply/unitarymxP.
elim: k => [|k IHk].
  rewrite !expr0 mulmx1.
  by rewrite -invmx_unitary // mulVmx //; exact: unitarymx_unit.
rewrite exprS IHk [in LHS]hA -mulmxE.
rewrite exprS -mulmxE.
have step : U^t* *m T *m U *m (U^t* *m T ^+ k *m U)
          = U^t* *m T *m (U *m U^t*) *m T ^+ k *m U
  by rewrite !mulmxA.
by rewrite step hUU mulmx1 !mulmxA.
Qed.

End SchurPow.

(* ================================================================== *)
(*  Сходимость степеней при Фробениусовом сжатии (Session 20.5)        *)
(* ================================================================== *)
(*  Предельная ступень: A^+k → 0 при frob_sq A < 1.  Объединяет          *)
(*  алгебраические оценки Session 20 (frob_sq_exp_le) с архимедовым       *)
(*  затуханием r^+k → 0 (mxtopo.r_pow_cvgn0) через squeeze и мост         *)
(*  Фробениуса frob_sq_cvgn0_to_mxcvgn.  Архимедовость — явная гипотеза   *)
(*  (см. mxtopo: над numClosedFieldType cvg_expr неприменима).            *)

Section SchurPowCvg.
Variable (ℂ : numClosedFieldType).
Hypothesis ℂ_archi : Num.archimedean_axiom ℂ.

(* Сходимость Фробениусова квадрата степени: frob_sq (A^+k.+1) → 0.     *)
(* Squeeze: 0 ≤ frob_sq (A^+k.+1) ≤ (frob_sq A)^+k.+1 (frob_sq_exp_le), *)
(* и (frob_sq A)^+k.+1 → 0 (r_pow_cvgn0, т.к. 0 ≤ frob_sq A < 1).       *)
Lemma frob_sq_pow_cvgn0 n (A : 'M[ℂ]_n.+1) :
  frob_sq A < 1 ->
  (fun k => frob_sq (A ^+ k.+1)) @ \oo --> (0 : ℂ).
Proof.
move=> Ac.
apply: (cvgC_le0_squeeze (t := fun k => (frob_sq A) ^+ k.+1)).
- by move=> k; exact: frob_sq_ge0.
- by move=> k; exact: frob_sq_exp_le.
- apply: r_pow_cvgn0 => //; exact: frob_sq_ge0.
Qed.

(* Поэлементная сходимость степеней: A^+k.+1 → 0 при frob_sq A < 1.     *)
(* Мост frob_sq_cvgn0_to_mxcvgn с пределом L = 0: достаточно frob_sq    *)
(* разности → 0, а frob_sq (A^+k.+1 - 0) = frob_sq (A^+k.+1).           *)
Lemma mx_pow_cvgn0_frob_lt1 n (A : 'M[ℂ]_n.+1) :
  frob_sq A < 1 ->
  (fun k => A ^+ k.+1) @ \oo --> (0 : 'M[ℂ]_n.+1).
Proof.
move=> Ac.
apply: frob_sq_cvgn0_to_mxcvgn.
under eq_cvg=> k do rewrite subr0.
exact: frob_sq_pow_cvgn0.
Qed.

(* Связка двух нитей пути Kailath–Sayed–Hassibi App. E: Фробениусово    *)
(* сжатие даёт одновременно Шуровость (spec_rad_lt1) и сходимость        *)
(* степеней к нулю.  Полный `spec_rad_lt1 A → A^+k → 0` (без             *)
(* Фробениусовой гипотезы) требует блочной индукции по                  *)
(* верхне-треугольной форме и вынесен в Session 20.6.                    *)
Corollary pow_cvgn0_spec_rad_via_frob n (A : 'M[ℂ]_n.+1) :
  frob_sq A < 1 ->
  spec_rad_lt1 A /\ (fun k => A ^+ k.+1) @ \oo --> (0 : 'M[ℂ]_n.+1).
Proof.
move=> Ac; split.
- exact: frob_sq_contract_spec_rad_lt1.
- exact: mx_pow_cvgn0_frob_lt1.
Qed.

End SchurPowCvg.
