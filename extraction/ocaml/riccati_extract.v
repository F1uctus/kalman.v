
Set Warnings "-all".
From Kalman.seqmx Require Import riccati_seqmx experiments_seqmx.
Require Extraction.

Extraction Language OCaml.
Set Extraction KeepSingleton.

Extract Inductive bool => "bool" [ "true" "false" ].
Extract Inductive list => "list" [ "[]" "( :: )" ].
Extract Inductive prod => "( * )" [ "( , )" ].
Extract Inductive nat => "int" [ "0" "succ" ]
  "(fun fO fS n -> if n=0 then fO () else fS (n-1))".

Extraction "riccati.ml"
  riccati_step_seqmx predict_cov_seqmx innov_cov_seqmx kalman_gain_seqmx
  update_cov_seqmx alt_update_cov_seqmx ctr_seqmx cinv2
  mpow_seqmx obsv_gram_seqmx ctrl_gram_seqmx closed_loop_seqmx.
