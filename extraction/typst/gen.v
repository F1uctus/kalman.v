(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Runs the RenderTypst command via the dune rule: prints the statements listed
  in kalman_typst.v into rocq2typst.json. The file is not part of the
  KalmanTypst theory and is built only by the rule in this directory's dune.
*)

From KalmanTypst Require Import kalman_typst.

Elpi RenderTypst "rocq2typst.json".
