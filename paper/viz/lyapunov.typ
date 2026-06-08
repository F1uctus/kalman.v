
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "plotdata.typ": load, points, lyapunov-path

#let lyap-data = load(lyapunov-path)

#let panel-convergence(data) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (paint: gray, thickness: 0.5pt),
    tick: (stroke: gray + 0.5pt),
  ))
  let pts = points(data.iterations, "N", "log10_frob_dist")
  cetz-plot.plot.plot(
    name: "conv",
    size: (8.5, 5),
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
    axis-style: "scientific",
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
  spacing: 0.9em,
  panel-convergence(data),
  align(center, lyap-note(data)),
)
