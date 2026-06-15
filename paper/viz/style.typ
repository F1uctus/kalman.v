// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/style.typ — shared text sizes for the main element groups of every viz
// figure. The thesis renders with `viz-style` as is; the slides pass larger
// overrides through the `style:` parameter of each figure (figures are scaled
// down when fitted into a slide column, so the source sizes must be larger to
// keep the same effective size).
//
// Groups:
//   label      — primary text: axis labels, node/block labels, row symbols;
//   tick       — tick labels (numbers and powers on axes); also the default
//                text size inside every canvas, so unformatted cetz-plot ticks
//                inherit it instead of the surrounding document size;
//   legend     — legend entries;
//   subcaption — (а)/(б) sublabels under panels and per-frame sublabels;
//   annot      — small in-figure annotations (ε, N(ε), флаги PBH, примечания).

#let viz-style = (
  label: 9pt,
  tick: 8pt,
  legend: 8pt,
  subcaption: 9pt,
  annot: 8pt,
)

// Merge user overrides over the defaults.
#let viz-resolve(style) = viz-style + style

// Canvas wrapper: pins the default text size inside the canvas to the tick
// group, so nothing inherits the (much larger) document or slide text size.
#let viz-canvas(st, body) = [
  #set text(size: st.tick)
  #body
]
