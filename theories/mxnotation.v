(* Обозначения. *)

From Stdlib.Unicode Require Import Utf8.
From mathcomp.boot Require Import fintype.
From mathcomp.algebra Require Import matrix sesquilinear spectral.

Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(* Умножение матриц. *)
Notation "A ⋅ B" := (mulmx A B)
  (at level 40, left associativity, only printing, format "A  ⋅  B") : ring_scope.

Notation "M †" := (M^t*)
  (at level 30, only printing, format "M †") : sesquilinear_scope.

(* Стандартный базис: 'e_i строка, 'e_i† столбец. *)
Notation "''e_' i" := (delta_mx ord0 i)
  (at level 8, i at level 2, only printing, format "''e_' i") : ring_scope.

Notation "''e_' i '†'" := (delta_mx i ord0)
  (at level 8, i at level 2, only printing, format "''e_' i '†'") : ring_scope.
