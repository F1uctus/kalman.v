
Set Warnings "-all".
From Kalman.seqmx Require Import riccati_seqmx experiments kalman_sim.
Require Extraction.

Extraction Language OCaml.
Set Extraction KeepSingleton.

(* Идиоматичные типы OCaml для чистого извлечённого кода. *)
Extract Inductive bool => "bool" [ "true" "false" ].
Extract Inductive list => "list" [ "[]" "( :: )" ].
Extract Inductive prod => "( * )" [ "( , )" ].
(*
  Конструктор S отображается в полностью квалифицированный Stdlib.Int.succ:
  неквалифицированное `succ` внутри извлечённых модулей Pos/N затеняется
  одноимённой функцией Pos.succ, что искажает арифметику (Pos.succ 0 = 2).
*)
Extract Inductive nat => "int" [ "0" "Stdlib.Int.succ" ]
  "(fun fO fS n -> if n=0 then fO () else fS (n-1))".

(*
  Двоичные числа positive/N/Z генератора Лемера (kalman_sim.v) отображаются
  в int OCaml; значения генератора не превосходят модуля 65537.
*)
From Stdlib Require Import ExtrOcamlZInt.

Extraction "riccati.ml"
  riccati_step_seqmx predict_cov_seqmx innov_cov_seqmx filter_gain_seqmx
  update_cov_seqmx alt_update_cov_seqmx ctr_seqmx cinv_fl
  mpow_seqmx obsv_gram_seqmx ctrl_gram_seqmx closed_loop_seqmx
  kalman_sim_run.
