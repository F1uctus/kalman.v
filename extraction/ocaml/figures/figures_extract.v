(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Extraction of the generic figure documents to figures.ml.
*)
Set Warnings "-all".
From KalmanShow Require Import figures.
Require Extraction.

Extraction Language OCaml.
Set Extraction KeepSingleton.

(* Idiomatic OCaml types for clean extracted code. *)
Extract Inductive bool => "bool" [ "true" "false" ].
Extract Inductive list => "list" [ "[]" "( :: )" ].
Extract Inductive prod => "( * )" [ "( , )" ].
(*
  The constructor S maps to the fully qualified Stdlib.Int.succ: an unqualified
  `succ` inside the extracted Pos/N modules is shadowed by the same-named Pos.succ
  function, which corrupts the arithmetic (Pos.succ 0 = 2).
*)
Extract Inductive nat => "int" [ "0" "Stdlib.Int.succ" ]
  "(fun fO fS n -> if n=0 then fO () else fS (n-1))".

(* The Lehmer generator integers (sim.v) map to OCaml int. *)
From Stdlib Require Import ExtrOcamlZInt.
(* Rocq strings map to an OCaml char list. *)
From Stdlib Require Import ExtrOcamlString.

Extraction "figures.ml"
  dare_doc gramian_doc schur_pow_doc run_doc run3_doc ortho_doc lyap_doc
  spectral_doc.
