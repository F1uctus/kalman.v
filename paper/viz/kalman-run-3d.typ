// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/kalman-run-3d.typ — a 3D position-tracking Kalman run (helix), the spatial
// analogue of kalman-run.typ panel (a). An axonometric projection shows the true
// trajectory, the noisy measurements, and the filter estimate in space.
//
// Data: paper/data/kalman_run_3d.json, emitted by extraction/ocaml/driver.exe
// from the extracted verified program theories/seqmx/kalman_sim.v
// (kalman_sim3_run). The 6D state is (x, vx, y, vy, z, vz): the velocity rotates
// in the x-y plane (Pythagorean angle cos = 4/5, sin = 3/5) while position
// integrates it and z is constant-velocity, so the true path is a helix. Three
// positions are measured, so the innovation covariance is 3 x 3 and the run
// exercises the extracted general Faddeev-LeVerrier inverse. The same verified
// run is checked to stay inside the +/- 2 sigma corridor (sim3_run_in_band).

#import "@preview/cetz:0.5.2"
#import "wire.typ": load
#import "style.typ": viz-canvas, viz-resolve

#let raw = load("/paper/data/kalman_run_3d.json")
#let pos(m) = (m.at(0).at(0), m.at(2).at(0), m.at(4).at(0))
#let kalman3-data = (steps: raw.steps.enumerate().map(((k, s)) => {
  let base = (k: k, "true": pos(s.x_true), est: pos(s.x_est),
    sigma: (calc.sqrt(s.P.at(0).at(0)), calc.sqrt(s.P.at(2).at(2)), calc.sqrt(s.P.at(4).at(4))))
  if s.meas != none { base + (meas: (s.meas.at(0).at(0), s.meas.at(1).at(0), s.meas.at(2).at(0))) } else { base }
}))

// Axonometric view: z straight up, x to the right and toward the viewer, y to
// the left and toward the viewer (depth). The three unit axes map to fixed 2D
// screen vectors, so projection is linear.
#let view3 = (
  ex: (0.94, -0.34),
  ey: (-0.54, -0.30),
  ez: (0.0, 1.0),
)

// A small upright cross marker at canvas point m.
#let xmark(m, c, r) = {
  cetz.draw.line((m.at(0) - r, m.at(1) - r), (m.at(0) + r, m.at(1) + r), stroke: c)
  cetz.draw.line((m.at(0) - r, m.at(1) + r), (m.at(0) + r, m.at(1) - r), stroke: c)
}

// A short line sample for the manual legend.
#let lsample(c) = box(baseline: -0.12em, height: 0.2em, width: 1.4em, align(
  horizon,
  line(length: 1.4em, stroke: c + 1.1pt),
))

