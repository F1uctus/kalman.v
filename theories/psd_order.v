(*  Порядок Лёвнера (Loewner) на эрмитовых матрицах над                  *)
(*  numClosedFieldType.                                                   *)
(*                                                                        *)
(*  A <= B  <=>  B - A положительно полуопределена.                       *)

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Top Require Import psd_base.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section PsdOrder.
Variable (C : numClosedFieldType).

Definition psd_le n (A B : 'M[C]_n) : Prop := psd (B - A).

Lemma psd_le_refl n (A : 'M[C]_n) : psd A -> psd_le A A.
Proof.
  move=> _; rewrite /psd_le subrr; split; first by rewrite trmxC0.
  by move=> v; rewrite mulmx0 mul0mx mxtrace0 lexx.
Qed.

Lemma psd_le_trans n (A B D : 'M[C]_n) :
  psd_le A B -> psd_le B D -> psd_le A D.
Proof.
  rewrite /psd_le => hAB hBD.
  have hSum : psd ((B - A) + (D - B)) := psd_add hAB hBD.
  suff -> : D - A = (B - A) + (D - B) by exact: hSum.
  by rewrite addrC -addrA addrCA [B + (D - B)]addrCA addrN addr0.
Qed.

Lemma psd_le_congr n p (A B : 'M[C]_n) (M : 'M[C]_(n, p)) :
  psd_le A B -> psd_le (M^t* *m A *m M) (M^t* *m B *m M).
Proof.
  rewrite /psd_le => hAB.
  have -> : M^t* *m B *m M - M^t* *m A *m M = M^t* *m (B - A) *m M.
    by rewrite mulmxBr mulmxBl.
  exact: psd_congruence hAB.
Qed.

Lemma psd_le0_psd n (A : 'M[C]_n) : psd_le 0 A <-> psd A.
Proof. by rewrite /psd_le subr0. Qed.

Lemma psd_le_add2l n (A B D : 'M[C]_n) :
  psd_le A B -> psd_le (D + A) (D + B).
Proof.
  rewrite /psd_le => hAB.
  by rewrite opprD addrACA subrr add0r.
Qed.

Hypothesis psd_le_antisym :
  forall n (A B : 'M[C]_n), psd_le A B -> psd_le B A -> A = B.

End PsdOrder.
