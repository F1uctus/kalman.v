(*
  Извлечение доказанной seqmx-программы шага Риккати в OCaml.

  Извлекается обобщённый терм `riccati_step_seqmx` (слой операций CoqEAL):
  коэффициентный тип и кольцевые операции - параметры словаря, поэтому в коде
  программы нет `Obj.magic`, а коэффициент подставляется в OCaml (zarith `Q.t`,
  вычислимый аналог `bigQ`). Это тот же терм, который над `bigQ` доказанно
  уточняет спецификацию (`inst_bigQ.riccati_iter_seqmxC`).
*)
Set Warnings "-all".
From Kalman.seqmx Require Import support inverse riccati gramian closed_loop sim.
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
  Двоичные числа positive/N/Z генератора Лемера (sim.v) отображаются
  в int OCaml; значения генератора не превосходят модуля 65537.
*)
From Stdlib Require Import ExtrOcamlZInt.

Extraction "riccati.ml"
  riccati_step_seqmx predict_cov_seqmx innov_cov_seqmx filter_gain_seqmx
  update_cov_seqmx alt_update_cov_seqmx ctr_seqmx cinv_fl
  mpow_seqmx obsv_gram_seqmx ctrl_gram_seqmx closed_loop_seqmx
  kalman_sim_run kalman_sim3_run sim3_seed.
