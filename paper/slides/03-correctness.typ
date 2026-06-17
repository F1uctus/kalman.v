// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../slides-speech.typ": note
#import "../viz/orthogonality.typ": orthogonality-figure
#import "@preview/pinit:0.2.2": absolute-place, simple-arrow

// Подчёркивание термина, подсветку фрагмента формулы и прямую стрелку между ними
// строим по позициям невидимых меток "<key>-src/-start/-end". Подсветку рисуем
// до формулы, поэтому она ложится под чёрный шрифт; стрелку после, поэтому она
// поверх. Ключ key различает два пояснения: pred (предсказание) и upd
// (обновление в форме Джозефа).
#let ul(body) = underline(stroke: 0.6pt + unn-colors.accent-blue, offset: 2pt, body)
#let pos-mark(name) = [#metadata(none)#label(name)]

#let _hl-box(key) = {
  let qa = query(label(key + "-start"))
  let qb = query(label(key + "-end"))
  if qa.len() == 0 or qb.len() == 0 { return none }
  let em = text.size
  let pa = qa.first().location().position()
  let pb = qb.first().location().position()
  (
    x0: pa.x - 0.22 * em,
    x1: pb.x + 0.12 * em,
    top: pa.y - 0.86 * em,
    height: 1.45 * em,
  )
}

#let hl(key) = context {
  let b = _hl-box(key)
  if b != none {
    absolute-place(dx: b.x0, dy: b.top, rect(
      width: b.x1 - b.x0,
      height: b.height,
      fill: unn-colors.orange.transparentize(60%),
      radius: 3pt,
    ))
  }
}

#let hl-arrow(key) = context {
  let b = _hl-box(key)
  let qs = query(label(key + "-src"))
  if b != none and qs.len() > 0 {
    let em = text.size
    let ps = qs.first().location().position()
    // Вертикальная стрелка вниз; x удерживаем в пределах подсветки.
    let x = calc.max(b.x0 + 0.3 * em, calc.min(b.x1 - 0.3 * em, ps.x))
    absolute-place(simple-arrow(
      fill: unn-colors.accent-blue,
      thickness: 1.4pt,
      start: (x, ps.y + 6pt),
      end: (x, b.top),
    ))
  }
}

== Результат 1: корректность шага

#set text(size: 16pt)

Полный шаг:
#ul[предск#pos-mark("pred-src")азание],
затем
#ul[обновление в #pos-mark("upd-src")форме Джозефа],
#hl("pred")
#hl("upd")
$
  #pos-mark("pred-start") P_(k+1|k) = F P_(k|k) F^* + G Q G^* #pos-mark("pred-end") ,
  quad
  #pos-mark("upd-start") P_(k|k) = (E - K H) P_(k|k-1) (E - K H)^* + K R K^* #pos-mark("upd-end") .
$

#hl-arrow("pred")
#hl-arrow("upd")

- Инновационная ковариация $R_(e,k) = H P_(k|k-1) H^* + R$ положительно
  определена при $R succ 0$ (`innov_cov_pd`), отсюда обратима
- Полный шаг фильтра в форме Джозефа сохраняет неотрицательную определённость
  ковариации:

#v(2pt)

#slide-snippet("kalman.v", "kf_step_psd")

#note("r1-step")

== Результат 2: несмещённость

#set text(size: 16pt)

Рекурсия ошибки $err(x) = bold(x) - est(x)$ (управление сокращается):
$
  err(x)_(k+1|k) = F err(x)_(k|k) + G bold(w)_(k+1),
  quad
  err(x)_(k+1|k+1) = err(x)_(k+1|k) - K_(f,k+1) e_(k+1).
$

При шумах с нулевым средним и $EE err(x)_0 = 0$ среднее ошибки остаётся нулевым
на каждом шаге, причём при произвольном усилении наблюдателя:

#slide-snippet("kalman.v", "unbiased", size: 12pt)

#note("r2-unbiased")

== Результат 2: оптимальность

#set text(size: 16pt)

#two-col(
  columns: (1fr, 300pt),
  [
    - `filter_gain_optimal`: усиление Калмана минимизирует след апостериорной
      ковариации среди всех усилений; доказательство ведётся выделением полного
      квадрата
    - `filter_gain_normal_eq`: стационарное условие
      $
        K_k R_(e,k) = P_(k|k-1) H^*
      $
      выражает ортогональность ошибки и инновации
  ],
  align(center + horizon, slide-fig(orthogonality-figure(
    style: (label: 11pt, annot: 10pt),
  ))),
)

#note("r2-optimal")
