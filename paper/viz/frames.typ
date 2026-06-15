// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/frames.typ — small-multiples ("frame strip") helper.
//
// The static analogue of an interactive slider: render the same plot for a sweep
// of a parameter (k, eps, an
// eigenvalue, …) as a row — or a labelled grid of rows — of cetz canvases on a
// shared scale. Figures stay declarative: pass the per-frame data and a `render`
// function returning one (fixed-size) canvas, and this lays them out aligned.

// A strip of frames, optional per-frame sublabel underneath.
//   items    — array of per-frame data
//   render   — item => content (a fixed-size canvas)
//   sublabel — none | (item => content) placed under each frame
//   dir      — ltr (a horizontal row, the default) | ttb (a vertical column)
#let frame-strip(items, render, sublabel: none, gutter: 0.4em, dir: ltr) = {
  let cells = items.map(it => if sublabel != none {
    stack(spacing: 0.3em, render(it), sublabel(it))
  } else {
    render(it)
  })
  if dir == ttb {
    grid(columns: (auto,), row-gutter: gutter, align: center, ..cells)
  } else {
    grid(
      columns: items.map(_ => auto),
      column-gutter: gutter,
      align: bottom + center,
      ..cells,
    )
  }
}

// A labelled grid of frame rows sharing one column scale.
//   rows       — array of (label: content, items: array)
//   render     — item => content (a fixed-size canvas), shared by every cell
//   top-labels — none | array of content (length = #columns) shown above the grid
// All rows must have the same number of items; the left label column is `auto`,
// frame columns are equal so the cells line up across rows.
#let frame-grid(
  rows,
  render,
  top-labels: none,
  col-gutter: 0.35em,
  row-gutter: 0.5em,
) = {
  let ncol = rows.first().items.len()
  let cells = ()
  if top-labels != none {
    cells.push([]) // empty corner above the label column
    for t in top-labels { cells.push(align(center, t)) }
  }
  for row in rows {
    cells.push(align(right + horizon, row.label))
    for it in row.items { cells.push(align(center + horizon, render(it))) }
  }
  grid(
    columns: (auto,) + range(ncol).map(_ => auto),
    column-gutter: col-gutter,
    row-gutter: row-gutter,
    align: center + horizon,
    ..cells,
  )
}
