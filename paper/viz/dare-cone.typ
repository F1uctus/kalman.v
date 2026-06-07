
#import "@preview/cetz:0.5.2"
#import "proj3.typ": proj, default-view
#import "plotdata.typ": load, dare-convergence-path

#let dare-cone-data = load(dare-convergence-path)

#let cone-dir(th) = (
  calc.cos(th) * calc.cos(th),
  calc.cos(th) * calc.sin(th),
  calc.sin(th) * calc.sin(th),
)

#let mat-to-xyz(P) = (P.at(0).at(0), P.at(0).at(1), P.at(1).at(1))

#let dare-cone-figure(data: dare-cone-data, s: 0.95) = cetz.canvas(length: 1cm, {
  let view = default-view
  let P = p => proj(p, view: view)
  let O = P((0, 0, 0))

  let nrim = 60
  let rim = range(nrim + 1).map(i => P(cone-dir(i / nrim * calc.pi).map(x => x * s)))
  cetz.draw.line(..rim, stroke: gray.lighten(15%) + 0.5pt, close: true)
  for i in range(13) {
    cetz.draw.line(
      O,
      P(cone-dir(i / 12 * calc.pi).map(x => x * s)),
      stroke: gray.lighten(45%) + 0.4pt,
    )
  }

  let aL = s * 1.12
  let bL = s * 0.62
  cetz.draw.line(O, P((aL, 0, 0)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(P((aL, 0, 0)), text(size: 9pt)[$P_(1 1)$], anchor: "west", padding: 0.12)
  cetz.draw.line(O, P((0, 0, aL)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(P((0, 0, aL)), text(size: 9pt)[$P_(2 2)$], anchor: "east", padding: 0.12)
  cetz.draw.line(O, P((0, bL, 0)), mark: (end: ">"), stroke: black + 0.6pt)
  cetz.draw.content(P((0, bL, 0)), text(size: 9pt)[$P_(1 2)$], anchor: "south", padding: 0.12)

  let xyz = data.iterations.map(it => mat-to-xyz(it.P))
  let pts = xyz.map(P)
  let n = pts.len()

  cetz.draw.line(
    ..xyz.map(q => P((q.at(0), 0, q.at(2)))),
    stroke: (paint: gray, dash: "dotted", thickness: 0.5pt),
  )
  for i in range(n - 1) {
    let frac = i / (n - 1)
    cetz.draw.line(pts.at(i), pts.at(i + 1), stroke: luma((1 - frac) * 55%) + 1.1pt)
  }
  for (i, p) in pts.enumerate() {
    let frac = i / (n - 1)
    cetz.draw.circle(p, radius: 0.045, fill: luma((1 - frac) * 55%), stroke: none)
  }

  let q = mat-to-xyz(data.Pss)
  let qp = P(q)
  cetz.draw.line(qp, P((q.at(0), 0, q.at(2))), stroke: (paint: red.lighten(30%), dash: "dashed", thickness: 0.5pt))
  cetz.draw.circle(qp, radius: 0.09, fill: red, stroke: none)
  cetz.draw.content(qp, text(size: 9pt, fill: red)[$P_(s s)$], anchor: "west", padding: 0.16)

  cetz.draw.content(O, text(size: 8.5pt)[$P_0 = 0$], anchor: "north-east", padding: 0.18)
})
