// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/dare-cone.typ — the PSD cone of 2x2 covariances, with the Riccati
// trajectory climbing from the apex P_0 = 0 to the DARE fixed point P_ss.
//
// 2x2 symmetric matrices live in R^3 with coordinates (P11, P12, P22); the PSD
// ones form the cone { P11,P22 >= 0, P11*P22 >= P12^2 }, whose boundary is the
// rank-1 matrices lambda * v v^T. In the coordinates v = (P11-P22)/2, w = P12,
// u = (P11+P22)/2 this is the circular cone u >= sqrt(v^2 + w^2): the trace axis
// u is the axis of symmetry, the cross-section at height u a disk of radius u.
// Two views of one picture:
//   (a) the 3D cone with the monotone ascent inside it (riccati_mono.v: the
//       Loewner order is the cone order, P_k <= P_{k+1}; dare.v: P_k -> P_ss);
//   (b) the same trajectory seen end-on (down the trace axis): a disk, the
//       trajectory threading its interior, P_ss strictly inside the rank-1 rim.
//
// Data: paper/data/dare_convergence.json (each iteration's 2x2 matrix P).

#import "@preview/cetz:0.5.2"
#import "../common/markup-shorthands.typ": *
#import "proj3.typ": default-view, proj
#import "wire.typ": load
#import "style.typ": viz-canvas, viz-resolve

#let raw = load("/paper/data/dare_convergence.json")
#let dare-cone-data = (P_ss: raw.P_ss, iterations: raw.iterations.map(P => (P: P)))

// Boundary ray direction d(theta) = lambda*v v^T for v=(cos,sin):
//   (P11, P12, P22) = (cos^2, cos*sin, sin^2).  Period pi traces the whole cone.
#let cone-dir(th) = (
  calc.cos(th) * calc.cos(th),
  calc.cos(th) * calc.sin(th),
  calc.sin(th) * calc.sin(th),
)

#let mat-to-xyz(P) = (P.at(0).at(0), P.at(0).at(1), P.at(1).at(1))
#let trace-of(P) = P.at(0).at(0) + P.at(1).at(1)

// gradient light -> dark along the trajectory (early light, late dark)
#let traj-color(frac) = luma((1 - frac) * 55%)

