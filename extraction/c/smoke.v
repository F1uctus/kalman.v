(*
  Smoke tests of the CertiRocq pipeline.

  Closed expressions are formatted into strings and compiled to C; the reference
  strings are pinned by a proof through vm_compute, and the output of the
  compiled programs is checked against them byte for byte.

  The first test (Q, the default pipeline) covers Z and Q arithmetic with
  reduction of fractions, the Decimal and String path and the traversal of a
  byte list from C; this is the working pipeline of the directory. The second
  test (bigQ, the -unsafe-erasure option) exercises support for coinductive
  types: the bigQ closure contains a stream from StreamMemo (the memo of BigN
  operations), which the default pipeline does not translate.
*)

Set Warnings "-all".
From Stdlib Require Import ZArith QArith Qreduction List Strings.String Strings.Byte.
From Bignums Require Import BigQ.
From KalmanShow Require Import show.
From CertiRocq.Plugin Require Import CertiRocq.

Set CertiRocq Build Directory "generated".

(* (2/7)^2 + (3)^(-1) = 4/49 + 1/3 = 61/147, then deep arithmetic. *)
Definition smoke_q : Q := Qred ((2 # 7) * (2 # 7) + / 3)%Q.
Definition smoke_deep : Q :=
  Qred (Qpower (44 # 14) 17 + Qpower (3 # 9) 23 - 1)%Q.

Definition smoke_out : list byte :=
  bytes_of_string
    (append (string_of_Q smoke_q) (append nl (string_of_Q smoke_deep))).

Example smoke_expected :
  string_of_Q smoke_q = "61/147"%string /\
  string_of_Q smoke_deep =
    "6236981143076424064767066702984442/21900576078914553391266189"%string.
Proof. vm_compute. split; reflexivity. Qed.

CertiRocq Compile -O 1 -file "smoke" smoke_out.
CertiRocq Generate Glue -file "glue_smoke" [ list, byte ].

(* The same check over bigQ with a multi-word integer at the zn2z level. *)
Local Open Scope bigQ_scope.

Definition smoke_bq : bigQ :=
  BigQ.add_norm (BigQ.mul_norm (2 # 7) (2 # 7)) (BigQ.inv_norm (3 # 1)).
Definition smoke_bq_big : bigQ :=
  BigQ.mul_norm (123456789123456789 # 1) (123456789123456789 # 1).

Definition smoke_bq_out : list byte :=
  bytes_of_string
    (append (string_of_bigQ smoke_bq)
       (append nl (string_of_bigQ smoke_bq_big))).

Example smoke_bq_expected :
  string_of_bigQ smoke_bq = "61/147"%string /\
  string_of_bigQ smoke_bq_big =
    "15241578780673678515622620750190521/1"%string.
Proof. vm_compute. split; reflexivity. Qed.

CertiRocq Compile -unsafe-erasure -O 1 -file "smoke_bq" smoke_bq_out.
