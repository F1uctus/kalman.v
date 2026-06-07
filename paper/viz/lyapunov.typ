
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "ellipse.typ": add-ellipse
#import "plotdata.typ": load, points, lyapunov-path

#let lyap-data = load(lyapunov-path)

#let panel-convergence(data) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (dash: "dotted", paint: gray),
    tick: (stroke: gray + 0.5pt),
  ))
  let pts = points(data.iterations, "N", "log10_frob_dist")
  cetz-plot.plot.plot(
    name: "conv",
    size: (6, 5),
    x-label: $N$,
    y-label: $norm(P_N - X_oo)_F$,
    x-min: 0,
    x-max: calc.max(..data.iterations.map(it => it.N)) + 1,
    y-min: -7,
    y-max: 1,
    x-tick-step: 6,
    y-tick-step: 2,
    y-format: v => {
      let e = int(calc.round(v))
      [#text(size: 8pt)[$10^(#e)$]]
    },
    x-grid: "both",
    y-grid: "both",
    axis-style: "school-book",
    {
      cetz-plot.plot.add(
        pts,
        style: (stroke: black + 1pt),
        mark: "o",
        mark-size: 0.12,
      )
    },
  )
})

#let panel-ellipses(data, max-shown: 12) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (dash: "dotted", paint: gray),
    tick: (stroke: gray + 0.5pt),
  ))
  let shown = data.iterations.filter(it => it.ellipse.a > 1e-6).slice(0, max-shown)
  let n = calc.max(shown.len(), 2)
  cetz-plot.plot.plot(
    name: "ell",
    size: (6, 6),
    x-min: -2.2,
    x-max: 2.2,
    y-min: -2.2,
    y-max: 2.2,
    x-label: $x_1$,
    y-label: $x_2$,
    x-tick-step: 1,
    y-tick-step: 1,
    x-grid: "both",
    y-grid: "both",
    axis-style: "school-book",
    {
      for (i, it) in shown.enumerate() {
        let frac = i / (n - 1)
        let e = it.ellipse
        add-ellipse(
          radii: (e.a, e.b),
          rotation: e.angle_rad * 1rad,
          stroke: luma((1 - frac) * 70%) + 0.8pt,
        )
      }
      let ess = data.lyap_sol_ellipse
      add-ellipse(
        radii: (ess.a, ess.b),
        rotation: ess.angle_rad * 1rad,
        stroke: red + 1.3pt,
        show-radii: true,
      )
    },
  )
})

#let lyap-note(data) = {
  let s = data.lyap_sol
  let tr-lim = s.at(0).at(0) + s.at(1).at(1)
  let last = data.iterations.last()
  let le = calc.round(last.log10_frob_dist, digits: 1)
  text(size: 9pt)[
    $"tr" X_oo approx #calc.round(tr-lim, digits: 2)$, #h(0.4em)
    $norm(P_#last.N - X_oo)_F approx 10^(#le)$
  ]
}

#let lyapunov-figure(data: lyap-data) = stack(
  spacing: 0.7em,
  grid(
    columns: (auto, auto),
    gutter: 1.5em,
    align: bottom,
    stack(
      spacing: 0.6em,
      panel-convergence(data),
      align(center, text(size: 9pt)[(а) геометрическая сходимость по норме Фробениуса]),
    ),
    stack(
      spacing: 0.6em,
      panel-ellipses(data),
      align(center, text(size: 9pt)[(б) эллипсы ковариации $P_N -> X_oo$]),
    ),
  ),
  align(center, lyap-note(data)),
)
