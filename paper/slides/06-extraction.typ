// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../slides-speech.typ": note
#import "../viz/kalman-run.typ": kalman-run-figure
#import "../viz/kalman-run-3d.typ": kalman-run-3d-figure

== 5. Извлечение исполняемого кода

#set text(size: 16pt)

- Матрицы определяются библиотекой CoqEAL как двумерные массивы. Почти
  тривиальными леммами доказывается совпадение определений ДАУР над такими
  матрицами с определениями, удобными для доказательств;
- Общий алгоритм обращения матриц через метод Фаддеева-Леверье формализован с
  конструктивным доказательством корректности;
- Код извлечён в язык #OCaml, что даёт возможность использования во встроенном
  ПО.

#trust-chain(
  [Спецификация \ #Rocq],
  [Код \ #OCaml],
  [Данные \ {...}],
  [Графики \ Typst],
)

#align(center, pill(
  [Все графики этой работы построены извлечённым проверенным кодом],
  fill: unn-colors.green,
  text-fill: unn-colors.primary,
))

#note("r5-extract")

== Эксперимент: движение в одномерном пространстве

#set text(size: 14pt)

#slide-fig(
  kalman-run-figure(style: slide-viz, size: (9, 3.6), dir: ltr),
  max-h: 190pt,
)

Прогон извлечённого фильтра: все данные, включая возмущения (модель возмущений
со свойствами белого шума, генератор Лемера псевдослучайных чисел), построены
извлечённой программой; вхождение ошибки в окрестность $plus.minus 2 sigma_k$
формализовано в виде отдельной леммы.

#note("r5-exp")

== Эксперимент: движение в трёхмерном пространстве

#set text(size: 14pt)

#two-col(
  columns: (1fr, 400pt),
  [
    Показан первый виток оценки винтовой траектории фильтром; окрестность
    $plus.minus 2 sigma_k$ по каждой координате доказан отдельной леммой.
  ],
  align(center + horizon, slide-fig(
    kalman-run-3d-figure(style: slide-viz),
    max-h: 214pt,
  )),
)

