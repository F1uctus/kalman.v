Set Warnings "-coercions".

From HB Require Import structures.
From Kalman Require Import mxnotation.
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

(*
  Эрмитово сопряжение матриц.
  https://ru.wikipedia.org/wiki/Эрмитово_сопряжённая_матрица.
*)
Section HermitianTranspose.

  Variable (ℂ : numClosedFieldType).

  Lemma trmxC_add m n (A B : 'M[ℂ]_(m, n)) :
    (A + B)^t* = A^t* + B^t*.
  Proof. by rewrite linearD /= map_mxD. Qed.

  Lemma trmxC_mul m n p (A : 'M[ℂ]_(m, n)) (B : 'M[ℂ]_(n, p)) :
    (A *m B)^t* = B^t* *m A^t*.
  Proof. by rewrite trmx_mul map_mxM. Qed.

  Lemma trmxC0 m n :
    (0 : 'M[ℂ]_(m, n))^t* = 0.
  Proof. by rewrite linear0 map_mx0. Qed.

  Lemma trmxCB m n (A B : 'M[ℂ]_(m, n)) :
    (A - B)^t* = A^t* - B^t*.
  Proof. by rewrite trmxC_add linearN /= map_mxN. Qed.

  Lemma trmxCN m n (A : 'M[ℂ]_(m, n)) :
    (- A)^t* = - A^t*.
  Proof. by rewrite linearN /= map_mxN. Qed.

  Lemma trmxC1 n :
    (1%:M : 'M[ℂ]_n)^t* = 1%:M.
  Proof. by rewrite trmx1 map_mx1. Qed.

  Lemma trmxC_scale m n (a : ℂ) (A : 'M[ℂ]_(m, n)) :
    (a *: A)^t* = a^* *: A^t*.
  Proof. by rewrite linearZ /= map_mxZ. Qed.

  (* Эрмитово сопряжение перестановочно со степенью квадратной матрицы. *)
  Lemma trmxCX m (M : 'M[ℂ]_m) k :
    (M^+k)^t* = (M^t*)^+k.
  Proof.
    elim: k => [|k IH]; first by rewrite !expr0 trmxC1.
    by rewrite exprS trmxC_mul IH exprSr.
  Qed.

  (*
    Зануление эрмитова сопряжения эквивалентно занулению самой матрицы.
    († - инволюция, через `trmxCK`).
  *)
  Lemma trmxC_eq0 m n (M : 'M[ℂ]_(m, n)) : (M^t* == 0) = (M == 0).
  Proof.
    apply/idP/idP => [/eqP h|/eqP ->]; last by rewrite trmxC0.
    by apply/eqP; rewrite -(trmxCK M) h trmxC0.
  Qed.

End HermitianTranspose.
