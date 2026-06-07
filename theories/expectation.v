(* Алгебраическая аксиоматизация математического ожидания над матрицами. *)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Local Open Scope ring_scope.

Section Expectation.

  Variable (ℂ : numClosedFieldType).

  (* Абстрактный оператор математического ожидания. *)
  Variable 𝔼 : forall {r c : nat}, 'M[ℂ]_(r, c) -> 'M[ℂ]_(r, c).

  (* Аксиомы линейности. *)

  Hypothesis Exp_add : forall r c (A B : 'M[ℂ]_(r, c)),
    𝔼 (A + B) = 𝔼 A + 𝔼 B.

  Hypothesis Exp_scale : forall r c (a : ℂ) (A : 'M[ℂ]_(r, c)),
    𝔼 (a *: A) = a *: 𝔼 A.

  Hypothesis Exp_mulmx_l : forall r c s (A : 'M[ℂ]_(r, c)) (B : 'M[ℂ]_(c, s)),
    𝔼 (A *m B) = A *m 𝔼 B.

  (* Производные тождества. *)

  Lemma Exp_zero r c :
    𝔼 (0 : 'M[ℂ]_(r, c)) = 0.
  Proof.
    have e := Exp_scale (0 : ℂ) (0 : 'M[ℂ]_(r, c)).
    by rewrite !scale0r in e.
  Qed.

  Lemma Exp_opp r c (A : 'M[ℂ]_(r, c)) :
    𝔼 (- A) = - 𝔼 A.
  Proof.
    have -> : -A = (-1) *: A by rewrite scaleN1r.
    by rewrite Exp_scale scaleN1r.
  Qed.

  Lemma Exp_sub r c (A1 A2 : 'M[ℂ]_(r, c)) :
    𝔼 (A1 - A2) = 𝔼 A1 - 𝔼 A2.
  Proof.
    by rewrite Exp_add Exp_opp.
  Qed.

End Expectation.
