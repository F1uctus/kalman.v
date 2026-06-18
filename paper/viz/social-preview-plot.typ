// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/social-preview-plot.typ — sparse Kalman tracking panel for the GitHub
// social preview banner.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "plotdata.typ": load
#import "style.typ": viz-canvas, viz-resolve

#let kalman-data = load("/paper/data/kalman_run.json")

// Keep every `stride`-th step (always retain the last one).
#let subsample-steps(steps, stride: 2) = {
  let last-k = steps.last().k
  steps.filter(s => calc.rem(s.k, stride) == 0 or s.k == last-k)
}

#let social-panel-track(
  data: kalman-data,
  style: (:),
  size: (12.0, 4.8),
  theme: (:),
  stride: 2,
) = {
  let st = viz-resolve(style)
  let grid-paint = theme.at("grid", default: white.transparentize(78%))
  let true-color = theme.at("true-color", default: rgb("#8cf0b8"))
  let est-color = theme.at("est-color", default: rgb("#ffb380"))
  let meas-color = theme.at("meas-color", default: white.lighten(10%))

  let axes-style = (
    stroke: (paint: grid-paint, thickness: 0.45pt),
    tick: (stroke: none),
  )

  viz-canvas(st, cetz.canvas(length: 1cm, {
    cetz.draw.set-style(axes: axes-style)
    let steps = subsample-steps(data.steps, stride: stride)
    let kmax = data.steps.last().k
    let true-pos = steps.map(s => (s.k, s.x_true.at(0)))
    let est-pos = steps.map(s => (s.k, s.x_est.at(0)))
    let meas = steps.filter(s => "meas" in s).map(s => (s.k, s.meas))
    let ys = true-pos.map(p => p.at(1)) + meas.map(p => p.at(1))
    cetz-plot.plot.plot(
      name: "sp-trk",
      size: size,
      x-label: none,
      y-label: none,
      x-min: 0,
      x-max: kmax,
      y-min: calc.min(..ys) - 2,
      y-max: calc.max(..ys) + 2,
      x-tick-step: none,
      y-tick-step: none,
      x-grid: "both",
      y-grid: "both",
      axis-style: "scientific",
      {
        cetz-plot.plot.add(
          meas,
          mark: "x",
          mark-size: 0.28,
          mark-style: (stroke: meas-color, fill: meas-color),
          style: (stroke: none),
        )
        cetz-plot.plot.add(
          true-pos,
          style: (stroke: true-color + 2.4pt),
        )
        cetz-plot.plot.add(
          est-pos,
          style: (stroke: est-color + 2.4pt),
          mark: "o",
          mark-size: 0.14,
          mark-style: (stroke: est-color, fill: est-color.lighten(25%)),
        )
      },
    )
  }))
}
