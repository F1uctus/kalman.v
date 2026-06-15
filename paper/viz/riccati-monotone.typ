// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/riccati-monotone.typ — Loewner monotonicity of the Riccati iteration.
//
// Reuses the covariance-ellipse panel and data of dare-convergence.typ. The
// chain of nested, growing ellipses is the geometric content of
// theories/riccati_mono.v `riccati_iter0_mono`: starting from P_0 = 0,
// P_k <= P_{k+1} in the Loewner order, so each covariance ellipse contains the
// previous one and they increase up to the steady-state ellipse P_ss.

#import "dare-convergence.typ": panel-ellipses, dare-data

#let riccati-monotone-figure(data: dare-data, style: (:)) = panel-ellipses(
  data,
  max-shown: 8,
  style: style,
)
