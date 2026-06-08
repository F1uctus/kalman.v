
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "ellipse.typ": add-ellipse
#import "plotdata.typ": dare-convergence-path, load, points

#let dare-data = load(dare-convergence-path)

#let lsq-line(xs, ys) = {
  let n = xs.len()
  let sx = xs.sum()
  let sy = ys.sum()
  let sxx = xs.zip(xs).map(((a, b)) => a * b).sum()
  let sxy = xs.zip(ys).map(((a, b)) => a * b).sum()
  let a = (n * sxy - sx * sy) / (n * sxx - sx * sx)
  (a, (sy - a * sx) / n)
}

#let panel-convergence(data) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (paint: gray, thickness: 0.5pt),
    tick: (stroke: gray + 0.5pt),
  ))
  let pts = points(data.iterations, "k", "log10_frob_dist")
  let kmax = calc.max(..data.iterations.map(it => it.k))
  let lin = data.iterations.filter(it => it.k >= 4)
  let (a, b) = lsq-line(lin.map(it => it.k), lin.map(it => it.log10_frob_dist))
  let fit-line = ((0, b), (kmax, a * kmax + b))
  cetz-plot.plot.plot(
    name: "conv",
    size: (6, 5),
    x-label: $k$,
    y-label: $norm(P_k - P_(s s))_F$,
    x-min: 0,
    x-max: kmax + 1,
    y-min: -13,
    y-max: 1,
    x-tick-step: 5,
    y-tick-step: 3,
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
        fit-line,
        style: (stroke: (paint: red, dash: "dashed", thickness: 0.8pt)),
        label: [$rho(A_(c l))^2$],
      )
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
  let shown = data
    .iterations
    .filter(it => it.ellipse.a > 1e-6)
    .slice(0, max-shown)
  let n = calc.max(shown.len(), 2)
  cetz-plot.plot.plot(
    name: "ell",
    size: (6, 6),
    x-min: -1,
    x-max: 1,
    y-min: -1,
    y-max: 1,
    x-label: $x_1$,
    y-label: $x_2$,
    x-tick-step: 0.5,
    y-tick-step: 0.5,
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
      let ess = data.Pss_ellipse
      add-ellipse(
        radii: (ess.a, ess.b),
        rotation: ess.angle_rad * 1rad,
        stroke: red + 1.3pt,
        show-radii: true,
      )
    },
  )
})

#let dare-convergence-figure(data: dare-data) = grid(
  columns: (auto, auto),
  gutter: 1.5em,
  align: bottom,
  stack(
    spacing: 0.6em,
    panel-convergence(data),
    align(center, text(size: 9pt)[(а) геометрическая сходимость по норме
      Фробениуса]),
  ),
  stack(
    spacing: 0.6em,
    panel-ellipses(data),
    align(center, text(size: 9pt)[(б) эллипсы ковариации $P_k -> P_(s s)$]),
  ),
)
