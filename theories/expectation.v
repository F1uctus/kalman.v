(*  Алгебраическая аксиоматизация оператора математического ожидания  *)
(*  над матричными величинами.                                          *)
(*                                                                       *)
(*  Моделируем `Exp` как матричнозначное линейное отображение,           *)
(*  параметризованное полем `C : numClosedFieldType`.  Аксиомы:           *)
(*    * `Exp_add`      — аддитивность,                                  *)
(*    * `Exp_scale`    — однородность относительно скалярного множителя, *)
(*    * `Exp_mulmx_l`  — вынос детерминированной матрицы за знак         *)
(*                       ожидания (слева).                               *)
(*                                                                       *)
(*  Производные тождества `Exp_zero`, `Exp_opp`, `Exp_sub` выводятся    *)
(*  из аксиом и используются в `kalman.v` для доказательства              *)
(*  несмещённости.                                                       *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Local Open Scope ring_scope.

Section ExpAlgebra.
Variable (C : numClosedFieldType).

(* Абстрактный оператор математического ожидания. *)
Variable Exp : forall {r c : nat}, 'M[C]_(r, c) -> 'M[C]_(r, c).

(* Аксиомы линейности. *)
Hypothesis Exp_add : forall r c (A B : 'M[C]_(r, c)),
  Exp (A + B) = Exp A + Exp B.
Hypothesis Exp_scale : forall r c (a : C) (A : 'M[C]_(r, c)),
  Exp (a *: A) = a *: Exp A.
Hypothesis Exp_mulmx_l : forall r c s (A : 'M[C]_(r, c)) (B : 'M[C]_(c, s)),
  Exp (A *m B) = A *m Exp B.

(* Производные тождества. *)

Lemma Exp_zero r c : Exp (0 : 'M[C]_(r, c)) = 0.
Proof.
  have e := Exp_scale (0 : C) (0 : 'M[C]_(r, c)).
  by rewrite !scale0r in e.
Qed.

Lemma Exp_opp r c (A : 'M[C]_(r, c)) : Exp (- A) = - Exp A.
Proof.
  have -> : -A = (-1) *: A by rewrite scaleN1r.
  by rewrite Exp_scale scaleN1r.
Qed.

Lemma Exp_sub r c (A1 A2 : 'M[C]_(r, c)) :
  Exp (A1 - A2) = Exp A1 - Exp A2.
Proof. by rewrite Exp_add Exp_opp. Qed.

End ExpAlgebra.
