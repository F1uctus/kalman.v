(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Instantiating figures.ml at the float ring and writing the JSON files.
  The destination directory is the first command-line argument.
*)

(*
  Print a coefficient like `q_dec 20`: truncated, not rounded, to twenty
  fractional digits. `%.40f` rounds only at the fortieth digit, so cutting to
  the first twenty reproduces the truncation of the exact binary value.
*)
let q_dec20 (x : float) : string =
  if x <> x then "nan"
  else if x = infinity then "inf"
  else if x = neg_infinity then "-inf"
  else if x = 0. then "0." ^ String.make 20 '0'
  else
    let s = Printf.sprintf "%.40f" x in
    let dot = String.index s '.' in
    String.sub s 0 (dot + 1 + 20)

let chars_of_string (s : string) : char list =
  List.init (String.length s) (String.get s)

let string_of_chars (cs : char list) : string =
  let b = Buffer.create 4096 in
  List.iter (Buffer.add_char b) cs;
  Buffer.contents b

(* The coefficient printer in the shape the generic document expects. *)
let jnm (x : float) : char list = chars_of_string (q_dec20 x)

(* The float ring operations as the separate arguments of the CoqEAL dictionary. *)
let z = Ring_F64.zero
let o = Ring_F64.one
let n = Ring_F64.opp
let a = Ring_F64.add
let m = Ring_F64.mul
let i = Ring_F64.inv

(* File name and its contents; argument order follows the figures.mli signatures. *)
let documents : (string * char list) list =
  [ "dare_convergence.json", Figures.dare_doc     z o n a m i jnm
  ; "gramian.json",          Figures.gramian_doc  z o   a m i jnm
  ; "schur_stability.json",  Figures.schur_pow_doc z o n a m i jnm
  ; "kalman_run.json",       Figures.run_doc      z o n a m i jnm
  ; "kalman_run_3d.json",    Figures.run3_doc     z o n a m i jnm
  ; "orthogonality.json",    Figures.ortho_doc    z o n a m i jnm
  ; "lyapunov.json",         Figures.lyap_doc     z o   a m i jnm
  ; "spectral.json",         Figures.spectral_doc z o n a m i jnm ]

let () =
  let dir = if Array.length Sys.argv > 1 then Sys.argv.(1) else "." in
  List.iter
    (fun (name, chars) ->
      let path = Filename.concat dir name in
      let oc = open_out path in
      output_string oc (string_of_chars chars);
      close_out oc)
    documents
