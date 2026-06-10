// viz/lyapunov.typ — the Lyapunov partial-sum convergence figure.
//
// Data: paper/data/lyapunov.json, emitted by extraction/ocaml/driver.exe
// (gen_lyapunov). The exact matrices are the extracted controllability gramian
// ctrl_gram_seqmx run with G = I_2, Q = W, which equals the Lyapunov partial sum
// lyap_partial A W N = Σ_{k<N} A^k W (A†)^k by gramian_infty.ctrl_gram_eq_partial.
//
// One picture, one theorem: lyap_partial rises monotonically in the Loewner order
// (lyapunov.lyap_partial_mono) to the solution lyap_sol A W of X = A X A† + W
// (lyapunov.lyap_sol). The figure plots ||P_N - X_∞||_F vs N on a log scale; the
// straight line is the geometric rate ρ(A)² of the monotone rise. The companion
// covariance-ellipse nesting (P_0 = 0 growing to the limit) is shown where the
// text is about monotonicity, in riccati-monotone.typ.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "plotdata.typ": load, points, lyapunov-path
#import "style.typ": viz-canvas, viz-resolve

#let lyap-data = load(lyapunov-path)

// Log-scale Frobenius distance to the Lyapunov solution. Scientific (boxed) axes:
// the squared norm has no true zero, so a central school-book origin would imply
// a false 10^0 = 0; the box puts the floor at y-min, below the grid.
#let panel-convergence(data, st) = viz-canvas(st, cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (paint: gray, thickness: 0.5pt),
    tick: (stroke: gray + 0.5pt),
  ))
  let pts = points(data.iterations, "N", "log10_frob_dist")
  cetz-plot.plot.plot(
    name: "conv",
    size: (8.5, 5),
    x-label: text(size: st.label, $N$),
    y-label: text(size: st.label, $norm(P_N - X_oo)_F$),
    x-min: 0,
    x-max: calc.max(..data.iterations.map(it => it.N)) + 1,
    y-min: -7,
    y-max: 1,
    x-tick-step: 6,
    y-tick-step: 2,
    y-format: v => {
      let e = int(calc.round(v))
      [#text(size: st.tick)[$10^(#e)$]]
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
}))

// Reactive note: the computed limit (trace) and the residual at the last step,
// quoted from the data so prose and picture cannot drift.
#let lyap-note(data, st) = {
  let s = data.lyap_sol
  let tr-lim = s.at(0).at(0) + s.at(1).at(1)
  let last = data.iterations.last()
  let le = calc.round(last.log10_frob_dist, digits: 1)
  text(size: st.annot)[
    $"tr" X_oo approx #calc.round(tr-lim, digits: 2)$, #h(0.4em)
    $norm(P_#last.N - X_oo)_F approx 10^(#le)$
  ]
}

// Figure body (placed inside a #figure in parts/part4.typ).
#let lyapunov-figure(data: lyap-data, style: (:)) = {
  let st = viz-resolve(style)
  stack(
    spacing: 0.9em,
    panel-convergence(data, st),
    align(center, lyap-note(data, st)),
  )
}
