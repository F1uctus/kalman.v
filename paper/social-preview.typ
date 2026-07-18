// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// paper/social-preview.typ — GitHub social media preview (1280×640).
//
// Display face: Inter (Google Fonts / rsms/inter, OFL) — UI sans for headlines.

#import "@preview/cetz:0.5.2"
#import "common/fonts.typ": tnr-font
#import "viz/observer-block.typ": observer-block-canvas
#import "viz/social-preview-ellipses.typ": social-ellipse-panel
#import "viz/social-preview-plot.typ": social-panel-track
#import "viz/style.typ": viz-resolve

#set page(width: 1280pt, height: 640pt, margin: 0pt)
#set text(font: tnr-font, fill: white)

#let display-font = "Inter"
#let bg-deep = rgb("#082558")
#let bg-mid = rgb("#164f9c")
#let accent-cyan = rgb("#5ed4ff")
#let accent-mint = rgb("#6de8b0")
#let accent-coral = rgb("#ffb07a")
#let rocq-orange = rgb("#ff540a")
#let panel-h = 400pt
#let panel-inset = 12pt

#let preview-viz = viz-resolve((
  label: 18pt,
  tick: 13pt,
  legend: 14pt,
))

#let dark-observer-theme = (
  wire: white.transparentize(8%),
  box: white.transparentize(45%),
  mark-fill: white,
  tap-fill: white,
  label-fill: white,
  show-region-labels: false,
)

#let panel-inner-h = panel-h - 2 * panel-inset

#let panel-col-w = 560pt

#let fig-panel(body, factor: 150%) = box(
  width: 100%,
  height: panel-h,
  inset: panel-inset,
  box(
    width: 100%,
    height: panel-inner-h,
    align(center + horizon, scale(reflow: true, factor, body)),
  ),
)

#let bridge-arrow = cetz.canvas(length: 1cm, {
  import cetz.draw: line
  let mk = (end: ">", scale: 0.85, fill: accent-cyan)
  line((0, 0.2), (2.6, 0.2), stroke: accent-cyan + 2.8pt, mark: mk)
  line(
    (0, -0.2),
    (2.6, -0.2),
    stroke: (paint: accent-cyan.lighten(15%), dash: "dashed", thickness: 1.6pt),
    mark: mk,
  )
})

#let qed-badge = box(
  fill: rocq-orange,
  radius: 5pt,
  inset: (x: 14pt, y: 7pt),
  text(font: display-font, weight: "bold", size: 15pt, fill: white)[Qed.],
)

#let rocq-logo = grid(
  columns: (auto, auto),
  column-gutter: 10pt,
  align: horizon,
  image("/paper/images/icon-rocq-orange.svg", height: 42pt),
  text(font: display-font, size: 30pt, fill: rocq-orange, weight: "bold")[Rocq],
)

#let observer-body = observer-block-canvas(
  preview-viz,
  theme: dark-observer-theme,
)

#let plot-body = social-panel-track(
  style: preview-viz,
  size: (11.5, 5.0),
  stride: 2,
  theme: (
    grid: white.transparentize(68%),
    true-color: accent-mint,
    est-color: accent-coral,
    meas-color: white,
  ),
)

#let bg-grid = cetz.canvas(length: 1cm, {
  import cetz.draw: line
  let grid-stroke = white.transparentize(95%) + 0.45pt
  for x in range(14) {
    line((x, 0), (x, 6.4), stroke: grid-stroke)
  }
  for y in range(8) {
    line((0, y), (12.8, y), stroke: grid-stroke)
  }
})

#page[
  #place(dx: 0pt, dy: 0pt, rect(
    width: 100%,
    height: 100%,
    fill: gradient.linear(bg-deep, bg-mid, angle: 35deg),
  ))
  #place(dx: 0pt, dy: 0pt, layout(size => {
    let m = measure(bg-grid)
    let f = calc.max(size.width / m.width, size.height / m.height)
    scale(reflow: true, f * 100%, bg-grid)
  }))

  #pad(x: 28pt, y: 20pt)[
    #grid(
      rows: (auto, auto, auto),
      row-gutter: 35pt,
      {
        grid(
          columns: (1fr, auto),
          align: bottom,
          stack(
            spacing: 2pt,
            text(font: display-font, size: 46pt, weight: "bold", fill: white)[
              KALMAN FILTER
            ],
          ),
          rocq-logo,
        )
      },
      {
        grid(
          columns: (panel-col-w, auto, panel-col-w),
          column-gutter: 6pt,
          fig-panel(observer-body, factor: 120%),
          box(
            width: 100%,
            height: panel-h,
            align(center + horizon, [
              #stack(
                spacing: 12pt,
                bridge-arrow,
                qed-badge,
              )
            ]),
          ),
          fig-panel(plot-body),
        )
      },
      {
        social-ellipse-panel(
          n: 7,
          steady-stroke: accent-mint,
          steady-fill: accent-mint,
        )
      },
    )
  ]
]
