// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/dare-convergence.typ — the DARE / Riccati convergence figure.
//
// Data: paper/data/dare_convergence.json, emitted by extraction/ocaml/driver.exe
// (the faithful port of theories/kalman.v `riccati_step` iterated from 0, i.e.
// the `Pseq` of theories/dare.v whose limit is `Pss`).
//
// Two panels:
//   A — geometric convergence: ||P_k - P_ss||_F vs k on a log scale; the
//       straight-line decay is the quantitative content of riccati_frob_cvgn.
//   B — the covariance ellipse of P_k morphing from a point (P_0 = 0) up to the
//       steady-state ellipse P_ss (Loewner-increasing chain, riccati_mono.v).

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "../common/markup-shorthands.typ": *
#import "ellipse.typ": add-ellipse
#import "plotdata.typ": dare-convergence-path, load, points
#import "style.typ": viz-canvas, viz-resolve

#let dare-data = load(dare-convergence-path)

// Least-squares line y = a x + b through equal-length numeric arrays xs, ys.
#let lsq-line(xs, ys) = {
  let n = xs.len()
  let sx = xs.sum()
  let sy = ys.sum()
  let sxx = xs.zip(xs).map(((a, b)) => a * b).sum()
  let sxy = xs.zip(ys).map(((a, b)) => a * b).sum()
  let a = (n * sxy - sx * sy) / (n * sxx - sx * sx)
  (a, (sy - a * sx) / n)
}

// Panel A: log-scale Frobenius distance to the fixed point. Scientific (boxed)
// axes: the log ordinate has no true zero, so a central school-book origin would
// falsely mark 10^0 = 0; the box keeps the floor at y-min, below the grid.
#let panel-convergence(data, st) = viz-canvas(st, cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (paint: gray, thickness: 0.5pt),
    tick: (stroke: gray + 0.5pt),
  ))
  let pts = points(data.iterations, "k", "log10_frob_dist")
  let kmax = calc.max(..data.iterations.map(it => it.k))
  // Fit the asymptotic geometric rate over the linear regime (skip the early
  // pre-asymptotic transient k < 4). The distance oscillates ABOUT this line:
  // the closed loop has complex eigenvalues, so the error decays with a wavy
  // envelope rather than a clean straight line. The slope equals log10 ρ(A_cl)².
  let lin = data.iterations.filter(it => it.k >= 4)
  let (a, b) = lsq-line(lin.map(it => it.k), lin.map(it => it.log10_frob_dist))
  let fit-line = ((0, b), (kmax, a * kmax + b))
  cetz-plot.plot.plot(
    name: "conv",
    size: (6, 5),
    x-label: text(size: st.label, $k$),
    y-label: text(size: st.label, $norm(P_k - P_ss)_F$),
    x-min: 0,
    x-max: kmax + 1,
    y-min: -13,
    y-max: 1,
    x-tick-step: 5,
    y-tick-step: 3,
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
        fit-line,
        style: (stroke: (paint: red, dash: "dashed", thickness: 0.8pt)),
        label: text(size: st.legend, $rho(A_(c l))^2$),
      )
      cetz-plot.plot.add(
        pts,
        style: (stroke: black + 1pt),
        mark: "o",
        mark-size: 0.12,
      )
    },
  )
}))

// Panel B: covariance ellipses { v : v^T P_k^{-1} v = 1 } morphing to P_ss.
#let panel-ellipses(data, max-shown: 12, style: (:)) = {
  let st = viz-resolve(style)
  viz-canvas(st, cetz.canvas(length: 1cm, {
    cetz.draw.set-style(axes: (
      stroke: (dash: "dotted", paint: gray),
      tick: (stroke: gray + 0.5pt),
    ))
    // Non-degenerate early iterates (skip P_0 = 0) that show the morphing.
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
      x-label: text(size: st.label, $x_1$),
      y-label: text(size: st.label, $x_2$),
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
        // Steady-state ellipse, emphasized.
        let ess = data.Pss_ellipse
        add-ellipse(
          radii: (ess.a, ess.b),
          rotation: ess.angle_rad * 1rad,
          stroke: red + 1.3pt,
          show-radii: true,
        )
      },
    )
  }))
}

// Side-by-side figure body (placed inside a #figure in parts/part4.typ).
#let dare-convergence-figure(data: dare-data, style: (:)) = {
  let st = viz-resolve(style)
  grid(
    columns: (auto, auto),
    gutter: 1.5em,
    align: bottom,
    stack(
      spacing: 0.6em,
      panel-convergence(data, st),
      align(center, text(size: st.subcaption)[(а) геометрическая сходимость по
        норме Фробениуса]),
    ),
    stack(
      spacing: 0.6em,
      panel-ellipses(data, style: style),
      align(center, text(size: st.subcaption)[(б) эллипсы ковариации
        $P_k -> P_ss$]),
    ),
  )
}