// `scale` is cm per normalised unit. All three axes are normalised by one shared
// span, so the figure preserves the true aspect ratio of the trajectory (no axis
// is stretched). `shown` limits the run to its leading steps (the rotation makes
// roughly ten steps per turn, so the default shows a single first loop of the
// helix). `legend-side` is "right" (a compact vertical list that costs no height)
// or "bottom".
#let kalman-run-3d-figure(
  data: kalman3-data,
  style: (:),
  scale: 5.6,
  shown: 12,
  legend-side: "right",
) = {
  let st = viz-resolve(style)
  let steps = if shown == none {
    data.steps
  } else {
    data.steps.slice(0, calc.min(shown, data.steps.len()))
  }

  // Collect every plotted point, then normalise all axes by one shared span so
  // the picture keeps the true proportions of the trajectory.
  let pts = ()
  for s in steps {
    pts.push(s.at("true"))
    pts.push(s.est)
    if "meas" in s { pts.push(s.meas) }
  }
  let lo = range(3).map(i => calc.min(..pts.map(p => p.at(i))))
  let hi = range(3).map(i => calc.max(..pts.map(p => p.at(i))))
  let span = range(3).map(i => {
    let d = hi.at(i) - lo.at(i)
    if d == 0 { 1.0 } else { d }
  })
  let gspan = calc.max(..span)
  let ext = span.map(d => d / gspan) // per-axis extent of the data box (<= 1)
  let nrm(p) = range(3).map(i => (p.at(i) - lo.at(i)) / gspan)
  let ax = ext.at(0)
  let ay = ext.at(1)
  let az = ext.at(2)

  let canvas = viz-canvas(st, cetz.canvas(length: 1cm, {
    // Project a point of the data box to canvas coordinates (linear axonometry).
    let P(q) = (
      scale
        * (
          q.at(0) * view3.ex.at(0)
            + q.at(1) * view3.ey.at(0)
            + q.at(2) * view3.ez.at(0)
        ),
      scale
        * (
          q.at(0) * view3.ex.at(1)
            + q.at(1) * view3.ey.at(1)
            + q.at(2) * view3.ez.at(1)
        ),
    )
    let PV(p) = P(nrm(p))

    // floor (z = 0 plane) with a light grid, and back vertical edges for depth
    let floor = ((0, 0, 0), (ax, 0, 0), (ax, ay, 0), (0, ay, 0))
    cetz.draw.line(..floor.map(P), close: true, stroke: luma(78%) + 0.5pt)
    let ng = 4
    for i in range(1, ng) {
      let t = i / ng
      cetz.draw.line(P((t * ax, 0, 0)), P((t * ax, ay, 0)), stroke: luma(90%) + 0.4pt)
      cetz.draw.line(P((0, t * ay, 0)), P((ax, t * ay, 0)), stroke: luma(90%) + 0.4pt)
    }
    for c in ((0, ay, 0), (ax, ay, 0), (ax, 0, 0)) {
      cetz.draw.line(P(c), P((c.at(0), c.at(1), az)), stroke: luma(88%) + 0.4pt)
    }

    // axis arrows and labels (kept just past the data extent on each axis)
    let aL = 1.06
    cetz.draw.line(P((0, 0, 0)), P((ax * aL, 0, 0)), mark: (end: ">"), stroke: black + 0.6pt)
    cetz.draw.content(P((ax * aL, 0, 0)), text(size: st.label, $x$), anchor: "west", padding: 0.1)
    cetz.draw.line(P((0, 0, 0)), P((0, ay * aL, 0)), mark: (end: ">"), stroke: black + 0.6pt)
    cetz.draw.content(P((0, ay * aL, 0)), text(size: st.label, $y$), anchor: "east", padding: 0.1)
    cetz.draw.line(P((0, 0, 0)), P((0, 0, az * aL)), mark: (end: ">"), stroke: black + 0.6pt)
    cetz.draw.content(P((0, 0, az * aL)), text(size: st.label, $z$), anchor: "south", padding: 0.1)

    // faint drop lines from true points to the floor (the helix cylinder)
    for s in steps {
      let p = nrm(s.at("true"))
      cetz.draw.line(P(p), P((p.at(0), p.at(1), 0)), stroke: luma(86%) + 0.3pt)
    }

    // measurements (dark crosses, kept high-contrast against the trajectories)
    for s in steps {
      if "meas" in s { xmark(PV(s.meas), luma(30%) + 1pt, 0.07) }
    }

    // true trajectory (blue)
    let tpts = steps.map(s => PV(s.at("true")))
    for i in range(tpts.len() - 1) {
      cetz.draw.line(tpts.at(i), tpts.at(i + 1), stroke: blue + 1.1pt)
    }

    // filter estimate (red line and dots)
    let epts = steps.map(s => PV(s.est))
    for i in range(epts.len() - 1) {
      cetz.draw.line(epts.at(i), epts.at(i + 1), stroke: red + 1pt)
    }
    for p in epts {
      cetz.draw.circle(p, radius: 0.045, fill: red.lighten(35%), stroke: red + 0.4pt)
    }
  }))

  let item(sample, label) = grid(
    columns: (1.6em, auto),
    column-gutter: 0.5em,
    align: (horizon, horizon + left),
    sample, text(size: st.legend, label),
  )
  let xcross = box(baseline: -0.12em, text(fill: luma(30%), size: st.legend, weight: "bold")[$times$])
  let legend-items = (
    item(lsample(blue), [истинная\ траектория]),
    item(xcross, [измерения]),
    item(lsample(red), [оценка\ фильтра]),
  )

  if legend-side == "bottom" {
    stack(
      spacing: 0.7em,
      canvas,
      align(center, grid(
        columns: legend-items.len() * (auto,),
        column-gutter: 1.4em,
        ..legend-items,
      )),
    )
  } else {
    grid(
      columns: (auto, auto),
      column-gutter: 1.3em,
      align: horizon,
      canvas,
      stack(spacing: 1.0em, ..legend-items),
    )
  }
}
