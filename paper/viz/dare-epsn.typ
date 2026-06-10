// viz/dare-epsn.typ — the Frobenius ε–N staircase.
//
// Data: paper/data/dare_convergence.json (the same file panel A of
// dare-convergence.typ uses; no new driver). Each iteration carries
// `log10_frob_dist` = log10 ||P_k - Pss||_F, so the *squared* distance is
// 2·log10_frob_dist on the log axis.
//
// One picture, one theorem: this figure turns the ∀ε ∃N quantifier of
// `cvgn_frob_sq_eps_N` / `riccati_frob_cvgn` (theories/dare.v) into a
// picture. Those lemmas bound the SQUARED Frobenius norm
// `\tr((P_k - Pss)^† (P_k - Pss)) = ||P_k - Pss||_F^2 < ε`, so the y-axis is
// that squared norm and the ε threshold is a literal horizontal line at 10^e.
//
// Layout — a frame strip (small multiples, "slider flattened" over ε): the same
// geometric-decay panel repeated for ε ∈ {10⁻², 10⁻⁴, 10⁻⁶}. Each frame overlays
//   • a red dashed horizontal line at the ε level, and
//   • a blue dashed vertical marker at N(ε) — the first step from which the whole
//     tail stays below ε — with a dot at the crossing.
// The per-frame sublabel quotes the computed N(ε), so prose and picture cannot drift.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "frames.typ": frame-strip
#import "plotdata.typ": dare-convergence-path, load
#import "style.typ": viz-canvas, viz-resolve

#let epsn-data = load(dare-convergence-path)

// The swept parameter: ε = 10^e for these exponents (log10 ε = e exactly).
#let epsn-exponents = (-2, -4, -6)

// Shared log-scale axis bounds (every frame on the same scale — the point of a
// frame strip). Zoomed onto the fourth quadrant near the origin so the three
// thresholds ε ∈ {10⁻², 10⁻⁴, 10⁻⁶} and their N(ε) crossings stay distinct; the
// tail below 10⁻⁹ runs off the bottom and is not the point here.
#let epsn-ymin = -9
#let epsn-ymax = 1
#let epsn-xmax = 18

// N(ε): the smallest N such that the *whole tail* {k ≥ N} stays below ε, exactly
// the ∃N of the lemma (not merely the first crossing). Returns the crossing row
// {k, log10_frob_dist}, or none if the run never settles below ε.
#let n-eps(rows, e) = {
  let last-bad = -1
  for (i, r) in rows.enumerate() {
    if 2 * r.log10_frob_dist >= e { last-bad = i }
  }
  if last-bad + 1 < rows.len() { rows.at(last-bad + 1) } else { none }
}

// One frame: the geometric-decay panel with the ε line and the N(ε) marker.
#let epsn-frame(data, e, st) = {
  let rows = data.iterations
  // Keep only points inside the zoomed window (school-book axes do not clip, so
  // out-of-range points would render as stray marks below the frame).
  let pts = rows
    .filter(it => it.k <= epsn-xmax and 2 * it.log10_frob_dist >= epsn-ymin)
    .map(it => (it.k, 2 * it.log10_frob_dist))
  let cross = n-eps(rows, e)
  viz-canvas(st, cetz.canvas(length: 1cm, {
    cetz.draw.set-style(axes: (
      stroke: (dash: "dotted", paint: gray),
      tick: (stroke: gray + 0.5pt),
    ))
    cetz-plot.plot.plot(
      name: "p",
      size: (4, 3.4),
      x-label: text(size: st.label, $k$),
      y-label: text(size: st.label, $norm(P_k - P_(s s))_F^2$),
      x-min: 0,
      x-max: epsn-xmax,
      y-min: epsn-ymin,
      y-max: epsn-ymax,
      x-tick-step: 4,
      y-tick-step: 2,
      y-format: v => {
        let ee = int(calc.round(v))
        [#text(size: st.tick)[$10^(#ee)$]]
      },
      x-grid: "both",
      y-grid: "both",
      axis-style: "scientific",
      {
        cetz-plot.plot.add(
          pts,
          style: (stroke: black + 0.9pt),
          mark: "o",
          mark-size: 0.06,
          mark-style: (stroke: black + 0.5pt, fill: white),
        )
        // ε threshold and the N(ε) marker, in data coordinates (resize: false so
        // the labels never stretch the shared axis).
        cetz-plot.plot.annotate(resize: false, {
          cetz.draw.line(
            (0, e),
            (epsn-xmax, e),
            stroke: (paint: red, dash: "dashed", thickness: 1pt),
          )
          cetz.draw.content(
            (epsn-xmax * 0.85, e),
            anchor: "center",
            box(fill: white, inset: (x: 1.5pt), text(
              size: st.annot,
              fill: red,
            )[$epsilon$]),
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
              (nk + 0.3, epsn-ymin + 0.6),
              anchor: "west",
              box(fill: white, inset: (x: 1.5pt), text(
                size: st.annot,
                fill: blue,
              )[$N(epsilon)$]),
            )
          }
        })
      },
    )
  }))
}

// Per-frame sublabel: ε and the computed N(ε), quoted from the data.
#let epsn-sublabel(data, e, st) = {
  let cross = n-eps(data.iterations, e)
  let nstr = if cross != none { str(cross.k) } else { $-$ }
  text(size: st.subcaption)[$epsilon = 10^(#e)$, #h(0.3em)
    $N(epsilon) = #nstr$]
}

// Figure body (placed inside a #figure in parts/part4.typ). `dir: ttb` lays
// the frames out as a column and `exponents` selects a subset of the sweep
// (both used on slides).
#let dare-epsn-figure(
  data: epsn-data,
  style: (:),
  dir: ltr,
  exponents: epsn-exponents,
) = {
  let st = viz-resolve(style)
  frame-strip(
    exponents,
    e => epsn-frame(data, e, st),
    sublabel: e => epsn-sublabel(data, e, st),
    gutter: 1.2em,
    dir: dir,
  )
}
