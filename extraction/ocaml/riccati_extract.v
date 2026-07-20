(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Extraction of the generic Kalman filtering building blocks to riccati.ml.
*)
Set Warnings "-all".
From Kalman.seqmx Require Import support inverse riccati gramian closed_loop sim.
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

(* The positive/N/Z integers of the Lehmer generator (sim.v) map to OCaml int. *)
From Stdlib Require Import ExtrOcamlZInt.

Extraction "riccati.ml"
  riccati_step_seqmx predict_cov_seqmx innov_cov_seqmx filter_gain_seqmx
  update_cov_seqmx alt_update_cov_seqmx ctr_seqmx cinv_fl
  mpow_seqmx obsv_gram_seqmx ctrl_gram_seqmx closed_loop_seqmx
  kalman_sim_run kalman_sim3_run sim3_seed.
