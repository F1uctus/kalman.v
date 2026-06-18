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
#let ul(body) = underline(
  stroke: 0.6pt + unn-colors.accent-blue,
  offset: 2pt,
  body,
)
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

== 1. Определение шага фильтра и его корректность

#set text(size: 15pt)

_Эрмитова конгруэнция по матрице $M$_: $P |-> M P M^*$.

Полный шаг: #ul[предска#pos-mark("pred-src")зание], затем #ul[обновление (в
  числен#pos-mark("upd-src")но устойчивой _форме Джозефа_)],
#hl("pred")
#hl("upd")
$
  #pos-mark("pred-start") P_(k+1|k) = F P_(k|k) F^* + G Q G^* #pos-mark("pred-end") ,
  quad
  #pos-mark("upd-start") P_(k|k) = (E_n - K H) P_(k|k-1) (E_n - K H)^* + K R K^* #pos-mark("upd-end") .
$

#hl-arrow("pred")
#hl-arrow("upd")

- Инновационная ковариация $R_(e,k) = H P_(k|k-1) H^* + R succ 0$ при
  $R succ 0$, а значит обратима.

- Полный шаг фильтра сохраняет неотрицательную определённость ковариации:

$
  // hat(bold(x))_(k+1|k) = F hat(bold(x))_(k|k) + G bold(u)_k,
  // quad hat(bold(x))_(k+1|k+1)
  // = hat(bold(x))_(k+1|k) + K (bold(y)_(k+1) - H hat(bold(x))_(k+1|k)),
  // \
  P_(k|k) succ.eq 0
  thick => thick
  P_(k+1|k+1) = (E_n - K H) P_(k+1|k) (E_n - K H)^* + K R K^* succ.eq 0,
  thick "где" K = P_(k|k-1) H† R_(e,k)^(-1).
$

#slide-snippet("kalman.v", "kf_step_psd")

#note("r1-step")

== 2.1. Несмещённость ошибки оценивания

#set text(size: 16pt)

Рекурсия ошибки оценки $err(x) = bold(x) - est(x)$ (слагаемое с вектором
управления сокращается):
$
  err(x)_(k+1|k) = F err(x)_(k|k) + G bold(w)_(k+1),
  quad
  err(x)_(k+1|k+1) = err(x)_(k+1|k) - K_(f,k+1) e_(k+1),
  quad "где"
  quad e_(k+1) = bold(y)_(k+1) - H hat(bold(x))_(k+1|k), \
  quad K_(f,k+1) = P_(k+1|k) H^* R_(e,k+1)^(-1),
  quad R_(e,k+1) = H P_(k+1|k) H^* + R.
$

При возмущениях с нулевым средним и $EE err(x)_0 = 0$ среднее значение ошибки
остаётся $=0$ на каждом шаге, причём при любой послед. ${P_(k|k)}$, а значит и
при любом усилении $K$:

#slide-snippet("kalman.v", "unbiased")

#note("r2-unbiased")

== 2.2. Оптимальность матрицы $K_(f,k)$ (усиления Калмана)

#set text(size: 14pt)

#two-col(
  columns: (1fr, 250pt),
  [
    #set text(hyphenate: true)
    - $""
      forall K: P_(k|k)(K) = K R_(e,k) K^* - K H P_(k|k-1) - P_(k|k-1) H^* K^*
      + P_(k|k-1).$
      Выделение полного квадрата по $K$ (аналог
      $a x^2 - 2 b x = a (x - b/a)^2 - b^2/a$, здесь $a = R_(e,k)$):
      $ P_(k|k)(K) = (K - K_(f,k)) R_(e,k) (K - K_(f,k))^* + P_(k|k)(K_(f,k)). $
      Квадрат $succ.eq 0$ и $= 0$ лишь при
      $K = K_(f,k) = P_(k|k-1) H^* R_(e,k)^(-1)$; усиление Калмана минимизирует
      ковариацию (а с ней и след).

    - Условие стационарности $K_k R_(e,k) = P_(k|k-1) H^*$ равносильно
      $EE[err(x)_(k|k) e_k^*] = 0$: ошибка не коррелирует с инновацией. Это
      означает, что из наблюдения извлечено всё что можно, а оценка $hat(x)$
      есть ортогональная проекция состояния $x$ на подпространство наблюдений
      $cal(Y)$.
  ],
  align(center + horizon, slide-fig(orthogonality-figure(
    style: (label: 14pt, annot: 14pt),
  ))),
)

#note("r2-optimal")
