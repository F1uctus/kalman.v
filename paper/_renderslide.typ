#import "slides/lib.typ": *
#import "viz/kalman-run-3d.typ": kalman-run-3d-figure

// Replicates the unn-itmm content body box (668 x 243 pt) exactly.
#set page(
  width: 720pt,
  height: 405pt,
  margin: (top: 126pt, left: 29pt, right: 23pt, bottom: 36pt),
  fill: white,
)
#place(top + left, dy: -53pt, text(size: 22pt, weight: "bold", fill: rgb("#15356b"))[
  Эксперимент в пространстве
])

#set text(size: 14pt)

#slide-fig(
  kalman-run-3d-figure(style: slide-viz),
  max-h: 214pt,
)

Истинная траектория есть винтовая линия; коридор $plus.minus 2 sigma_k$ доказан
отдельной леммой.
