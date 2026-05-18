(*  Непрерывность алгебраических операций фильтра Калмана.               *)
(*                                                                       *)
(*  В этом файле:                                                        *)
(*    * непрерывность определителя, кофакторов, присоединённой матрицы   *)
(*      (полиномы от элементов);                                         *)
(*    * непрерывность `invmx` на `unitmx` (формула Крамера                *)
(*      `invmx A = (\det A)^-1 *: \adj A`);                              *)
(*    * непрерывность `predict_cov`, `innov_cov`, `kalman_gain`,         *)
(*      `update_cov`, `riccati_step` на соответствующих областях.        *)
(*                                                                       *)
(*  Областью непрерывности `kalman_gain` и `update_cov` является         *)
(*  открытое множество `{ P | innov_cov P \in unitmx }`, которое         *)
(*  содержит весь PSD-конус (по `innov_cov_inv` из `kalman.v` §3).       *)
(*                                                                       *)
(*  Никаких mxmonotone-зависимостей: сессия 4 — чистая непрерывность.    *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp.fingroup Require Import perm.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype.
From Kalman Require Import psd_base psd_order mxfrob mxtopo.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* ================================================================== *)
(*  Скалярное произведение по конечному списку (helper).               *)
(* ================================================================== *)

Section ScalarProd.
Variable (C : numClosedFieldType).

Lemma cvgC_prod (I : Type) (P : pred I) (r : seq I)
    (F : I -> nat -> C) (a : I -> C) :
  (forall i, P i -> F i @ \oo --> a i) ->
  (fun k => \prod_(i <- r | P i) F i k) @ \oo -->
    \prod_(i <- r | P i) a i.
Proof.
move=> HF; elim: r => [|i r IHr].
  rewrite big_nil; under eq_cvg do rewrite big_nil; exact: cvg_cst.
rewrite big_cons; under eq_cvg do rewrite big_cons; case: ifPn => Pi //.
exact: cvgC_M (HF _ Pi) IHr.
Qed.

End ScalarProd.

(* ================================================================== *)
(*  Перестановочные/обрезающие операции непрерывны (поэлементно).       *)
(* ================================================================== *)

Section MxShuffle.
Variable (C : numClosedFieldType).

