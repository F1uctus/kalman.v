(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Запуск команды RenderTypst по правилу dune: печать перечисленных в
  kalman_typst.v утверждений в rocq2typst.json. Файл не входит в теорию
  KalmanTypst и собирается только правилом из dune этого каталога.
*)

From KalmanTypst Require Import kalman_typst.

Elpi RenderTypst "rocq2typst.json".
