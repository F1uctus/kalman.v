
#import "@preview/cetz:0.5.2"
#import "proj3.typ": default-view, proj
#import "plotdata.typ": dare-convergence-path, load

#let dare-cone-data = load(dare-convergence-path)

#let cone-dir(th) = (
  calc.cos(th) * calc.cos(th),
  calc.cos(th) * calc.sin(th),
  calc.sin(th) * calc.sin(th),
)

#let mat-to-xyz(P) = (P.at(0).at(0), P.at(0).at(1), P.at(1).at(1))
#let trace-of(P) = P.at(0).at(0) + P.at(1).at(1)

#let traj-color(frac) = luma((1 - frac) * 55%)

#let cone-3d(data, s: 0.95) = cetz.canvas(length: 1cm, {
  let view = default-view
  let P = p => proj(p, view: view)
  let O = P((0, 0, 0))

  let nrim = 60
  let rim = range(nrim + 1).map(i => P(
    cone-dir(i / nrim * calc.pi).map(x => x * s),
  ))
  cetz.draw.line(..rim, stroke: gray.lighten(15%) + 0.5pt, close: true)
  for i in range(13) {
    cetz.draw.line(
      O,
      P(cone-dir(i / 12 * calc.pi).map(x => x * s)),
      stroke: gray.lighten(50%) + 0.4pt,
    )
  }

  let aL = s * 1.18
  let dL = s * 0.78
  cetz.draw.line(O, P((aL, 0, 0)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(
    P((aL, 0, 0)),
    text(size: 9pt)[$P_(1 1)$],
    anchor: "west",
    padding: 0.12,
  )
  cetz.draw.line(O, P((0, 0, aL)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(
    P((0, 0, aL)),
    text(size: 9pt)[$P_(2 2)$],
    anchor: "east",
    padding: 0.12,
  )
  cetz.draw.line(O, P((0, dL, 0)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(
    P((0, dL, 0)),
    text(size: 9pt)[$P_(1 2)$],
    anchor: "north-east",
    padding: 0.1,
  )

  let xyz = data.iterations.map(it => mat-to-xyz(it.P))
  let pts = xyz.map(P)
  let n = pts.len()

  let q = mat-to-xyz(data.Pss)
  cetz.draw.line(P(q), P((q.at(0), 0, q.at(2))), stroke: (
    paint: red.lighten(35%),
    dash: "dashed",
    thickness: 0.5pt,
  ))

  for i in range(n - 1) {
    cetz.draw.line(
      pts.at(i),
      pts.at(i + 1),
      stroke: traj-color(i / (n - 1)) + 1.1pt,
    )
  }
  for (i, p) in pts.enumerate() {
    cetz.draw.circle(p, radius: 0.045, fill: traj-color(i / (n - 1)), stroke: none)
  }

  cetz.draw.circle(P(q), radius: 0.09, fill: red, stroke: none)
  cetz.draw.content(
    P(q),
    text(size: 9pt, fill: red)[$P_(s s)$],
    anchor: "west",
    padding: 0.16,
  )

  cetz.draw.content(
    O,
    text(size: 8.5pt)[$P_0 = 0$],
    anchor: "north",
    padding: 0.2,
  )
})

#let cone-crosssection(data, s: 6.5) = cetz.canvas(length: 1cm, {
  let proj2 = P => (
    P.at(0).at(1) * s,
    (P.at(0).at(0) - P.at(1).at(1)) / 2 * s,
  )
  let r-ss = trace-of(data.Pss) / 2 * s

  for f in (0.4, 0.68) {
    cetz.draw.circle((0, 0), radius: r-ss * f, stroke: gray.lighten(55%) + 0.5pt)
  }
  cetz.draw.circle((0, 0), radius: r-ss, stroke: gray.lighten(5%) + 1pt)
  cetz.draw.content(
    (r-ss * calc.cos(35deg), r-ss * calc.sin(35deg)),
    text(size: 7.5pt, fill: gray.darken(20%))[ранг 1],
    anchor: "south-west",
    padding: 0.05,
  )

  let aL = r-ss * 1.4
  cetz.draw.line((-aL, 0), (aL, 0), mark: (end: ">"), stroke: black + 0.5pt)
  cetz.draw.content(
    (aL, 0),
    text(size: 9pt)[$P_(1 2)$],
    anchor: "west",
    padding: 0.1,
  )
  cetz.draw.line((0, -aL), (0, aL), mark: (end: ">"), stroke: black + 0.5pt)
  cetz.draw.content(
    (0, aL),
    text(size: 8pt)[$(P_(1 1) - P_(2 2)) \/ 2$],
    anchor: "south",
    padding: 0.1,
  )

  let pts = data.iterations.map(it => proj2(it.P))
  let n = pts.len()
  for i in range(n - 1) {
    cetz.draw.line(
      pts.at(i),
      pts.at(i + 1),
      stroke: traj-color(i / (n - 1)) + 1.1pt,
    )
  }
  for (i, p) in pts.enumerate() {
    cetz.draw.circle(p, radius: 0.05, fill: traj-color(i / (n - 1)), stroke: none)
  }

  let qp = proj2(data.Pss)
  cetz.draw.circle(qp, radius: 0.09, fill: red, stroke: none)
  cetz.draw.content(
    qp,
    text(size: 9pt, fill: red)[$P_(s s)$],
    anchor: "west",
    padding: 0.14,
  )
})

#let dare-cone-figure(data: dare-cone-data) = grid(
  columns: (auto, auto),
  column-gutter: 2em,
  align: horizon,
  stack(
    spacing: 0.6em,
    cone-3d(data),
    align(center, text(size: 9pt)[(а) конус и подъём траектории]),
  ),
  stack(
    spacing: 0.6em,
    cone-crosssection(data),
    align(center, text(size: 9pt)[(б) сечение поперёк оси следа]),
  ),
)
