(* Printing rationals as "num/den" and strings to byte lists *)

Set Warnings "-all".
From Stdlib Require Import ZArith QArith Decimal DecimalString DecimalZ.
From Stdlib Require Import Strings.String Strings.Ascii Strings.Byte List.
From Bignums Require Import BigQ.

Local Open Scope string_scope.

(* Decimal notation of an integer of type Z. *)
Definition string_of_Z (z : Z) : string :=
  DecimalString.NilZero.string_of_int (Z.to_int z).

(* Notation of Q as the string "num/den". *)
Definition string_of_Q (q : Q) : string :=
  string_of_Z (Qnum q) ++ "/" ++ string_of_Z (Zpos (Qden q)).

(* Notation of bigQ as the string "num/den" after conversion to the type Q. *)
Definition string_of_bigQ (q : bigQ) : string := string_of_Q (BigQ.to_Q q).

(* The byte list of a string; the C driver prints them one by one. *)
Definition bytes_of_string (s : string) : list byte :=
  list_byte_of_string s.

(* The newline character. *)
Definition nl : string := String "010"%char EmptyString.
