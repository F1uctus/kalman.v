
#import "@preview/cetz:0.5.2"
#import "proj3.typ": proj
#import "plotdata.typ": load, orthogonality-path

#let orthogonality-data = load(orthogonality-path)

#let ortho-view = (
  ex: (1.00, -0.30), // image of the x unit axis — right, receding
  ey: (0.46, 0.30),  // image of the y unit axis — into the floor
  ez: (0.00, 1.00),  // image of the z unit axis — straight up (perpendicular)
  scale: 1.55,       // cm per unit value
)

#let orthogonality-figure(data: orthogonality-data) = cetz.canvas(length: 2cm, {
  import cetz.draw: line, circle, content

  let tr-opt = data.trace_opt // Tr(P⁺), optimal posterior
  let tr-alt = data.alternatives.at(0).trace // K' = 0 ⇒ Tr(P⁻)

  let unit = 1.55
  let h = calc.sqrt(calc.max(0, tr-opt)) * unit // perpendicular = √Tr(P⁺)
  let base = calc.sqrt(calc.max(0, tr-alt - tr-opt)) * unit // in-plane base

  let ph = (0.82, 0.57) // in-plane direction of the projection x̂
  let P = p => proj(p, view: ortho-view)

  let O = (0, 0, 0)
  let X = base * ph.at(0)
  let Y = base * ph.at(1)
  let xhat = (X, Y, 0) // optimal estimate x̂⁺ = projection onto Y
  let xtrue = (X, Y, h) // true state x, lifted off the plane

  let m = 0.55
  let floor = (
    (-m, -m, 0),
    (X + m, -m * 0.6, 0),
    (X + m, Y + m, 0),
    (-m, Y + m, 0),
  ).map(P)
  line(..floor, close: true, fill: luma(94%), stroke: luma(70%) + 0.5pt)
  content(
    P((-m, 0.35, 0)),
    text(size: 8.5pt)[$cal(Y) = "span" {y_k}$],
    anchor: "east",
    padding: 0.12,
  )

  line(P(O), P(xtrue), stroke: rgb(200, 70, 40) + 1.1pt)
  content(
    P((0.5 * xtrue.at(0), 0.5 * xtrue.at(1), 0.5 * xtrue.at(2))),
    text(size: 8pt, fill: rgb(170, 55, 30))[$"Tr" P_(k|k-1) = #calc.round(tr-alt, digits: 2)$],
    anchor: "south-east",
    padding: 0.14,
  )

  line(P(O), P(xhat), stroke: (paint: luma(55%), dash: "dashed", thickness: 0.7pt))

  line(P(xhat), P(xtrue), stroke: black + 1.3pt)
  content(
    P(((xhat.at(0) + xtrue.at(0)) / 2, (xhat.at(1) + xtrue.at(1)) / 2, (xhat.at(2) + xtrue.at(2)) / 2)),
    text(size: 8pt)[$"Tr" P_(k|k) = #calc.round(tr-opt, digits: 2)$],
    anchor: "west",
    padding: 0.14,
  )

  let d = 0.16
  let ra = (
    xhat,
    (xhat.at(0) - d * ph.at(0), xhat.at(1) - d * ph.at(1), 0),
    (xhat.at(0) - d * ph.at(0), xhat.at(1) - d * ph.at(1), d),
    (xhat.at(0), xhat.at(1), d),
  ).map(P)
  line(..ra, stroke: luma(30%) + 0.5pt)

  circle(P(O), radius: 0.05, fill: luma(45%), stroke: none)
  content(P(O), text(size: 8pt, fill: luma(30%))[$hat(x)' = 0$], anchor: "north", padding: 0.16)
  circle(P(xhat), radius: 0.06, fill: black, stroke: none)
  content(P(xhat), text(size: 8.5pt)[$hat(x) = K y$], anchor: "north", padding: 0.18)
  circle(P(xtrue), radius: 0.06, fill: black, stroke: none)
  content(P(xtrue), text(size: 8.5pt)[$x$], anchor: "south", padding: 0.14)
})
