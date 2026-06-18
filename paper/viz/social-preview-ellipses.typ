// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/social-preview-ellipses.typ — full-width semi-transparent Riccati strip.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "ellipse.typ": ellipse-curve
#import "plotdata.typ": dare-convergence-path, load
#import "style.typ": viz-canvas

#let dare-data = load(dare-convergence-path)

#let social-ellipse-items(data, n) = {
  let shown = data.iterations.filter(it => it.ellipse.a > 0.12 and it.ellipse.b > 0.06)
  if shown.len() <= n {
    shown
  } else {
    range(n).map(i => {
      let j = int(calc.round(i * (shown.len() - 1) / calc.max(n - 1, 1)))
      shown.at(j)
    })
  }
}

#let social-ellipse-cell(
  it,
  idx,
  last-idx,
  stroke-base,
  steady-stroke,
  fill-base,
  steady-fill,
) = {
  let frac = idx / calc.max(last-idx, 1)
  let e = it.ellipse
  let is-last = idx == last-idx
  let stroke = if is-last {
    steady-stroke.transparentize(15%) + 2pt
  } else {
    stroke-base.transparentize(35% + frac * 10%) + 1.6pt
  }
  let fill = if is-last {
    steady-fill.transparentize(62%)
  } else {
    fill-base.transparentize(78% - frac * 8%)
  }
  let cell-h = 5.2
  align(center + horizon, viz-canvas((tick: 8pt,), cetz.canvas(length: 1cm, {
    cetz-plot.plot.plot(
      name: "se-" + str(idx),
      size: (3.4, cell-h),
      x-min: -1,
      x-max: 1,
      y-min: -1,
      y-max: 1,
      x-tick-step: none,
      y-tick-step: none,
      x-label: none,
      y-label: none,
      x-grid: false,
      y-grid: false,
      axis-style: none,
      {
        cetz-plot.plot.add(
          domain: (-3.15, 3.15),
          samples: 200,
          ellipse-curve(radii: (e.a, e.b), rotation: e.angle_rad * 1rad),
          style: (stroke: stroke, fill: fill),
        )
      },
    )
  })))
}

#let social-ellipse-strip(
  data: dare-data,
  n: 7,
  stroke-base: white,
  steady-stroke: rgb("#6de8b0"),
  fill-base: white,
  steady-fill: rgb("#6de8b0"),
  arrow-size: 20pt,
) = {
  let items = social-ellipse-items(data, n)
  let last = calc.max(items.len() - 1, 0)
  let cells = ()
  for (i, it) in items.enumerate() {
    if i > 0 {
      cells.push(align(
        center + horizon,
        text(size: arrow-size, fill: stroke-base.transparentize(45%))[$->$],
      ))
    }
    cells.push(social-ellipse-cell(
      it,
      i,
      last,
      stroke-base,
      steady-stroke,
      fill-base,
      steady-fill,
    ))
  }
  grid(
    columns: range(cells.len()).map(i => if calc.rem(i, 2) == 1 { auto } else { 1fr }),
    column-gutter: 0.2em,
    align: bottom,
    ..cells,
  )
}

// Full-width strip for the banner footer (no caption, no per-frame labels).
#let social-ellipse-panel(data: dare-data, ..args) = social-ellipse-strip(
  data: data,
  ..args,
)