Lemma cvgn_row' m n (M : nat -> 'M[C]_(m, n)) (L : 'M[C]_(m, n)) (i0 : 'I_m) :
  M @ \oo --> L -> (fun k => row' i0 (M k)) @ \oo --> row' i0 L.
Proof.
move=> HM; apply/mxcvgn_to_cvgn=> i j.
have HMe := cvgn_to_mxcvgn HM.
under eq_cvg=> k do rewrite mxE.
by rewrite mxE; exact: HMe.
Qed.

Lemma cvgn_col' m n (M : nat -> 'M[C]_(m, n)) (L : 'M[C]_(m, n)) (j0 : 'I_n) :
  M @ \oo --> L -> (fun k => col' j0 (M k)) @ \oo --> col' j0 L.
Proof.
move=> HM; apply/mxcvgn_to_cvgn=> i j.
have HMe := cvgn_to_mxcvgn HM.
under eq_cvg=> k do rewrite mxE.
by rewrite mxE; exact: HMe.
Qed.

End MxShuffle.

(* ================================================================== *)
(*  Непрерывность определителя, кофактора, присоединённой матрицы.      *)
(* ================================================================== *)

Section Determinant.
Variable (C : numClosedFieldType).

(* `\det` непрерывен: формула Лейбница даёт сумму произведений
   элементов матрицы. *)
Lemma cvgn_det n (M : nat -> 'M[C]_n) (L : 'M[C]_n) :
  M @ \oo --> L -> (fun k => \det (M k)) @ \oo --> \det L.
Proof.
move=> HM.
have HMe := cvgn_to_mxcvgn HM.
rewrite /determinant.
under eq_cvg=> k do rewrite /determinant.
apply: cvgC_sum=> s _.
apply: cvgC_M; first exact: cvg_cst.
apply: cvgC_prod=> i _; exact: HMe.
Qed.

(* Кофактор: `(-1)^(i+j) * \det (row' i (col' j A))`. *)
Lemma cvgn_cofactor n (M : nat -> 'M[C]_n) (L : 'M[C]_n) (i j : 'I_n) :
  M @ \oo --> L ->
  (fun k => cofactor (M k) i j) @ \oo --> cofactor L i j.
Proof.
move=> HM.
rewrite /cofactor.
under eq_cvg=> k do rewrite /cofactor.
apply: cvgC_M; first exact: cvg_cst.
apply: cvgn_det.
apply: cvgn_row'.
exact: cvgn_col'.
Qed.

(* Присоединённая матрица: `\adj A i j = cofactor A j i`. *)
Lemma cvgn_adjugate n (M : nat -> 'M[C]_n) (L : 'M[C]_n) :
  M @ \oo --> L -> (fun k => \adj (M k)) @ \oo --> \adj L.
Proof.
move=> HM; apply/mxcvgn_to_cvgn=> i j.
under eq_cvg=> k do rewrite mxE.
by rewrite mxE; exact: cvgn_cofactor.
Qed.

End Determinant.

(* ================================================================== *)
(*  Непрерывность invmx на unitmx.                                     *)
(* ================================================================== *)

Section Invmx.
Variable (C : numClosedFieldType).

(* `invmx A = (\det A)^-1 *: \adj A`, когда `A \in unitmx`.  В точках
   `L \in unitmx` определитель не равен нулю, и в окрестности `L`
   последовательность тоже unitmx, что позволяет переписать invmx
   по формуле Крамера и применить непрерывности скалярного обращения
   и скалярного произведения матрицы. *)
Lemma cvgn_invmx n (M : nat -> 'M[C]_n) (L : 'M[C]_n) :
  M @ \oo --> L -> L \in unitmx ->
  (fun k => invmx (M k)) @ \oo --> invmx L.
Proof.
move=> HM Lunit.
have FF : Filter (\oo : set_system nat) by typeclasses eauto.
have detL_unit : \det L \is a GRing.unit by rewrite -unitmxE.
have detL_nz : \det L != 0 by rewrite -unitfE.
have Hdet : (fun k => \det (M k)) @ \oo --> \det L := cvgn_det HM.
have Hadj : (fun k => \adj (M k)) @ \oo --> \adj L := cvgn_adjugate HM.
have HinvDet : (fun k => (\det (M k))^-1) @ \oo --> (\det L)^-1
  := @cvgV _ _ _ FF _ _ detL_nz Hdet.
have HformCvg :
    (fun k => (\det (M k))^-1 *: \adj (M k)) @ \oo -->
    (\det L)^-1 *: \adj L
  := @cvgZ _ _ _ _ FF _ _ _ _ HinvDet Hadj.
have HinvL : invmx L = (\det L)^-1 *: \adj L by rewrite /invmx Lunit.
have Hdet_nz : \forall k \near \oo, \det (M k) != 0.
  have Hdet_o :
    ((fun k => \det (M k)) : nat -> C^o) @ \oo --> (\det L : C^o)
    by exact: Hdet.
  exact: (@cvgr_neq0 _ _ _ _ _ _ (\det L : C^o) Hdet_o detL_nz).
have Hunit_near : \forall k \near \oo, M k \in unitmx.
  apply: filterS Hdet_nz=> k Hk; by rewrite unitmxE unitfE.
have Heq : \forall k \near \oo,
  (\det (M k))^-1 *: \adj (M k) = invmx (M k).
  apply: filterS Hunit_near=> k Hk; by rewrite /invmx Hk.
rewrite HinvL.
apply: cvg_trans HformCvg.
apply: near_eq_cvg.
apply: filterS Heq=> k Hk; exact: esym.
Qed.

End Invmx.

(* ================================================================== *)
(*  Непрерывность операций фильтра Калмана.                             *)
(* ================================================================== *)

Section KalmanCont.
Variable (C : numClosedFieldType).
Variables (m n p : nat).
Variables (F : 'M[C]_n) (G : 'M[C]_(n, m)) (H : 'M[C]_(p, n)).
Variables (Q : 'M[C]_m) (R : 'M[C]_p).

(* `predict_cov P = F *m P *m F^t* + G *m Q *m G^t*` — полином в P. *)
Definition predict_cov (P : 'M[C]_n) : 'M[C]_n :=
  F *m P *m F^t* + G *m Q *m G^t*.

Lemma cvgn_predict_cov (Pseq : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pseq @ \oo --> L -> (fun k => predict_cov (Pseq k)) @ \oo --> predict_cov L.
Proof.
move=> HP.
apply: cvgn_addmx; last exact: cvg_cst.
apply: cvgn_mulmx; last exact: cvg_cst.
apply: cvgn_mulmx (cvg_cst _) HP.
Qed.

(* `innov_cov P = H *m P *m H^t* + R` — полином в P. *)
Definition innov_cov (P : 'M[C]_n) : 'M[C]_p :=
  H *m P *m H^t* + R.

Lemma cvgn_innov_cov (Pseq : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pseq @ \oo --> L -> (fun k => innov_cov (Pseq k)) @ \oo --> innov_cov L.
Proof.
move=> HP.
apply: cvgn_addmx; last exact: cvg_cst.
apply: cvgn_mulmx; last exact: cvg_cst.
apply: cvgn_mulmx (cvg_cst _) HP.
Qed.

(* `kalman_gain P = P *m H^t* *m invmx (innov_cov P)`.
   Непрерывен в точках, где `innov_cov L \in unitmx`. *)
Definition kalman_gain (P : 'M[C]_n) : 'M[C]_(n, p) :=
  P *m H^t* *m invmx (innov_cov P).

Lemma cvgn_kalman_gain (Pseq : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pseq @ \oo --> L -> innov_cov L \in unitmx ->
  (fun k => kalman_gain (Pseq k)) @ \oo --> kalman_gain L.
Proof.
move=> HP Sunit.
rewrite /kalman_gain; under eq_cvg=> k do rewrite /kalman_gain.
apply: cvgn_mulmx.
- apply: cvgn_mulmx HP _; exact: cvg_cst.
- exact: cvgn_invmx (cvgn_innov_cov HP) Sunit.
Qed.

(* `update_cov P = (1 - kalman_gain P *m H) *m P`. *)
Definition update_cov (P : 'M[C]_n) : 'M[C]_n :=
  (1%:M - kalman_gain P *m H) *m P.

Lemma cvgn_update_cov (Pseq : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pseq @ \oo --> L -> innov_cov L \in unitmx ->
  (fun k => update_cov (Pseq k)) @ \oo --> update_cov L.
Proof.
move=> HP Sunit.
rewrite /update_cov; under eq_cvg=> k do rewrite /update_cov.
apply: cvgn_mulmx; last exact: HP.
apply: cvgn_submx; first exact: cvg_cst.
apply: cvgn_mulmx; last exact: cvg_cst.
exact: cvgn_kalman_gain HP Sunit.
Qed.

(* `riccati_step P = update_cov (predict_cov P)`. *)
Definition riccati_step (P : 'M[C]_n) : 'M[C]_n :=
  update_cov (predict_cov P).

Lemma cvgn_riccati_step (Pseq : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pseq @ \oo --> L -> innov_cov (predict_cov L) \in unitmx ->
  (fun k => riccati_step (Pseq k)) @ \oo --> riccati_step L.
Proof.
move=> HP Sunit.
apply: cvgn_update_cov Sunit.
exact: cvgn_predict_cov.
Qed.

End KalmanCont.
