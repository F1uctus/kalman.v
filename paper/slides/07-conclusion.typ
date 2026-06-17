// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../slides-speech.typ": note

== Выводы

#set text(size: 14pt)

#results-progress(done: (0, 1, 2, 3, 4))

#v(6pt)

+ Шаги фильтра сохраняют эрмитовость и неотрицательную определённость
  ковариации; инновационная ковариация обратима
+ Оценка несмещена при любом усилении; усиление Калмана оптимально в порядке
  Лёвнера
+ Формализованы ранговые критерии, грамианы, PBH, детектируемость,
  двойственность
+ Доказаны существование, единственность, устойчивость решения ДАУР, глобальная
  сходимость с оценкой $epsilon$--$N$
+ Исполняемый код связан со спецификацией уточнениями CoqEAL и извлечён в #OCaml

#v(2pt)

Перспективы: фильтры на пространствах Крейна, непрерывный фильтр Калмана-Бьюси,
численная устойчивость, нелинейные расширения.

#note("concl")

== Литература

#set text(size: 14pt)
#set par(hanging-indent: 18pt)

+ Kalman R. E. A New Approach to Linear Filtering and Prediction Problems \/\/
  Journal of Basic Engineering. 1960. Vol. 82, no. 1. P. 35--45.
+ Kailath T., Sayed A. H., Hassibi B. Linear Estimation. Upper Saddle River, NJ:
  Prentice Hall, 2000. 854 p.
+ Wonham W. M. Linear Multivariable Control: A Geometric Approach. New York:
  Springer, 1985. 334 p.
+ Mahboubi A., Tassi E. Mathematical Components. Zenodo, 2021. 183 p.
+ Zhou L., Barthe G., Strub P.-Y., Liu J., Ying M. CoqQ: Foundational
  Verification of Quantum Programs \/\/ Proceedings of the ACM on Programming
  Languages. 2023. Vol. 7, POPL. P. 833--865.
+ Dénès M., Mörtberg A., Siles V. A Refinement-Based Approach to Computational
  Algebra in Coq \/\/ Interactive Theorem Proving. 2012. P. 83--98.

#note("refs")
