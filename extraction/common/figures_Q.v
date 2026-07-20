(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Q instantiation of the figure documents as byte lists (verified numerics,
  `schur_doc` only), consumed by ../c
*)

Set Warnings "-all".
From Stdlib Require Import BinNat QArith List Strings.String Strings.Byte.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Kalman.seqmx Require Import
  support inverse riccati gramian closed_loop sim inst_Q.
From KalmanShow Require Import show show_json figures.

Local Open Scope string_scope.

Definition dare_json     : list byte := bytes_of_string (dare_doc     Q jnum).
Definition gramian_json  : list byte := bytes_of_string (gramian_doc  Q jnum).
Definition schur_json    : list byte := bytes_of_string (schur_doc    Q jnum).
Definition run_json      : list byte := bytes_of_string (run_doc      Q jnum).
Definition run3_json     : list byte := bytes_of_string (run3_doc     Q jnum).
Definition ortho_json    : list byte := bytes_of_string (ortho_doc    Q jnum).
Definition lyap_json     : list byte := bytes_of_string (lyap_doc     Q jnum).
Definition spectral_json : list byte := bytes_of_string (spectral_doc Q jnum).
