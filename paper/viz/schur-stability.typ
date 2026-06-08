
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "plotdata.typ": load

#let schur-data = load("/paper/data/schur_stability.json")

#let circle-curve(r) = t => (r * calc.cos(t), r * calc.sin(t))

#let panel-eigs(data) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (dash: "dotted", paint: gray),
    tick: (stroke: gray + 0.5pt),
  ))
  let eigs = data.eigenvalues.map(e => (e.re, e.im))
  let sr = data.spectral_radius
  cetz-plot.plot.plot(
    name: "eig",
    size: (5.5, 5.5),
    x-min: -1.2,
    x-max: 1.2,
    y-min: -1.2,
    y-max: 1.2,
    x-label: $Re$,
    y-label: $Im$,
    x-tick-step: 0.5,
    y-tick-step: 0.5,
    x-grid: "both",
    y-grid: "both",
    axis-style: "school-book",
    legend: "south",
    legend-style: (stroke: none, fill: none, item: (spacing: 0.3)),
    {
      cetz-plot.plot.add(
        domain: (-3.15, 3.15),
        samples: 200,
        circle-curve(1),
        style: (stroke: gray + 0.8pt),
        label: [единичная окружность],
      )
      cetz-plot.plot.add(
        domain: (-3.15, 3.15),
        samples: 200,
        circle-curve(sr),
        style: (stroke: (paint: red, dash: "dashed", thickness: 0.8pt)),
        label: [$rho = #calc.round(sr, digits: 3)$],
      )
      cetz-plot.plot.add(
        eigs,
        mark: "o",
        mark-size: 0.16,
        style: (stroke: none),
        mark-style: (stroke: blue, fill: blue.lighten(40%)),
        label: [спектр $A_(c l)$],
      )
    },
  )
})

#let panel-decay(data) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (paint: gray, thickness: 0.5pt),
    tick: (stroke: gray + 0.5pt),
  ))
  let pts = data.power_norms.map(r => (
    r.k,
    if r.frob > 0 { calc.log(r.frob, base: 10) } else { -16 },
  ))
  let kmax = data.power_norms.last().k
  let sr = data.spectral_radius
  let rho-line = ((0, 0), (kmax, kmax * calc.log(sr, base: 10)))
  cetz-plot.plot.plot(
    name: "decay",
    size: (5.5, 5.5),
    x-label: $k$,
    y-label: $norm(A_(c l)^k)_F$,
    x-min: 0,
    x-max: kmax,
    y-min: -5.5,
    y-max: 1,
    x-tick-step: 5,
    y-tick-step: 1,
    y-format: v => {
      let e = int(calc.round(v))
      [#text(size: 8pt)[$10^(#e)$]]
    },
    x-grid: "both",
    y-grid: "both",
    axis-style: "scientific",
    legend: "inner-north-east",
    legend-style: (stroke: none, fill: white, padding: 0.2, item: (spacing: 0.3)),
    {
      cetz-plot.plot.add(
        rho-line,
        style: (stroke: (paint: red, dash: "dashed", thickness: 0.8pt)),
        label: [$rho^k$],
      )
      cetz-plot.plot.add(pts, style: (stroke: black + 1pt), mark: "o", mark-size: 0.1)
    },
  )
})

#let schur-stability-figure(data: schur-data) = grid(
  columns: (auto, auto),
  gutter: 1.5em,
  align: bottom,
  stack(
    spacing: 0.6em,
    panel-eigs(data),
    align(center, text(size: 9pt)[(а) спектр $A_(c l)$ внутри единичной окружности]),
  ),
  stack(
    spacing: 0.6em,
    panel-decay(data),
    align(center, text(size: 9pt)[(б) геометрическая сходимость
      $norm(A_(c l)^k)_F -> 0$]),
  ),
)
