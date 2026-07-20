// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/spectral.typ — the antitone inverse figure.
//
// Data: paper/data/spectral.json, emitted by extraction/ocaml/figures/gen_data.ml
// (gen_spectral). Matrices and their inverses are the extracted, verified core
// (cinv_fl = invmx, Faddeev-LeVerrier); the driver self-checks A ⪯ B and B⁻¹ ⪯ A⁻¹ on the exact
// rationals and emits float eigenvalues + quadratic-form ellipse axes.
//
// Quadratic-form level set { x : xᵀ M x = 1 }, semi-axes 1/√λ along the
// eigenvectors (the Loewner convention: A ⪯ B ⟺ E_B ⊆ E_A). Illustrates
// pd_inv_antimono: A ⪯ B (PD) ⇒ B⁻¹ ⪯ A⁻¹, so the level-set containment reverses
// and the major/minor axes swap under inversion. A dashed gray unit circle (the
// level set of the identity) anchors the absolute scale.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "ellipse.typ": add-ellipse
#import "wire.typ": load, eig2, qform-ellipse2

#let raw = load("/paper/data/spectral.json")
#let obj(M) = {
  let (l1, l2) = eig2(M)
  (mat: M, eig: (l1, l2), qform_ellipse: qform-ellipse2(M))
}
#let spectral-data = (
  antitone: (A: obj(raw.A), B: obj(raw.B), A_inv: obj(raw.A_inv), B_inv: obj(raw.B_inv)),
)

// A small square plot canvas on a fixed symmetric range, school-book axes.
#let qf-plot(r, size: 3.1, body) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (dash: "dotted", paint: gray),
    tick: (stroke: gray + 0.5pt),
    x: (mark: (end: "straight")),
    y: (mark: (end: "straight")),
  ))
  cetz-plot.plot.plot(
    name: "p",
    size: (size, size),
    x-min: -r,
    x-max: r,
    y-min: -r,
    y-max: r,
    x-tick-step: none,
    y-tick-step: none,
    x-grid: "both",
    y-grid: "both",
    axis-style: "school-book",
    body,
  )
})

// A pair of quadratic-form ellipses (A-family red, B-family green) over a dashed
// gray unit circle, with a color-keyed relation label. Nesting follows from the
// radii in the data.
#let antitone-pair(red-ell, green-ell, relation, r) = stack(
  spacing: 1em,
  qf-plot(r, size: 5, {
    // unit circle = level set of the identity, a dashed gray scale reference.
    add-ellipse(
      radii: (1, 1),
      rotation: 0deg,
      stroke: (paint: gray, dash: "dashed", thickness: 0.6pt),
    )
    add-ellipse(
      radii: (red-ell.a, red-ell.b),
      rotation: red-ell.angle_rad * 1rad,
      stroke: red + 1.1pt,
    )
    add-ellipse(
      radii: (green-ell.a, green-ell.b),
      rotation: green-ell.angle_rad * 1rad,
      stroke: green + 1.1pt,
    )
  }),
  align(center, text(size: 9.5pt, relation)),
)

#let panel-antitone(data) = {
  let a = data.antitone
  let rel-ab = [
    #text(fill: red)[$A$]
    $thick prec.eq thick$
    #text(fill: green)[$B$]
    $quad thick$
  ]
  let rel-inv = [
    #text(fill: green)[$B^(-1)$]
    $thick prec.eq thick$
    #text(fill: red)[$A^(-1)$]
    $quad thick$
  ]
  grid(
    columns: (auto, auto),
    column-gutter: 1.6em,
    align: bottom,
    // A ⪯ B: the bigger matrix B has the smaller level ellipse (E_B ⊆ E_A).
    antitone-pair(a.A.qform_ellipse, a.B.qform_ellipse, rel-ab, 1.25),
    // inversion reverses it: E_{A⁻¹} ⊆ E_{B⁻¹} (A stays red, B stays green).
    antitone-pair(a.A_inv.qform_ellipse, a.B_inv.qform_ellipse, rel-inv, 3.4),
  )
}

// Reactive note: eigenvalues, and how inversion reciprocates them (quoted data).
#let frac-or-int(x) = {
  let r = calc.round(1 / x)
  if calc.abs(1 / x - r) < 1e-6 and r != 1 { $1 \/ #r$ } else {
    $#calc.round(x, digits: 2)$
  }
}
#let eigpair(e) = $(#frac-or-int(e.at(0)), #frac-or-int(e.at(1)))$

#let spectral-note(data) = {
  let a = data.antitone
  text(size: 9pt)[
    $lambda(A) = #eigpair(a.A.eig)$, #h(0.3em)
    $lambda(A^(-1)) = #eigpair(a.A_inv.eig)$;
    #h(0.6em)
    $lambda(B) = #eigpair(a.B.eig)$, #h(0.3em)
    $lambda(B^(-1)) = #eigpair(a.B_inv.eig)$
  ]
}

// Figure body (placed inside a #figure in parts/part2.typ).
#let spectral-figure(data: spectral-data) = stack(
  spacing: 1.4em,
  panel-antitone(data),
  align(center, spectral-note(data)),
)
