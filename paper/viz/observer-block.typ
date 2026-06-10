// viz/observer-block.typ — оптимальный наблюдатель с обратной связью по
// инновации, по мотивам Kailath, Sayed, Hassibi "Linear Estimation", Fig. 1.1
// "The optimum transient observer". Верхний пунктирный контур воспроизводит
// модель в пространстве состояний, нижний повторяет её детерминированную часть
// и корректируется инновацией через усиление K_{p,k}. Схема без данных,
// нарисована примитивами cetz.

#import "@preview/cetz:0.5.2"
#import "style.typ": viz-resolve

#let observer-block-canvas(st) = cetz.canvas(length: 1.05cm, {
  import cetz.draw: circle, content, line, rect

  let wire = (paint: black, thickness: 0.8pt)
  let boxst = (paint: gray, dash: "dashed", thickness: 0.8pt)
  let mk = (end: ">", scale: 0.55, fill: black)
  let rsum = 0.16

  // Прямоугольный блок с подписью.
  let blk(cx, cy, w, h, label) = {
    rect((cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), stroke: wire)
    content((cx, cy), text(size: st.label, label))
  }
  // Сумматор: кружок со знаком плюс.
  let adder(cx, cy) = {
    circle((cx, cy), radius: rsum, stroke: wire)
    line((cx - 0.07, cy), (cx + 0.07, cy), stroke: wire)
    line((cx, cy - 0.07), (cx, cy + 0.07), stroke: wire)
  }
  // Точка ветвления сигнала.
  let tap(cx, cy) = circle((cx, cy), radius: 0.045, fill: black, stroke: none)

  // ===== верхний контур: модель системы =====================================
  rect((-6.0, 0.55), (5.4, 3.6), stroke: boxst)
  content(
    (-0.3, 3.6),
    box(
      fill: white,
      inset: (x: 2.5pt),
      text(size: st.label + 1pt, fill: gray.darken(25%))[СИСТЕМА],
    ),
  )

  // вход управления и точка ветвления к наблюдателю
  content((-6.55, 2.2), text(size: st.label, $bold(u)_k$))
  line((-6.3, 2.2), (-4.96, 2.2), stroke: wire, mark: mk)
  tap(-5.7, 2.2)

  // шум процесса
  content((-4.8, 3.2), text(size: st.label, $bold(w)_(k+1)$))
  line((-4.8, 2.95), (-4.8, 2.36), stroke: wire, mark: mk)
  adder(-4.8, 2.2)

  line((-4.64, 2.2), (-4.15, 2.2), stroke: wire, mark: mk)
  blk(-3.7, 2.2, 0.9, 0.6, $G$)
  line((-3.25, 2.2), (-2.66, 2.2), stroke: wire, mark: mk)
  adder(-2.5, 2.2)
  line((-2.34, 2.2), (-1.75, 2.2), stroke: wire, mark: mk)
  blk(-1.25, 2.2, 1.0, 0.6, $z^(-1)$)
  line((-0.75, 2.2), (1.1, 2.2), stroke: wire, mark: mk)
  tap(0.1, 2.2)
  content((0.1, 2.48), text(size: st.label, $bold(x)_k$))
  blk(1.5, 2.2, 0.8, 0.6, $H$)
  line((1.9, 2.2), (2.74, 2.2), stroke: wire, mark: mk)

  // шум измерения и выход
  content((2.9, 3.2), text(size: st.label, $bold(v)_k$))
  line((2.9, 2.95), (2.9, 2.36), stroke: wire, mark: mk)
  adder(2.9, 2.2)
  line((3.06, 2.2), (5.9, 2.2), stroke: wire, mark: mk)
  tap(4.5, 2.2)
  content((6.1, 2.2), anchor: "west", text(size: st.label, $bold(y)_k$))

  // обратная связь динамики F
  line((0.1, 2.2), (0.1, 1.0), stroke: wire)
  line((0.1, 1.0), (-0.85, 1.0), stroke: wire, mark: mk)
  blk(-1.25, 1.0, 0.8, 0.56, $F$)
  line((-1.65, 1.0), (-2.5, 1.0), stroke: wire)
  line((-2.5, 1.0), (-2.5, 2.04), stroke: wire, mark: mk)

  // ===== нижний контур: наблюдатель ==========================================
  rect((-6.0, -4.9), (5.4, -0.6), stroke: boxst)
  content(
    (-0.3, -4.9),
    box(
      fill: white,
      inset: (x: 2.5pt),
      text(size: st.label + 1pt, fill: gray.darken(25%))[НАБЛЮДАТЕЛЬ],
    ),
  )

  // копия управления
  line((-5.7, 2.2), (-5.7, -1.5), stroke: wire)
  line((-5.7, -1.5), (-4.15, -1.5), stroke: wire, mark: mk)
  blk(-3.7, -1.5, 0.9, 0.6, $G$)
  line((-3.25, -1.5), (-2.66, -1.5), stroke: wire, mark: mk)
  adder(-2.5, -1.5)
  line((-2.34, -1.5), (-1.75, -1.5), stroke: wire, mark: mk)
  blk(-1.25, -1.5, 1.0, 0.6, $z^(-1)$)
  line((-0.75, -1.5), (1.1, -1.5), stroke: wire, mark: mk)
  tap(0.1, -1.5)
  content((0.1, -1.22), text(size: st.label, $hat(x)_k$))
  blk(1.5, -1.5, 0.8, 0.6, $H$)
  line((1.9, -1.5), (2.74, -1.5), stroke: wire, mark: mk)
  content((2.3, -1.24), text(size: st.label, $hat(y)_k$))

  // инновация: e_k = y_k - ŷ_k
  line((4.5, 2.2), (4.5, -1.5), stroke: wire)
  line((4.5, -1.5), (3.06, -1.5), stroke: wire, mark: mk)
  adder(2.9, -1.5)
  content((2.55, -1.26), text(size: st.label, $-$))

  line((2.9, -1.66), (2.9, -3.9), stroke: wire)
  content((3.14, -2.7), anchor: "west", text(size: st.label, $e_k$))
  line((2.9, -3.9), (1.0, -3.9), stroke: wire, mark: mk)
  blk(0.4, -3.9, 1.2, 0.6, $K_(p,k)$)
  line((-0.2, -3.9), (-3.1, -3.9), stroke: wire)
  line((-3.1, -3.9), (-3.1, -1.86), stroke: wire)
  line((-3.1, -1.86), (-2.62, -1.61), stroke: wire, mark: mk)

  // обратная связь динамики F наблюдателя
  line((0.1, -1.5), (0.1, -2.7), stroke: wire)
  line((0.1, -2.7), (-0.85, -2.7), stroke: wire, mark: mk)
  blk(-1.25, -2.7, 0.8, 0.56, $F$)
  line((-1.65, -2.7), (-2.5, -2.7), stroke: wire)
  line((-2.5, -2.7), (-2.5, -1.66), stroke: wire, mark: mk)
})

// Схема растягивается на всю ширину текстового блока.
#let observer-block-figure(style: (:)) = {
  let st = viz-resolve(style)
  let canvas = observer-block-canvas(st)
  layout(size => {
    let m = measure(canvas)
    scale(
      reflow: true,
      size.width / m.width * 100%,
      canvas,
    )
  })
}
