(*
  Печать рациональных чисел десятичной дробью и сборка документа JSON
  фигур. Значение Q выводится с фиксированным числом дробных знаков (20),
  чего достаточно для точного восстановления числа двойной точности при
  чтении в Typst. Массивы и объекты собираются простыми строковыми
  комбинаторами; печать матрицы строится из печати коэффициента в
  figures.v, поэтому она не зависит от коэффициентного типа.
*)
Set Warnings "-all".
From Stdlib Require Import ZArith QArith List Strings.String Strings.Ascii.
From mathcomp.boot Require Import all_boot.
From KalmanShow Require Import show. (* string_of_Z *)

Local Open Scope string_scope.

Fixpoint frac_digits (p : nat) (rem den : Z) : string :=
  match p with
  | O => ""
  | S p' =>
      let r10 := (rem * 10)%Z in
      let d := (r10 / den)%Z in
      let r := (r10 mod den)%Z in
      String (ascii_of_nat (48 + Z.to_nat d)) (frac_digits p' r den)
  end.

Definition q_dec (p : nat) (q : Q) : string :=
  let n := Qnum q in
  let d := Zpos (Qden q) in
  let s := if (n <? 0)%Z then "-" else "" in
  let a := Z.abs n in
  s ++ string_of_Z (a / d)%Z ++ "." ++ frac_digits p (a mod d)%Z d.

Definition jnum (q : Q) : string := q_dec 20 q.
Definition jnat (n : nat) : string := string_of_Z (Z.of_nat n).
Definition jarr (xs : list string) : string := "[" ++ String.concat "," xs ++ "]".
Definition jobj (kvs : list (string * string)) : string :=
  "{" ++ String.concat ","
        (map (fun kv => """" ++ fst kv ++ """:" ++ snd kv) kvs) ++ "}".
