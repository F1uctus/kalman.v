// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../slides-speech.typ": note
#import "../viz/lyapunov.typ": lyapunov-figure
#import "../viz/riccati-monotone.typ": riccati-monotone-figure
#import "../viz/dare-cone.typ": dare-cone-figure

== 4.1. Топология, пределы и монотонность

#set text(size: 13pt)

#two-col(
  columns: (1fr, 225pt),
  [
    - Матрицы образуют конечномерное нормированное пространство: топология не
      зависит от нормы, сходимость равносильна сходимости по норме Фробениуса.


    - Монотонная ограниченная последовательность эрмитовых матриц сходится.

    - Дискретное уравнение Ляпунова $X = A X A^* + Q$ решается степенным рядом;
      решение единственно при устойчивой $A$.

    - Итерация уравнения из $P_0 = 0$ не убывает в порядке Лёвнера.

    - Детектируемость даёт равномерную мажоранту траектории: решение уравнения
      Ляпунова при фиксированном стабилизирующем усилении.
  ],
  align(center + horizon, stack(
    spacing: 8pt,
    slide-fig(lyapunov-figure(style: slide-viz), max-h: 100pt),
    slide-fig(riccati-monotone-figure(style: slide-viz), max-h: 100pt),
  )),
)

#note("r4-topo")
#note("r4-mono")

== 4.2. Решение ДАУР

#set text(size: 16pt)

#two-col(
  columns: (1fr, 300pt),
  [
    Схема области сходимости на конусе неотрицательно определённых матриц:
    $
      0 = P_0 prec.eq P_1 prec.eq dots.c prec.eq P_"bnd"
    $

    - Предел существует и решает ДАУР (`dare_psd_sol`)
    - Управляемость пары $(F, G Q G^*)$ даёт $P_ss succ 0$ (`Pss_pd`)
    - Решение единственно среди положительно определённых (`Pss_unique_pd`)
    - Итог: `dare_stabilizing_sol`
  ],
  align(center + horizon, slide-fig(
    dare-cone-figure(style: slide-viz, panels: ("a",)),
  )),
)

#note("r4-dare")
