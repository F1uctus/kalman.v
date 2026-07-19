// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/gramian.typ — observability / controllability gramian ellipses.
//
// Data: paper/data/gramian.json, emitted by extraction/ocaml/driver.exe from the
// extracted, verified seqmx programs theories/seqmx/gramian.v
// (`obsv_gram_seqmx` / `ctrl_gram_seqmx`, proven equal to theories/obsv_bound.v
// `obsv_gram` / `ctrl_gram`). The picture is the
// content of `obsv_gram_pd_of_observable` / `ctrl_gram_pd_of_controllable`: the
// finite gramian becomes positive-definite *exactly* at k = n when the pair is
// observable / controllable, and never for a degenerate pair.
//
// Layout — a 4-row frame strip (small multiples over k), reusing add-ellipse:
//   O_k observable    : a rank-1 sliver at k=1 that fills out to a PD ellipse at
//                       k=n=2 and keeps growing (teal);
//   O_k unobservable  : a flat degenerate sliver at every k (gray dashed);
//   C_k controllable  : dual of the first row;
//   C_k uncontrollable: dual of the second.
// The gramian ellipsoid is the image of the unit ball under G_k^{1/2}, so its
// semi-axes are sqrt(eig G_k) — exactly the cov_ellipse2 convention.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "ellipse.typ": add-ellipse
#import "frames.typ": frame-grid
#import "wire.typ": load, eig2, ellipse2, pd
#import "style.typ": viz-canvas, viz-resolve

#let raw = load("/paper/data/gramian.json")
#let gramian-data = (n: 2, kmax: 5, cases: raw.cases.map(c => (
  kind: c.kind, positive: c.positive, F: c.F, view: c.view, weight: c.weight,
  pd_at_n: pd(c.frames.at(1)),
  frames: c.frames.enumerate().map(((i, g)) => {
    let (l1, l2) = eig2(g)
    (k: i + 1, gram: g, eig: (l1, l2), pd: pd(g), ellipse: ellipse2(g))
  }),
)))

#let gram-lim = 2.0 // shared square scale (all four gramians fit, comparably)
#let gram-pd-color = rgb("#1f6f6b") // PD => a proper 2-D ellipse
#let gram-deg-color = luma(45%) // degenerate => a flat sliver

// One small multiple: the gramian ellipse at a single k, on the shared scale.
// A boxed panel (no central cross — the degenerate slivers are axis-aligned and
// would hide under it). PD frames get a solid teal ellipse (add-ellipse); a
// degenerate gramian (b = 0) collapses to a flat gray sliver, drawn with tip
// markers so its extent — and its growth in k — stays legible.
#let gram-frame(it, lim: gram-lim) = cetz.canvas(length: 1.4cm, {
  cetz-plot.plot.plot(
    size: (2, 2),
    axis-style: "scientific",
    x-label: none,
    y-label: none,
    x-min: -lim,
    x-max: lim,
    y-min: -lim,
    y-max: lim,
    x-tick-step: none,
    y-tick-step: none,
    {
      let e = it.ellipse
      if it.pd {
        add-ellipse(
          radii: (e.a, e.b),
          rotation: e.angle_rad * 1rad,
          stroke: gram-pd-color + 1.2pt,
        )
      } else {
        add-ellipse(
          radii: (e.a, 0),
          rotation: e.angle_rad * 1rad,
          stroke: gram-deg-color + 1.4pt,
        )
        let tip = (e.a * calc.cos(e.angle_rad), e.a * calc.sin(e.angle_rad))
        cetz-plot.plot.add(
          (tip, (-tip.at(0), -tip.at(1))),
          style: (stroke: none),
          mark: "o",
          mark-size: 0.13,
          mark-style: (stroke: gram-deg-color, fill: gram-deg-color),
        )
      }
    },
  )
})

// Left-hand row label: the gramian symbol plus a short observability /
// controllability qualifier.
#let gram-row-label(c, st) = {
  let sym = if c.kind == "obsv" { $cal(O)_k$ } else { $cal(C)_k$ }
  let qual = if c.kind == "obsv" {
    if c.positive { [$(H,F)$ набл.] } else { [$(H,F)$ ненабл.] }
  } else {
    if c.positive { [$(F,G)$ упр.] } else { [$(F,G)$ неупр.] }
  }
  stack(
    spacing: 0.3em,
    text(size: st.label, sym),
    text(size: st.annot, qual),
  )
}

// Top labels k = 1 … kmax; the k = n column (where PD switches on) is emphasized.
#let gram-top-labels(data, st, kmax) = range(1, kmax + 1).map(k => if (
  k == data.n
) {
  text(size: st.label, weight: "bold")[$k = #k = n$]
} else {
  text(size: st.label)[$k = #k$]
})

// `kmax` caps how many k-columns are shown (default: all available).
#let gramian-figure(data: gramian-data, style: (:), kmax: none) = {
  let st = viz-resolve(style)
  let kshow = if kmax == none { data.kmax } else { calc.min(kmax, data.kmax) }
  frame-grid(
    data.cases.map(c => (
      label: gram-row-label(c, st),
      items: c.frames.slice(0, kshow),
    )),
    it => gram-frame(it),
    top-labels: gram-top-labels(data, st, kshow),
  )
}
