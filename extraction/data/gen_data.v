(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Запуск команды WriteJson по правилу dune: печать восьми документов с сырыми
  данными фигур. Файл не входит в теорию KalmanData и собирается только
  правилом из dune этого каталога.
*)

From KalmanData Require Import kalman_data.

Elpi WriteJson "dare_convergence.json" (d_dare).
Elpi WriteJson "gramian.json"          (d_gramian).
Elpi WriteJson "schur_stability.json"  (d_schur).
Elpi WriteJson "kalman_run.json"       (d_run).
Elpi WriteJson "kalman_run_3d.json"    (d_run3).
Elpi WriteJson "orthogonality.json"    (d_ortho).
Elpi WriteJson "lyapunov.json"         (d_lyap).
Elpi WriteJson "spectral.json"         (d_spectral).
