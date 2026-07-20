// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/kalman-run.typ — a Kalman filter run over synthetic data.
//
// Data: paper/data/kalman_run.json, emitted by extraction/ocaml/figures/gen_data.ml. The
// whole run is the extracted verified program theories/seqmx/sim.v: the
// noises come from the four-point model of theories/noise.v, the sample path is
// the Lehmer generator defined inside Rocq, and the covariance band is the
// exact Riccati covariance. No PRNG and no simulation logic lives in OCaml.
// The first row (k = 0) is the initial state and carries no measurement.
// Two panels:
//   (a) position tracking — noisy measurements, the true position, and the
//       filter estimate;
//   (b) the classic consistency plot — the estimation error stays inside the
//       +/- sigma confidence band, which shrinks as the covariance converges to
//       the DARE steady state (the same P_ss visualized in dare-convergence.typ).
//
// sigma_k = sqrt((P_k)_11) is emitted per step by the OCaml driver.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "wire.typ": load
#import "style.typ": viz-canvas, viz-resolve

#let raw = load("/paper/data/kalman_run.json")
#let kalman-data = (steps: raw.steps.enumerate().map(((k, s)) => {
  let base = (k: k, x_true: (s.x_true.at(0).at(0), s.x_true.at(1).at(0)),
    x_est: (s.x_est.at(0).at(0), s.x_est.at(1).at(0)), pos_sigma: calc.sqrt(s.P.at(0).at(0)))
  if s.meas != none { base + (meas: s.meas.at(0).at(0)) } else { base }
}))

#let axes-style = (
  stroke: (dash: "dotted", paint: gray),
  tick: (stroke: gray + 0.5pt),
)

// Both panels share the k-axis; stacking them vertically only lines the x-ticks
// up if the left margin (the y-tick-label column) has the same width in both.
// Render every y-tick label inside a fixed-width right-aligned box to force it.
#let kr-yfmt(st) = v => box(width: 2.6em, align(right, text(size: st.tick)[#v]))
#let kr-size = (13.5, 3.6) // plot area: fills the text block, modest height

// Panel (a): measurements vs true vs estimate.
#let panel-track(data, st, size) = viz-canvas(st, cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: axes-style, legend: (orientation: ltr))
  let steps = data.steps
  let kmax = steps.last().k
  let true-pos = steps.map(s => (s.k, s.x_true.at(0)))
  let est-pos = steps.map(s => (s.k, s.x_est.at(0)))
  let meas = steps.filter(s => "meas" in s).map(s => (s.k, s.meas))
  let ys = true-pos.map(p => p.at(1)) + meas.map(p => p.at(1))
  cetz-plot.plot.plot(
    name: "trk",
    size: size,
    x-label: text(size: st.label, $k$),
    y-label: box(width: 5.5em, align(center, text(size: st.label, $x_1$))),
    y-format: kr-yfmt(st),
    x-min: 0,
    x-max: kmax,
    y-min: calc.min(..ys) - 2,
    y-max: calc.max(..ys) + 2,
    x-tick-step: 10,
    y-tick-step: 3,
    x-grid: "both",
    y-grid: "both",
    axis-style: "school-book",
    legend: "south",
    legend-style: (
      stroke: none,
      fill: none,
      item: (spacing: 0.7),
    ),
    {
      cetz-plot.plot.add(
        meas,
        mark: "x",
        mark-size: 0.14,
        style: (stroke: none),
        label: text(size: st.legend)[измерения $y_k$],
      )
      cetz-plot.plot.add(true-pos, style: (stroke: blue + 1pt), label: text(
        size: st.legend,
      )[истинное $x_1$])
      cetz-plot.plot.add(
        est-pos,
        style: (stroke: red + 1pt),
        mark: "o",
        mark-size: 0.07,
        mark-style: (stroke: red, fill: red.lighten(55%)),
        label: text(size: st.legend)[оценка $hat(x)_1$],
      )
    },
  )
}))

// Panel (b): estimation error with the +/- sigma confidence band.
#let panel-error(data, st, size) = viz-canvas(st, cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: axes-style, legend: (orientation: ltr))
  let steps = data.steps
  let kmax = steps.last().k
  let err = steps.map(s => (s.k, s.x_est.at(0) - s.x_true.at(0)))
  let up = steps.map(s => (s.k, 2 * s.pos_sigma))
  let lo = steps.map(s => (s.k, -2 * s.pos_sigma))
  let smax = calc.max(..steps.map(s => s.pos_sigma))
  // school-book axes ignore per-axis auto-tick-count; set y-tick-step explicitly.
  let y-tick-step = calc.ceil(4.8 * smax / 5)
  cetz-plot.plot.plot(
    name: "err",
    size: size,
    x-label: text(size: st.label, $k$),
    y-label: box(width: 5.5em, align(center, text(
      size: st.label,
      $hat(x)_1 - x_1$,
    ))),
    y-format: kr-yfmt(st),
    x-min: 0,
    x-max: kmax,
    y-min: -2.4 * smax,
    y-max: 2.4 * smax,
    x-tick-step: 10,
    y-tick-step: y-tick-step,
    y-minor-tick-step: none,
    x-grid: "both",
    y-grid: "major",
    axis-style: "school-book",
    legend: "south",
    legend-style: (stroke: none, fill: none, item: (spacing: 0.7)),
    {
      cetz-plot.plot.add-fill-between(
        up,
        lo,
        style: (fill: luma(88%), stroke: none),
        label: text(size: st.legend)[$plus.minus 2 sigma_k$],
      )
      cetz-plot.plot.add(((0, 0), (kmax, 0)), style: (
        stroke: (paint: gray, dash: "dotted"),
      ))
      cetz-plot.plot.add(
        err,
        style: (stroke: red + 1pt),
        mark: "o",
        mark-size: 0.07,
        label: text(size: st.legend)[ошибка],
      )
    },
  )
}))

// In the thesis the panels are stacked vertically (`dir: ttb`, the default)
// on a shared, aligned k-axis (see kr-yfmt / kr-size), each enlarged to fill
// the text block. On slides `dir: ltr` puts them side by side. `size` is the
// cetz plot area of one panel.
#let kalman-run-figure(
  data: kalman-data,
  style: (:),
  size: kr-size,
  dir: ttb,
) = {
  let st = viz-resolve(style)
  let panel-a = stack(
    spacing: 0.6em,
    panel-track(data, st, size),
    align(center, text(size: st.subcaption)[(а) слежение за положением]),
  )
  let panel-b = stack(
    spacing: 0.6em,
    panel-error(data, st, size),
    align(center, text(size: st.subcaption)[(б) ошибка оценки в коридоре
      $plus.minus 2 sigma_k$]),
  )
  if dir == ltr {
    grid(
      columns: (auto, auto),
      column-gutter: 0em,
      align: bottom,
      panel-a, panel-b,
    )
  } else {
    stack(spacing: 1.1em, panel-a, panel-b)
  }
}
