// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/schur-stability.typ — Schur stability of the closed loop.
//
// Data: paper/data/schur_stability.json, emitted by extraction/ocaml/driver.exe
// from the extracted, verified theories/seqmx/experiments.v
// `closed_loop_seqmx`. The closed-loop matrix A_cl = F - F K_f H = F(I - K_f H)
// (the predicted-covariance form F_p of dare.v `riccati_closed_loop_identity`)
// has spectral radius rho < 1 — the classical condition behind DARE convergence
// (theories/spec_rad.v `spec_rad_lt1`, detectability.v `schur_stable`). Two panels:
//   (a) the eigenvalues of A_cl, the spectral-radius circle of radius rho, and
//       the unit circle in the complex plane;
//   (b) ||A_cl^k||_F -> 0 (geometric decay) — the dynamical meaning of rho < 1,
//       the discrete analogue of the complex-cnvg.typ spiral.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "wire.typ": load, frob, mat-pow, spectral-radius, eig2-general
#import "style.typ": viz-canvas, viz-resolve

#let raw = load("/paper/data/schur_stability.json")
#let ((r1, i1), (r2, i2)) = eig2-general(raw.A_cl)
#let schur-data = (
  A_cl: raw.A_cl, spectral_radius: spectral-radius(raw.A_cl),
  eigenvalues: ((re: r1, im: i1), (re: r2, im: i2)),
  // The raw JSON carries only A_cl. Typst computes A_cl^k and its Frobenius norm here.
  power_norms: range(31).map(k => (k: k, frob: frob(mat-pow(raw.A_cl, k)))),
)

#let circle-curve(r) = t => (r * calc.cos(t), r * calc.sin(t))

#let panel-eigs(data, st) = viz-canvas(st, cetz.canvas(length: 1cm, {
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
    x-label: text(size: st.label, $Re$),
    y-label: text(size: st.label, $Im$),
    x-tick-step: 0.5,
    y-tick-step: 0.5,
    x-grid: "both",
    y-grid: "both",
    axis-style: "school-book",
    {
      cetz-plot.plot.add(
        domain: (-3.15, 3.15),
        samples: 200,
        circle-curve(1),
        style: (stroke: gray + 0.8pt),
      )
      cetz-plot.plot.add(
        domain: (-3.15, 3.15),
        samples: 200,
        circle-curve(sr),
        style: (stroke: (paint: red, dash: "dashed", thickness: 0.8pt)),
      )
      cetz-plot.plot.add(
        eigs,
        mark: "o",
        mark-size: 0.16,
        style: (stroke: none),
        mark-style: (stroke: blue, fill: blue.lighten(40%)),
      )
    },
  )
}))

// The (а) legend as a plain content row under the panel: a cetz-plot legend
// (south or inner) changes the canvas bounds and misaligns the two grids.
#let eigs-legend(data, st) = {
  let item(sample, body) = box(grid(
    columns: 2,
    column-gutter: 0.4em,
    align: horizon,
    sample, text(size: st.legend, body),
  ))
  stack(
    dir: ltr,
    spacing: 1em,
    item(line(length: 16pt, stroke: gray + 0.8pt), [единичная окружность]),
    item(
      line(length: 16pt, stroke: (
        paint: red,
        dash: "dashed",
        thickness: 0.8pt,
      )),
      $rho = #calc.round(data.spectral_radius, digits: 3)$,
    ),
    item(
      circle(radius: 2.6pt, stroke: blue, fill: blue.lighten(40%)),
      [спектр $A_(c l)$],
    ),
  )
}

#let panel-decay(data, st) = viz-canvas(st, cetz.canvas(length: 1cm, {
  // Scientific (boxed) axes: a log ordinate has no true zero, so a central
  // school-book origin would falsely mark 10^0 = 0; the box puts the floor at
  // y-min, well below the data.
  cetz.draw.set-style(axes: (
    stroke: (paint: gray, thickness: 0.5pt),
    tick: (stroke: gray + 0.5pt),
  ))
  let pts = data.power_norms.map(r => (
    r.k,
    if r.frob > 0 { calc.log(r.frob, base: 10) } else { -16 },
  ))
  let kmax = data.power_norms.last().k
  // Asymptotic geometric envelope rho^k (log10 = k log10 rho). Because A_cl is
  // non-normal, the actual norm first rises above it (transient growth) and only
  // later settles parallel to it: the gap to this line is the source of the bump.
  // (named `sr`, not `rho`: a `rho` binding would shadow the ρ math symbol used
  // in the legend label below.)
  let sr = data.spectral_radius
  let rho-line = ((0, 0), (kmax, kmax * calc.log(sr, base: 10)))
  cetz-plot.plot.plot(
    name: "decay",
    size: (5.5, 5.5),
    x-label: text(size: st.label, $k$),
    y-label: text(size: st.label, $norm(A_(c l)^k)_F$),
    x-min: 0,
    x-max: kmax,
    y-min: -5.5,
    y-max: 1,
    x-tick-step: 5,
    y-tick-step: 1,
    y-format: v => {
      let e = int(calc.round(v))
      [#text(size: st.tick)[$10^(#e)$]]
    },
    x-grid: "both",
    y-grid: "both",
    axis-style: "scientific",
    legend: "inner-north-east",
    legend-style: (
      stroke: none,
      fill: white,
      padding: 0.2,
      item: (spacing: 0.3),
    ),
    {
      cetz-plot.plot.add(
        rho-line,
        style: (stroke: (paint: red, dash: "dashed", thickness: 0.8pt)),
        label: text(size: st.legend, $rho^k$),
      )
      cetz-plot.plot.add(
        pts,
        style: (stroke: black + 1pt),
        mark: "o",
        mark-size: 0.1,
      )
    },
  )
}))

// Both plot areas are 5.5 x 5.5; the panels share one horizon-aligned grid
// row (legend and subcaptions live in separate rows), so the two coordinate
// grids line up at the same height. `dir: ttb` stacks the panels vertically
// (used on slides).
#let schur-stability-figure(data: schur-data, style: (:), dir: ltr) = {
  let st = viz-resolve(style)
  let cap-a = text(size: st.subcaption)[(а) спектр $A_(c l)$ внутри единичной
    окружности]
  let cap-b = text(size: st.subcaption)[(б) геометрическая сходимость
    $norm(A_(c l)^k)_F -> 0$]
  if dir == ttb {
    grid(
      columns: (auto,),
      row-gutter: 0.6em,
      align: center,
      panel-eigs(data, st),
      eigs-legend(data, st),
      cap-a,
      panel-decay(data, st),
      cap-b,
    )
  } else {
    grid(
      columns: (auto, auto),
      column-gutter: 1.5em,
      row-gutter: 0.6em,
      align: center + horizon,
      panel-eigs(data, st), panel-decay(data, st),
      eigs-legend(data, st), [],
      cap-a, cap-b,
    )
  }
}
