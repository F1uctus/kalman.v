// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/orthogonality.typ — the orthogonality principle behind Kalman-gain
// optimality, as the classic projection diagram.
//
// In the Hilbert space of zero-mean random variables (inner product
// <X,Y> = E[X Y*]) the optimal estimate x̂ is the orthogonal projection of the
// state x onto the span Y of the measurements; the error e = x − x̂ is
// perpendicular to Y (the normal equation kalman.filter_gain_normal_eq,
// K S = P H†). Any other gain K' lands the estimate elsewhere, so its error is
// longer — for K' = 0 (ignore the measurement) the error is the whole drop from
// the prediction, with covariance trace Tr(P⁻) > Tr(P⁺). The right triangle is
// the square-completion identity behind kalman.filter_gain_optimal:
//   Tr(P⁻) = Tr(P⁺) + (in-plane offset)²  =  perpendicular² + base².
//
// Geometry is schematic, but its proportions and the two trace labels are the
// exact extracted numbers: the perpendicular height is √Tr(P⁺) and the in-plane
// base is √(Tr(P⁻) − Tr(P⁺)), so the slanted error is literally √Tr(P⁻).
//
// Data: paper/data/orthogonality.json (extracted seqmx programs; see driver.ml).

#import "@preview/cetz:0.5.2"
#import "proj3.typ": proj
#import "plotdata.typ": load, orthogonality-path
#import "style.typ": viz-canvas, viz-resolve

#let orthogonality-data = load(orthogonality-path)

// A floor (z = 0) seen from above-front, with the perpendicular pointing up.
#let ortho-view = (
  ex: (1.00, -0.30), // image of the x unit axis — right, receding
  ey: (0.46, 0.30), // image of the y unit axis — into the floor
  ez: (0.00, 1.00), // image of the z unit axis — straight up (perpendicular)
  scale: 1.55, // cm per unit value
)

#let orthogonality-figure(data: orthogonality-data, style: (:)) = {
  let st = viz-resolve(style)
  viz-canvas(st, cetz.canvas(length: 2cm, {
    import cetz.draw: circle, content, line

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

    // --- data plane Y = span of the measurements (faint floor quad) ---
    let m = 0.55
    let floor = (
      (-m, -m, 0),
      (X + m, -m * 0.6, 0),
      (X + m, Y + m, 0),
      (-m, Y + m, 0),
    ).map(P)
    line(..floor, close: true, fill: luma(94%), stroke: luma(70%) + 0.5pt)
    content(
      P((X / 2, -0.8 * m, 0)),
      text(size: st.label)[$cal(Y) = "span" {y_k}$],
      anchor: "north",
      padding: 0.16,
    )

    // --- sub-optimal error e' = x − x̂' for K' = 0 (ignore measurement) ---
    // x̂' sits at the origin (no correction), so e' is the full drop O → x.
    line(P(O), P(xtrue), stroke: rgb(200, 70, 40) + 1.1pt)
    content(
      P((0.5 * xtrue.at(0), 0.5 * xtrue.at(1), 0.5 * xtrue.at(2))),
      text(size: st.annot, fill: rgb(
        170,
        55,
        30,
      ))[$"Tr" P_(k|k-1) = #calc.round(tr-alt, digits: 2)$],
      anchor: "south-east",
      padding: 0.14,
    )

    // --- in-plane correction O → x̂ (the projection, dashed gray) ---
    line(P(O), P(xhat), stroke: (
      paint: luma(55%),
      dash: "dashed",
      thickness: 0.7pt,
    ))

    // --- optimal error e = x − x̂ (perpendicular to the plane) ---
    line(P(xhat), P(xtrue), stroke: black + 1.3pt)
    content(
      P((
        (xhat.at(0) + xtrue.at(0)) / 2,
        (xhat.at(1) + xtrue.at(1)) / 2,
        (xhat.at(2) + xtrue.at(2)) / 2,
      )),
      text(size: st.annot)[$"Tr" P_(k|k) = #calc.round(tr-opt, digits: 2)$],
      anchor: "west",
      padding: 0.14,
    )

    // --- right-angle marker at x̂ (e ⊥ plane: the normal equation) ---
    let d = 0.16
    let ra = (
      xhat,
      (xhat.at(0) - d * ph.at(0), xhat.at(1) - d * ph.at(1), 0),
      (xhat.at(0) - d * ph.at(0), xhat.at(1) - d * ph.at(1), d),
      (xhat.at(0), xhat.at(1), d),
    ).map(P)
    line(..ra, stroke: luma(30%) + 0.5pt)

    // --- vertices ---
    circle(P(O), radius: 0.05, fill: luma(45%), stroke: none)
    content(
      P(O),
      text(size: st.label, fill: luma(30%))[$hat(x)' = 0$],
      anchor: "east",
      padding: 0.16,
    )
    circle(P(xhat), radius: 0.06, fill: black, stroke: none)
    content(
      P(xhat),
      text(size: st.label)[$hat(x) = K y$],
      anchor: "north",
      padding: 0.18,
    )
    circle(P(xtrue), radius: 0.06, fill: black, stroke: none)
    content(P(xtrue), text(size: st.label)[$x$], anchor: "south", padding: 0.14)
  }))
}
