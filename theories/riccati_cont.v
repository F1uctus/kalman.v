(*
  Непрерывность алгебраических операций фильтра Калмана.

  В этом файле:
  - непрерывность определителя, кофакторов, присоединённой матрицы
    (полиномы от элементов);
  - непрерывность `invmx` на `unitmx`
    (формула Крамера `invmx A = (\det A)^-1 *: \adj A`);
  - непрерывность `predict_cov`, `innov_cov`, `kalman_gain`, `update_cov`,
    `riccati_step` на соответствующих областях.

  Областью непрерывности `kalman_gain` и `update_cov` является открытое
  множество `{ P | innov_cov P \in unitmx }`, которое содержит весь конус
  неотрицательно определённых матриц (по `innov_cov_inv`).
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp.fingroup Require Import perm.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype.
From Kalman Require Import mxnotation mxdefinite mxloewner mxfrob mxtopo riccati_def.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* Перестановочные/обрезающие операции непрерывны (поэлементно). *)
Section MxShuffle.

  Variable (ℂ : numClosedFieldType).

  Lemma cvgn_row' m n (M : nat -> 'M[ℂ]_(m, n)) (L : 'M[ℂ]_(m, n)) (i0 : 'I_m) :
    M @ \oo --> L -> (fun k => row' i0 (M k)) @ \oo --> row' i0 L.
  Proof.
    move=> HM; apply/mxcvgn_to_cvgn=> i j.
    have HMe := cvgn_to_mxcvgn HM.
    under eq_cvg=> k do rewrite mxE.
    by rewrite mxE; exact: HMe.
  Qed.

  Lemma cvgn_col' m n (M : nat -> 'M[ℂ]_(m, n)) (L : 'M[ℂ]_(m, n)) (j0 : 'I_n) :
    M @ \oo --> L -> (fun k => col' j0 (M k)) @ \oo --> col' j0 L.
  Proof.
    move=> HM; apply/mxcvgn_to_cvgn=> i j.
    have HMe := cvgn_to_mxcvgn HM.
    under eq_cvg=> k do rewrite mxE.
    by rewrite mxE; exact: HMe.
  Qed.

End MxShuffle.

(* Непрерывность определителя, кофактора, присоединённой матрицы. *)
Section Determinant.

  Variable (ℂ : numClosedFieldType).

  (* https://ru.wikipedia.org/wiki/Формула_Лейбница_для_определителей *)
  Lemma cvgn_det n (M : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
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
  Lemma cvgn_cofactor n (M : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) (i j : 'I_n) :
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
  Lemma cvgn_adjugate n (M : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    M @ \oo --> L -> (fun k => \adj (M k)) @ \oo --> \adj L.
  Proof.
    move=> HM; apply/mxcvgn_to_cvgn=> i j.
    under eq_cvg=> k do rewrite mxE.
    by rewrite mxE; exact: cvgn_cofactor.
  Qed.

End Determinant.

(* Непрерывность invmx на unitmx. *)
Section Invmx.

  Variable (ℂ : numClosedFieldType).

  (*
    `invmx A = (\det A)^-1 *: \adj A`, когда `A \in unitmx`. В точках
    `L \in unitmx` определитель не равен нулю, и в окрестности `L`
    последовательность тоже unitmx, что позволяет переписать invmx по формуле
    Крамера и применить непрерывности скалярного обращения и скалярного
    произведения матрицы.
  *)
  Lemma cvgn_invmx n (M : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
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
        ((fun k => \det (M k)) : nat -> ℂ^o) @ \oo --> (\det L : ℂ^o)
        by exact: Hdet.
      exact: (@cvgr_neq0 _ _ _ _ _ _ (\det L : ℂ^o) Hdet_o detL_nz).
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

(* Непрерывность операций фильтра Калмана. *)
Section KalmanCont.

  Variable (ℂ : numClosedFieldType).

  Variables (m n p : nat).
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variables (Q : 'M[ℂ]_m) (R : 'M[ℂ]_p).

  (* $"predict_cov" P = F P F† + G Q G†$ - полином в $P$. *)
  Local Notation predict_cov := (riccati_def.predict_cov conjC F G Q).

  Lemma cvgn_predict_cov (Pseq : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pseq @ \oo --> L -> (fun k => predict_cov (Pseq k)) @ \oo --> predict_cov L.
  Proof.
    move=> HP.
    apply: cvgn_addmx; last exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    apply: cvgn_mulmx (cvg_cst _) HP.
  Qed.

  (* $"innov_cov" P = H P H† + R$ - полином в $P$. *)
  Local Notation innov_cov := (riccati_def.innov_cov conjC H R).

  Lemma cvgn_innov_cov (Pseq : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pseq @ \oo --> L -> (fun k => innov_cov (Pseq k)) @ \oo --> innov_cov L.
  Proof.
    move=> HP.
    apply: cvgn_addmx; last exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    apply: cvgn_mulmx (cvg_cst _) HP.
  Qed.

  (*
    $"kalman_gain" P = P H† "invmx"("innov_cov" P)$. Непрерывен в точках, где
    `innov_cov L \in unitmx`.
  *)
  Local Notation kalman_gain := (riccati_def.kalman_gain conjC H R).

  Lemma cvgn_kalman_gain (Pseq : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pseq @ \oo --> L -> innov_cov L \in unitmx ->
    (fun k => kalman_gain (Pseq k)) @ \oo --> kalman_gain L.
  Proof.
    move=> HP Sunit.
    rewrite kalman_gainE; under eq_cvg=> k do rewrite kalman_gainE.
    apply: cvgn_mulmx.
    - apply: cvgn_mulmx HP _; exact: cvg_cst.
    - exact: cvgn_invmx (cvgn_innov_cov HP) Sunit.
  Qed.

  (* $"update_cov" P = (E - "kalman_gain" P H) P$. *)
  Local Notation update_cov := (riccati_def.update_cov conjC H R).

  Lemma cvgn_update_cov (Pseq : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pseq @ \oo --> L -> innov_cov L \in unitmx ->
    (fun k => update_cov (Pseq k)) @ \oo --> update_cov L.
  Proof.
    move=> HP Sunit.
    rewrite update_covE; under eq_cvg=> k do rewrite update_covE.
    apply: cvgn_mulmx; last exact: HP.
    apply: cvgn_submx; first exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    exact: cvgn_kalman_gain HP Sunit.
  Qed.

  (* $"riccati_step" P = "update_cov"("predict_cov" P)$. *)
  Local Notation riccati_step := (riccati_def.riccati_step conjC F G H Q R).

  Lemma cvgn_riccati_step (Pseq : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pseq @ \oo --> L -> innov_cov (predict_cov L) \in unitmx ->
    (fun k => riccati_step (Pseq k)) @ \oo --> riccati_step L.
  Proof.
    move=> HP Sunit.
    apply: cvgn_update_cov Sunit.
    exact: cvgn_predict_cov.
  Qed.

End KalmanCont.
