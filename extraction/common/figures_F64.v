(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  float64 instantiation of the figure documents as byte lists (unverified
  numerics, `schur_pow_doc`), with the float coefficient printer, consumed by
  ../c
*)

Set Warnings "-all".
From Stdlib Require Import BinNat ZArith QArith Floats SpecFloat FloatOps.
From Stdlib Require Import List Strings.String Strings.Byte.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Kalman.seqmx Require Import
  support inverse riccati gramian closed_loop sim inst_Float64.
From KalmanShow Require Import show show_json figures.

Local Open Scope string_scope.

(* Exact translation of a finite double to the rational $(-1)^s m 2^e$. *)
Definition q_of_float (x : float) : Q :=
  match Prim2SF x with
  | S754_finite s m e =>
      let n := if s then Zneg m else Zpos m in
      if (0 <=? e)%Z then Qmake (n * 2 ^ e) 1
      else Qmake n (Z.to_pos (2 ^ (- e)))
  | _ => 0%Q
  end.

(* Coefficient printer; infinity and not-a-number print as non-JSON words. *)
Definition fnum (x : float) : string :=
  match Prim2SF x with
  | S754_nan => "nan"
  | S754_infinity s => if s then "-inf" else "inf"
  | _ => q_dec 20 (q_of_float x)
  end.

(* The documents as byte lists; CertiRocq compiles them. *)
Definition dare_json     : list byte := bytes_of_string (dare_doc      float fnum).
Definition gramian_json  : list byte := bytes_of_string (gramian_doc   float fnum).
Definition schur_json    : list byte := bytes_of_string (schur_pow_doc float fnum).
Definition run_json      : list byte := bytes_of_string (run_doc       float fnum).
Definition run3_json     : list byte := bytes_of_string (run3_doc      float fnum).
Definition ortho_json    : list byte := bytes_of_string (ortho_doc     float fnum).
Definition lyap_json     : list byte := bytes_of_string (lyap_doc      float fnum).
Definition spectral_json : list byte := bytes_of_string (spectral_doc  float fnum).