// ---- Panel (a): the PSD cone in 3D with the climbing Riccati trajectory ----
#let cone-3d(data, st, s: 0.95) = viz-canvas(st, cetz.canvas(length: 1cm, {
  let view = default-view
  let P = p => proj(p, view: view)
  let O = P((0, 0, 0))

  // PSD cone wireframe (light gray): rank-1 rim + radial generators.
  let nrim = 60
  let rim = range(nrim + 1).map(i => P(
    cone-dir(i / nrim * calc.pi).map(x => x * s),
  ))
  cetz.draw.line(..rim, stroke: gray.lighten(15%) + 0.5pt, close: true)
  for i in range(13) {
    cetz.draw.line(
      O,
      P(cone-dir(i / 12 * calc.pi).map(x => x * s)),
      stroke: gray.lighten(50%) + 0.4pt,
    )
  }

  // coordinate axes: P11 up-right, P22 up-left, P12 into the page (depth).
  let aL = s * 1.18
  let dL = s * 0.78
  cetz.draw.line(O, P((aL, 0, 0)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(
    P((aL, 0, 0)),
    text(size: st.label)[$P_(1 1)$],
    anchor: "west",
    padding: 0.12,
  )
  cetz.draw.line(O, P((0, 0, aL)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(
    P((0, 0, aL)),
    text(size: st.label)[$P_(2 2)$],
    anchor: "east",
    padding: 0.12,
  )
  cetz.draw.line(O, P((0, dL, 0)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(
    P((0, dL, 0)),
    text(size: st.label)[$P_(1 2)$],
    anchor: "north-east",
    padding: 0.1,
  )

  // trajectory P_k = iter k riccati_step 0
  let xyz = data.iterations.map(it => mat-to-xyz(it.P))
  let pts = xyz.map(P)
  let n = pts.len()

  // a single drop line from P_ss to the P12 = 0 floor, for depth anchoring
  let q = mat-to-xyz(data.P_ss)
  cetz.draw.line(P(q), P((q.at(0), 0, q.at(2))), stroke: (
    paint: red.lighten(35%),
    dash: "dashed",
    thickness: 0.5pt,
  ))

  // climbing polyline + dots, gradient light -> dark
  for i in range(n - 1) {
    cetz.draw.line(
      pts.at(i),
      pts.at(i + 1),
      stroke: traj-color(i / (n - 1)) + 1.1pt,
    )
  }
  for (i, p) in pts.enumerate() {
    cetz.draw.circle(
      p,
      radius: 0.045,
      fill: traj-color(i / (n - 1)),
      stroke: none,
    )
  }

  // P_ss (red)
  cetz.draw.circle(P(q), radius: 0.09, fill: red, stroke: none)
  cetz.draw.content(
    P(q),
    text(size: st.label, fill: red)[$P_ss$],
    anchor: "west",
    padding: 0.16,
  )

  // apex
  cetz.draw.content(
    O,
    text(size: st.annot)[$P_0 = 0$],
    anchor: "north",
    padding: 0.2,
  )
}))

// ---- Panel (b): the same trajectory seen end-on, down the trace axis ----
// Coordinates (w, v) = (P12, (P11-P22)/2): the cone cross-section is a disk of
// radius trace/2, so P_ss lands strictly inside the rank-1 rim, well off every
// axis. The early iterates start near the rim (nearly rank-1) and move inward as
// the covariance becomes positive definite.
#let cone-crosssection(data, st, s: 6.5) = viz-canvas(st, cetz.canvas(
  length: 1cm,
  {
    let proj2 = P => (
      P.at(0).at(1) * s,
      (P.at(0).at(0) - P.at(1).at(1)) / 2 * s,
    )
    let r-ss = trace-of(data.P_ss) / 2 * s

    // a couple of faint inner cross-sections (smaller traces) + the bold rim
    for f in (0.4, 0.68) {
      cetz.draw.circle(
        (0, 0),
        radius: r-ss * f,
        stroke: gray.lighten(55%) + 0.5pt,
      )
    }
    cetz.draw.circle((0, 0), radius: r-ss, stroke: gray.lighten(5%) + 1pt)
    cetz.draw.content(
      (r-ss * calc.cos(35deg), r-ss * calc.sin(35deg)),
      text(size: st.annot, fill: gray.darken(20%))[ранг 1],
      anchor: "south-west",
      padding: 0.05,
    )

    // axes through the centre (scalar matrices)
    let aL = r-ss * 1.4
    cetz.draw.line((-aL, 0), (aL, 0), mark: (end: ">"), stroke: black + 0.5pt)
    cetz.draw.content(
      (aL, 0),
      text(size: st.label)[$P_(1 2)$],
      anchor: "west",
      padding: 0.1,
    )
    cetz.draw.line((0, -aL), (0, aL), mark: (end: ">"), stroke: black + 0.5pt)
    cetz.draw.content(
      (0, aL),
      text(size: st.annot)[$(P_(1 1) - P_(2 2)) \/ 2$],
      anchor: "south",
      padding: 0.1,
    )

    // trajectory in the cross-section plane
    let pts = data.iterations.map(it => proj2(it.P))
    let n = pts.len()
    for i in range(n - 1) {
      cetz.draw.line(
        pts.at(i),
        pts.at(i + 1),
        stroke: traj-color(i / (n - 1)) + 1.1pt,
      )
    }
    for (i, p) in pts.enumerate() {
      cetz.draw.circle(
        p,
        radius: 0.05,
        fill: traj-color(i / (n - 1)),
        stroke: none,
      )
    }

    // P_ss (red)
    let qp = proj2(data.P_ss)
    cetz.draw.circle(qp, radius: 0.09, fill: red, stroke: none)
    cetz.draw.content(
      qp,
      text(size: st.label, fill: red)[$P_ss$],
      anchor: "west",
      padding: 0.14,
    )
  },
))

// `dir: ttb` stacks the panels vertically (used on slides). `panels` selects the
// sub-figures by key ("a" — конус, "b" — сечение); по умолчанию обе. При выборе
// одной буквенная подпись (а)/(б) опускается: различать нечего, поэтому рисунок
// выводится без подписи и на слайде показывается крупно.
#let dare-cone-figure(
  data: dare-cone-data,
  style: (:),
  dir: ltr,
  panels: ("a", "b"),
) = {
  let st = viz-resolve(style)
  let make(key) = if key == "a" {
    (body: cone-3d(data, st), caption: [(а) конус и подъём траектории])
  } else {
    (
      body: cone-crosssection(data, st),
      caption: [(б) сечение ортогонально оси следа],
    )
  }
  let chosen = panels.map(make)
  if chosen.len() == 1 {
    return chosen.first().body
  }
  let items = chosen.map(p => stack(
    spacing: 0.6em,
    p.body,
    align(center, text(size: st.subcaption, p.caption)),
  ))
  if dir == ttb {
    grid(columns: (auto,), row-gutter: 1.2em, align: center, ..items)
  } else {
    grid(columns: (auto, auto), column-gutter: 2em, align: horizon, ..items)
  }
}
