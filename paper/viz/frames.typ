
#let frame-strip(items, render, sublabel: none, gutter: 0.4em) = grid(
  columns: items.map(_ => auto),
  column-gutter: gutter,
  align: bottom + center,
  ..items.map(it => if sublabel != none {
    stack(spacing: 0.3em, render(it), sublabel(it))
  } else {
    render(it)
  }),
)

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
