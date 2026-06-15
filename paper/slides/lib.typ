// Общие между текстом и слайдами сокращения и подсветка Rocq.

#import "@local/unn-itmm:0.2.1": *
#import "@preview/codly:1.3.0": codly-init
#import "../common/preamble.typ": *
#import "../common/rocq.typ": *

// Пять результатов работы (по заключению ВКР). Карта результатов
// показывается трижды: анонс на задачах, прогресс по ходу доклада, итог на
// выводах.
#let result-clusters = (
  [Корректность шага],
  [Несмещённость, оптимальность],
  [Структурные условия],
  [Сходимость к ДАУР],
  [Извлечение кода],
)

#let results-progress(current: none, done: ()) = result-map(
  result-clusters,
  current: current,
  done: done,
  size: 11pt,
  height: 44pt,
)

// Размеры подписей viz-фигур на слайдах: один общий набор групп
// (см. paper/viz/style.typ), крупнее текста, потому что фигуры
// уменьшаются при вписывании в колонку слайда.
#let slide-viz = (
  label: 14pt,
  tick: 11pt,
  legend: 12pt,
  subcaption: 12pt,
  annot: 12pt,
)

// Готовая фигура в масштабе слайда: вписывается в доступную
// ширину (доля `s`) с ограничением высоты `max-h`.
#let slide-fig(body, s: 1.0, max-h: 235pt) = align(center, layout(size => {
  let m = measure(body)
  let f = calc.min(size.width / m.width, max-h / m.height) * s
  scale(reflow: true, f * 100%, body)
}))

// Компактный листинг Rocq: без нумерации строк, уменьшенный шрифт,
// по умолчанию только формулировка (без тела доказательства).
// `name` передаётся без ключевого слова: `slide-snippet("kalman.v", "unbiased")`.
#let slide-snippet(source, name, size: 13pt, proof: false) = [
  #show raw.where(block: true): set text(size: size)
  #let lines = rocq-src(source).split("\n")
  #let loc = rocq-locate(lines, name)
  #let stmt = rocq-statement-range(lines, loc.idx, loc.kind)
  #let end = if proof {
    let pr = rocq-proofbody-range(lines, loc.idx)
    if pr == none { stmt.end } else { pr.end }
  } else { stmt.end }
  #let snippet = rocq-dedent-lines(lines.slice(stmt.start, end + 1))
  #rocq-codly(
    rocq-raw(snippet.join("\n")),
    source,
    number-format: none,
    display-icon: false,
  )
]
