
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "frames.typ": frame-strip
#import "plotdata.typ": load, dare-convergence-path

#let epsn-data = load(dare-convergence-path)

#let epsn-exponents = (-2, -4, -6)

#let epsn-ymin = -26
#let epsn-ymax = 1

#let n-eps(rows, e) = {
  let last-bad = -1
  for (i, r) in rows.enumerate() {
    if 2 * r.log10_frob_dist >= e { last-bad = i }
  }
  if last-bad + 1 < rows.len() { rows.at(last-bad + 1) } else { none }
}

#let epsn-frame(data, e) = {
  let rows = data.iterations
  let pts = rows.map(it => (it.k, 2 * it.log10_frob_dist))
  let kmax = calc.max(..rows.map(it => it.k))
  let cross = n-eps(rows, e)
  cetz.canvas(length: 1cm, {
    cetz.draw.set-style(axes: (
      stroke: (dash: "dotted", paint: gray),
      tick: (stroke: gray + 0.5pt),
    ))
    cetz-plot.plot.plot(
      name: "p",
      size: (4, 3.4),
      x-label: $k$,
      y-label: $norm(P_k - P_(s s))_F^2$,
      x-min: 0,
      x-max: kmax + 1,
      y-min: epsn-ymin,
      y-max: epsn-ymax,
      x-tick-step: 10,
      y-tick-step: 8,
      y-format: v => {
        let ee = int(calc.round(v))
        [#text(size: 7pt)[$10^(#ee)$]]
      },
      x-grid: "both",
      y-grid: "both",
      axis-style: "school-book",
      {
        cetz-plot.plot.add(
          pts,
          style: (stroke: black + 0.9pt),
          mark: "o",
          mark-size: 0.06,
          mark-style: (stroke: black + 0.5pt, fill: white),
        )
        cetz-plot.plot.annotate(resize: false, {
          cetz.draw.line(
            (0, e),
            (kmax + 1, e),
            stroke: (paint: red, dash: "dashed", thickness: 1pt),
          )
          cetz.draw.content(
            (kmax * 0.9, e),
            anchor: "center",
            box(fill: white, inset: (x: 1.5pt), text(size: 8.5pt, fill: red)[$epsilon$]),
          )
          if cross != none {
            let nk = cross.k
            let nv = 2 * cross.log10_frob_dist
            cetz.draw.line(
              (nk, epsn-ymin),
              (nk, nv),
              stroke: (paint: blue, dash: "dashed", thickness: 1pt),
            )
            cetz.draw.circle(
              (nk, nv),
              radius: 0.09,
              stroke: none,
              fill: blue,
            )
            cetz.draw.content(
              (nk, epsn-ymin),
              anchor: "north",
              padding: 0.1,
              text(size: 8pt, fill: blue)[$N(epsilon)$],
            )
          }
        })
      },
    )
  })
}

#let epsn-sublabel(data, e) = {
  let cross = n-eps(data.iterations, e)
  let nstr = if cross != none { str(cross.k) } else { $-$ }
  text(size: 9pt)[$epsilon = 10^(#e)$, #h(0.3em) $N(epsilon) = #nstr$]
}

#let dare-epsn-figure(data: epsn-data) = frame-strip(
  epsn-exponents,
  e => epsn-frame(data, e),
  sublabel: e => epsn-sublabel(data, e),
  gutter: 1.2em,
)
