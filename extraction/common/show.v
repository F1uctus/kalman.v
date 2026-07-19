(*
  Печать рациональных чисел для драйвера на C

  Точное рациональное значение выводится строкой вида "num/den" в
  десятичной записи; знаменатель целого значения равен 1. Значение
  bigQ предварительно приводится к типу Q из Stdlib. Строка
  преобразуется в список байтов, который скомпилированная CertiRocq
  программа возвращает драйверу на C.
*)

Set Warnings "-all".
From Stdlib Require Import ZArith QArith Decimal DecimalString DecimalZ.
From Stdlib Require Import Strings.String Strings.Ascii Strings.Byte List.
From Bignums Require Import BigQ.

Local Open Scope string_scope.

(* Десятичная запись целого числа типа Z. *)
Definition string_of_Z (z : Z) : string :=
  DecimalString.NilZero.string_of_int (Z.to_int z).

(* Запись Q строкой "num/den". *)
Definition string_of_Q (q : Q) : string :=
  string_of_Z (Qnum q) ++ "/" ++ string_of_Z (Zpos (Qden q)).

(* Запись bigQ строкой "num/den" после приведения к типу Q. *)
Definition string_of_bigQ (q : bigQ) : string := string_of_Q (BigQ.to_Q q).

(* Список байтов строки; драйвер на C печатает их по одному. *)
Definition bytes_of_string (s : string) : list byte :=
  list_byte_of_string s.

(* Символ перевода строки. *)
Definition nl : string := String "010"%char EmptyString.
