// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/duality-square.typ — the duality of the gramians as a commuting square.
//
// Building the gramian commutes with dualizing: starting from (F, G, Q) one may
// either build the controllability gramian C_k directly, or first dualize to
// (F*, G*, Q^-1) and build the observability gramian O_k — the result is the same
// matrix. The bottom edge (the equality) is exactly theories/duality.v
// `ctrl_gram_dual`. The same square commutes for the optimal Riccati solutions
// P_ss / S_ss (classical, not re-proven here) — shown as a faint echo. No data.

#import "@preview/cetz:0.5.2"

#let duality-square-figure = cetz.canvas(length: 1cm, {
  let xL = -3.5
  let xR = 3.5
  let yT = 1.5
  let yB = -1.5

  let cbox(pos, body) = cetz.draw.content(
    pos,
    box(stroke: 0.6pt + gray.darken(10%), inset: 6pt, radius: 3pt, body),
  )

  // corners
  cbox((xL, yT), text(size: 12pt)[$(F, G, Q)$])
  cbox((xR, yT), text(size: 12pt)[$(F^*, G^*, Q^(-1))$])
  cbox((xL, yB), text(size: 12pt)[$cal(C)_s$])
  cbox((xR, yB), text(size: 12pt)[$cal(O)_s$])

  // top edge: dualize
  cetz.draw.line(
    (xL + 1.5, yT),
    (xR - 1.7, yT),
    mark: (end: ">", scale: 0.6),
    stroke: black + 0.9pt,
  )
  cetz.draw.content((0, yT + 0.34), text(size: 10pt)[$(dot)^*$])

  // left edge: build the controllability gramian
  cetz.draw.line(
    (xL, yT - 0.7),
    (xL, yB + 0.6),
    mark: (end: ">", scale: 0.6),
    stroke: black + 0.9pt,
  )
  cetz.draw.content(
    (xL - 0.2, (yT + yB) / 2),
    anchor: "east",
    text(size: 10pt, fill: rgb(20, 90, 160))[`ctrl_gram`],
  )

  // right edge: build the observability gramian
  cetz.draw.line(
    (xR, yT - 0.7),
    (xR, yB + 0.6),
    mark: (end: ">", scale: 0.6),
    stroke: black + 0.9pt,
  )
  cetz.draw.content(
    (xR + 0.2, (yT + yB) / 2),
    anchor: "west",
    text(size: 10pt, fill: rgb(20, 90, 160))[`obsv_gram`],
  )

  // bottom edge: the equality — this is the lemma
  cetz.draw.line((xL + 0.9, yB), (xR - 0.9, yB), stroke: black + 0.9pt)
  cetz.draw.content(
    (0, yB),
    box(fill: white, inset: (x: 3pt), text(size: 13pt)[$=$]),
  )
  cetz.draw.content(
    (0, yB - 0.42),
    text(size: 10pt, fill: rgb(20, 90, 160))[`ctrl_gram_dual`],
  )
})
