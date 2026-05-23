(*  Спектральный радиус через Schur-разложение.                          *)
(*                                                                         *)
(*  Над `numClosedFieldType` каждая квадратная матрица унитарно            *)
(*  подобна верхне-треугольной (теорема Schur, mathcomp 2.x                *)
(*  `algebra/spectral.v`).  Диагональ T = U A Uᶜ содержит собственные      *)
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

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral mxred.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import psd_base mxfrob.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(* ================================================================== *)
(*  Унитарная инвариантность Фробениусова квадрата                     *)
(* ================================================================== *)

Section FrobUnitary.
Variable (C : numClosedFieldType).

(* Унитарная U слева: frob_sq (U M) = frob_sq M.                       *)
Lemma frob_sq_unitary_left n m (U : 'M[C]_n) (M : 'M[C]_(n, m)) :
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
Lemma frob_sq_unitary_right n m (U : 'M[C]_n) (M : 'M[C]_(m, n)) :
  U \is unitarymx -> frob_sq (M *m U) = frob_sq M.
Proof.
move=> hU.
rewrite -[in RHS]frob_sq_trmxC -[in LHS]frob_sq_trmxC.
rewrite trmxC_mul.
apply: frob_sq_unitary_left.
by rewrite trmxC_unitary.
Qed.

(* Сопряжение унитарным с двух сторон: frob_sq (U M Uᶜ) = frob_sq M.   *)
Lemma frob_sq_conj_unitary n (U M : 'M[C]_n) :
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
Variable (C : numClosedFieldType).

(* Для каждого диагонального элемента M_ii: ‖M_ii‖² ≤ frob_sq M.        *)
(* Тривиально через frob_sqE: \sum_{i,j} M_ij^* M_ij ≥ единичное       *)
(* слагаемое M_ii^* M_ii = ‖M_ii‖².                                    *)
Lemma diag_normCK_le_frob_sq n (M : 'M[C]_n) (i : 'I_n) :
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
Variable (C : numClosedFieldType).

(* `spec_rad_lt1 A` — существование Schur-разложения с диагональю      *)
(* строго внутри открытого единичного диска.  Не утверждает максимум   *)
(* (это потребовало бы `bigmax`), но достаточно для downstream:        *)
(* спектральный анализ через любую конкретную трёхугольную форму.      *)
Definition spec_rad_lt1 n (A : 'M[C]_n) : Prop :=
  exists U T : 'M[C]_n,
    [/\ U \is unitarymx,
        A = U^t* *m T *m U,
        is_trig_mx T &
        forall i : 'I_n, `|T i i| < 1].

(* ================================================================== *)
(*  Главная теорема: Фробениусово сжатие ⇒ Шуровость                   *)
(* ================================================================== *)

(* Для n.+1: устраняем граничный случай n = 0 (Schur требует n > 0).   *)
Theorem frob_sq_contract_spec_rad_lt1 n (A : 'M[C]_n.+1) :
  frob_sq A < 1 -> spec_rad_lt1 A.
Proof.
move=> Ac.
(* Шаг 1: Schur даёт unitary U и трёхугольную conjmx U A.              *)
have HSchur : (0 < n.+1)%N := isT.
have [U Uunit Atrig] := Schur A HSchur.
(* Atrig : is_trig_mx (conjmx U A);  conjmx U A = U A Uᶜ при U unitary *)
have HTeq : conjmx U A = U *m A *m U^t* := conjymx A Uunit.
set T := conjmx U A.
(* Шаг 2: A = Uᶜ T U (обратное Schur-разложение).                       *)
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
(* ‖T i i‖² < 1 ⇒ ‖T i i‖ < 1 — через mono `ltr_pXn2r` на Num.nneg. *)
rewrite -(@ltr_pXn2r _ 2 isT _ _ _ _) ?nnegrE //.
by rewrite expr1n; exact: Hsq.
Qed.

End SpecRad.
