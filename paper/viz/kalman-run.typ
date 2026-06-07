
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "plotdata.typ": load

#let kalman-data = load("/paper/data/kalman_run.json")

#let axes-style = (
  stroke: (dash: "dotted", paint: gray),
  tick: (stroke: gray + 0.5pt),
)

#let panel-track(data) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: axes-style)
  let steps = data.steps
  let kmax = steps.last().k
  let true-pos = steps.map(s => (s.k, s.x_true.at(0)))
  let est-pos = steps.map(s => (s.k, s.x_est.at(0)))
  let meas = steps.map(s => (s.k, s.meas))
  let ys = true-pos.map(p => p.at(1)) + meas.map(p => p.at(1))
  cetz-plot.plot.plot(
    name: "trk",
    size: (7, 5),
    x-label: $k$,
    y-label: $x_1$,
    x-min: 0,
    x-max: kmax,
    y-min: calc.min(..ys) - 2,
    y-max: calc.max(..ys) + 2,
    x-tick-step: 10,
    x-grid: "both",
    y-grid: "both",
    axis-style: "school-book",
    legend: "south",
    legend-style: (stroke: none, fill: none, item: (spacing: 0.3)),
    {
      cetz-plot.plot.add(
        meas,
        mark: "x",
        mark-size: 0.14,
        style: (stroke: none),
        label: [измерения $y_k$],
      )
      cetz-plot.plot.add(true-pos, style: (stroke: blue + 1pt), label: [истинное $x_1$])
      cetz-plot.plot.add(
        est-pos,
        style: (stroke: red + 1pt),
        mark: "o",
        mark-size: 0.07,
        mark-style: (stroke: red, fill: red.lighten(55%)),
        label: [оценка $hat(x)_1$],
      )
    },
  )
})

#let panel-error(data) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: axes-style)
  let steps = data.steps
  let kmax = steps.last().k
  let err = steps.map(s => (s.k, s.x_est.at(0) - s.x_true.at(0)))
  let up = steps.map(s => (s.k, 2 * s.pos_sigma))
  let lo = steps.map(s => (s.k, -2 * s.pos_sigma))
  let smax = calc.max(..steps.map(s => s.pos_sigma))
  let y-tick-step = calc.ceil(4.8 * smax / 5)
  cetz-plot.plot.plot(
    name: "err",
    size: (7, 5),
    x-label: $k$,
    y-label: $hat(x)_1 - x_1$,
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
    legend-style: (stroke: none, fill: none, item: (spacing: 0.3)),
    {
      cetz-plot.plot.add-fill-between(
        up,
        lo,
        style: (fill: luma(88%), stroke: none),
        label: [$plus.minus 2 sigma_k$],
      )
      cetz-plot.plot.add(((0, 0), (kmax, 0)), style: (stroke: (paint: gray, dash: "dotted")))
      cetz-plot.plot.add(
        err,
        style: (stroke: red + 1pt),
        mark: "o",
        mark-size: 0.07,
        label: [ошибка],
      )
    },
  )
})

#let kalman-run-figure(data: kalman-data) = grid(
  columns: (auto, auto),
  gutter: 1.5em,
  align: bottom,
  stack(
    spacing: 0.6em,
    panel-track(data),
    align(center, text(size: 9pt)[(а) слежение за положением]),
  ),
  stack(
    spacing: 0.6em,
    panel-error(data),
    align(center, text(size: 9pt)[(б) ошибка оценки в коридоре $plus.minus 2 sigma_k$]),
  ),
)
