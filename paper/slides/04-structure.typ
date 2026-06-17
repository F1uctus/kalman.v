// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../slides-speech.typ": note
#import "../viz/gramian.typ": gramian-figure
#import "../viz/duality-mirror.typ": duality-mirror-figure

== Результат 3: наблюдаемость и управляемость

#set text(size: 16pt)

#two-col(
  columns: (1fr, 270pt),
  [
    - Критерии на ранг: пара $(H, F)$ наблюдаема, а пара $(F, G)$ управляема,
      если соответствующие блочные матрицы имеют полный ранг $n$
    - Грамианы определяются конструктивно как суммы неотрицательно определённых
      слагаемых
    - При наблюдаемости грамиан из $n$ слагаемых положительно определён. Это же
      справедливо и для управляемости
  ],
  align(center + horizon, slide-fig(gramian-figure(
    style: (..slide-viz, label: 17pt, annot: 14pt),
  ))),
)

#note("r3-obsv")

== Результат 3: детектируемость и двойственность

#set text(size: 16pt)

#two-col(
  columns: (1fr, 300pt),
  [
    - Спектральный критерий PBH: достаточно контролировать собственные
      направления на единичной окружности и вне её
    - `detectable_stabilizing`: детектируемость даёт стабилизирующее усиление
      наблюдателя
    - Двойственность оценивания и управления: `stabilizable_dual`,
      `ctrl_gram_dual` связывают факты между $(H, F)$ и $(F^*, H^*)$
  ],
  align(center + horizon, slide-fig(
    duality-mirror-figure(
      style: slide-viz,
      xcol: 4.4,
    ),
  )),
)

#note("r3-dual")
