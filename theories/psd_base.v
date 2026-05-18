(*  Положительная/неотрицательная определённость над numClosedFieldType. *)
(*                                                                       *)
(*  Эрмитова форма: M = M^t*  (где ^t* = (^T)^conjC из                   *)
(*  mathcomp.algebra.sesquilinear).                                      *)
(*                                                                       *)
(*  Скелет доказательств адаптирован из CoqQ/src/mxpred.v                *)
(*  (psdmxD, psdmx_bimap_closed_gen, psdmx_dot).                         *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Lemma trmx_add (K : numFieldType) m n (A C : 'M[K]_(m, n)) :
  (A + C)^T = A^T + C^T.
Proof. by apply/matrixP=> i j; rewrite !mxE. Qed.

Lemma trmxC_add (K : numClosedFieldType) m n (A C : 'M[K]_(m, n)) :
  (A + C)^t* = A^t* + C^t*.
Proof. by rewrite linearD /= map_mxD. Qed.

Lemma trmxC_mul (K : numClosedFieldType) m n p
  (A : 'M[K]_(m, n)) (B : 'M[K]_(n, p)) :
  (A *m B)^t* = B^t* *m A^t*.
Proof. by rewrite trmx_mul map_mxM. Qed.

Lemma trmxC0 (K : numClosedFieldType) m n : (0 : 'M[K]_(m, n))^t* = 0.
Proof. by rewrite linear0 map_mx0. Qed.

Lemma trmxCB (K : numClosedFieldType) m n (A C : 'M[K]_(m, n)) :
  (A - C)^t* = A^t* - C^t*.
Proof. by rewrite trmxC_add linearN /= map_mxN. Qed.

Lemma trmxCN (K : numClosedFieldType) m n (A : 'M[K]_(m, n)) :
  (- A)^t* = - A^t*.
Proof. by rewrite linearN /= map_mxN. Qed.

Lemma trmxC1 (K : numClosedFieldType) n : (1%:M : 'M[K]_n)^t* = 1%:M.
Proof. by rewrite trmx1 map_mx1. Qed.

Lemma trmxC_scale (K : numClosedFieldType) m n (a : K) (A : 'M[K]_(m, n)) :
  (a *: A)^t* = a^* *: A^t*.
Proof. by rewrite linearZ /= map_mxZ. Qed.

Section PSD.
Variable (C : numClosedFieldType).

Definition psd n (M : 'M[C]_n) : Prop :=
  M = M^t* /\ forall (v : 'cV[C]_n), 0 <= \tr (v^t* *m M *m v).

Definition pd n (M : 'M[C]_n) : Prop :=
  M = M^t* /\ forall (v : 'cV[C]_n), v != 0 -> 0 < \tr (v^t* *m M *m v).

Lemma pd_psd n (M : 'M[C]_n) : pd M -> psd M.
Proof.
  case=> Msym pdM; split=> // v.
  have [/eqP->|vNZ] := boolP (v == 0).
    by rewrite trmxC0 mul0mx mulmx0 mxtrace0 lexx.
  exact: ltW (pdM v vNZ).
Qed.

Lemma psd0 n : psd (0 : 'M[C]_n).
Proof.
  split; first by rewrite trmxC0.
  by move=> v; rewrite mulmx0 mul0mx mxtrace0 lexx.
Qed.

Lemma psd_add n (A B : 'M[C]_n) : psd A -> psd B -> psd (A + B).
Proof.
  move=> [Asym psdA] [Bsym psdB]; split.
    by rewrite trmxC_add -Asym -Bsym.
  move=> v; rewrite mulmxDr mulmxDl mxtraceD.
  exact: addr_ge0 (psdA v) (psdB v).
Qed.

Lemma psd_congruence n p (A : 'M[C]_n) (M : 'M[C]_(n, p)) :
  psd A -> psd (M^t* *m A *m M).
Proof.
  move=> [Asym hA]; split.
  - by rewrite trmxC_mul trmxC_mul trmxCK mulmxA -Asym.
  - move=> v.
    rewrite !mulmxA -mulmxA -trmxC_mul.
    exact: hA (M *m v).
Qed.

Lemma psd_mulmx_row n m (A : 'M[C]_m) (M : 'M[C]_(n, m)) :
  psd A -> psd (M *m A *m M^t*).
Proof.
  move=> psdA.
  have -> : (M *m A *m M^t*) = (M^t*)^t* *m A *m M^t* by rewrite trmxCK.
  exact: psd_congruence psdA.
Qed.

Lemma qf_delta n (M : 'M[C]_n) i :
  \tr ((delta_mx i ord0 : 'cV[C]_n)^t* *m M *m delta_mx i ord0) = M i i.
Proof.
  have del_eq : (delta_mx i ord0 : 'cV[C]_n)^t* = (delta_mx ord0 i : 'rV[C]_n).
    by rewrite trmx_delta map_delta_mx.
  rewrite del_eq -rowE trace_mx11 mxE (bigD1 i) //= big1 ?addr0; last first.
    move=> j neji; rewrite !mxE eqxx andbT.
    by rewrite (negbTE neji) mulr0.
  by rewrite !mxE !eqxx /= mulr1.
Qed.

Lemma psd_tr_ge0 n (M : 'M[C]_n) : psd M -> 0 <= \tr M.
Proof.
  case=> _ psdM; rewrite /mxtrace; apply: sumr_ge0 => i _.
  by rewrite -(qf_delta M i); exact: psdM.
Qed.

(* Положительно определённая матрица обратима. *)
Lemma pd_invertible n (M : 'M[C]_n) : pd M -> M \in unitmx.
Proof.
  move=> [Msym pdM]; apply: contraT => Mnu.
  have cokerNZ : cokermx M != 0 by rewrite cokermx_eq0 row_full_unit.
  have /matrix0Pn [i [j Cij_nz]] := cokerNZ.
  pose v := cokermx M *m delta_mx j ord0 : 'cV[C]_n.
  have vNZ : v != 0.
    apply/cV0Pn; exists i; rewrite /v -colE mxE; exact: Cij_nz.
  have Mv0 : M *m v = 0 by rewrite /v mulmxA mulmx_coker mul0mx.
  by move: (pdM v vNZ); rewrite -mulmxA Mv0 mulmx0 mxtrace0 ltxx.
Qed.

(* Сумма положительно определённых матриц также
   положительно определена. *)
Lemma pd_add n (A B : 'M[C]_n) : pd A -> psd B -> pd (A + B).
Proof.
  move=> [Asym pdA] [Bsym psdB]; split.
    by rewrite trmxC_add -Asym -Bsym.
  move=> v vNZ.
  rewrite mulmxDr mulmxDl mxtraceD addrC.
  exact: ltr_wpDl (psdB v) (pdA v vNZ).
Qed.

(* Обратная матрица к положительно определённой
   также определена положительно. *)
Lemma pd_inv n (M : 'M[C]_n) : pd M -> pd (invmx M).
Proof.
  move=> pdM; have Munit : M \in unitmx := pd_invertible pdM.
  case: pdM => Msym pdMq; split.
    by rewrite trmx_inv map_invmx -Msym.
  move=> v vNZ.
  pose w := invmx M *m v.
  have vw : v = M *m w by rewrite /w mulmxA mulmxV // mul1mx.
  have wNZ : w != 0.
    apply: contraNneq vNZ => w0.
    by rewrite vw w0 mulmx0.
  have eq_qform : v^t* *m invmx M *m v = w^t* *m M *m w.
    rewrite vw trmxC_mul -Msym.
    rewrite [in LHS]mulmxA.
    rewrite -[in LHS](mulmxA _ (invmx M) M).
    by rewrite mulVmx // mulmx1.
  by rewrite eq_qform; exact: pdMq.
Qed.

End PSD.
