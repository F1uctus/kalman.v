// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../slides-speech.typ": note
#import "../viz/spectral.typ": spectral-figure
#import "../viz/duality-spectral.typ": duality-spectral-figure
#import "../viz/schur-stability.typ": schur-stability-figure
#import "../viz/dare-epsn.typ": dare-epsn-figure

== Антимонотонность обращения

#set text(size: 16pt)

#two-col(
  columns: (1fr, 300pt),
  [
    - Спектральная теорема для эрмитовых матриц (`spectral_decomp`)
    - Обращение антимонотонно относительно порядка Лёвнера (`pd_inv_antimono`):
      из $A prec.eq B$ следует
      $B^(-1) prec.eq A^(-1)$
    - Используется в доказательствах единственности решения ДАУР
  ],
  align(center + horizon, slide-fig(spectral-figure())),
)

#note("backup-antimono")

== 4. Устойчивость контура

#set text(size: 16pt)

#two-col(
  columns: (1fr, 280pt),
  [
    - Замкнутый контур $F_p = F - K_p H$ устойчив по Шуру: спектр строго внутри
      единичного круга (`Fp_schur`)
    - Отсюда нормы степеней $F_p^k$ убывают геометрически, и возмущения
      начального состояния становятся пренебрежимо малы
  ],
  align(center + horizon, slide-fig(schur-stability-figure(
    style: (
      ..slide-viz,
      label: 18pt,
      tick: 13pt,
      legend: 14pt,
      subcaption: 15pt,
    ),
    dir: ttb,
  ))),
)

#note("r4-schur")

== 4. Количественная сходимость

#set text(size: 16pt)

#two-col(
  columns: (1fr, 280pt),
  [
    - Глобальная сходимость из любого неотрицательно определённого $P_0$
    - Форма $epsilon$--$N$ по норме Фробениуса (`kalman_filter_frob_cvgn`):
      $
        forall epsilon > 0 thick exists N(epsilon):
        quad
        norm(P_k - P_ss)_F < epsilon
      $
      при $k >= N(epsilon)$; то же для усиления
      $K_k -> K_ss$
    - Свойство перенесено на ковариацию работающего фильтра над любыми потоками
      входов и измерений
  ],
  align(center + horizon, slide-fig(dare-epsn-figure(
    style: (..slide-viz, label: 16pt, tick: 13pt, subcaption: 14pt),
    dir: ttb,
    exponents: (-2, -6),
  ))),
)

#note("r4-epsn")

== Двойственность

#set text(size: 15pt)

#slide-fig(duality-spectral-figure(style: slide-viz), max-h: 165pt)

#v(2pt)

Спектры замкнутых контуров наблюдателя и регулятора совпадают: двойственность
переносит устойчивость между задачами оценивания и управления.

#note("backup-duality")

== Пример ДАУР

#set text(size: 16pt)

- Скалярное ДАУР из $P_0 = 1$ даёт последовательность
  $1 -> 5\/6 -> 13\/16$
- Значение вычислено `vm_compute` внутри #Rocq и связано со спецификацией
  уточнением `ex_iter_correct`

#v(4pt)

#slide-snippet("seqmx/riccati_seqmx.v", "ex_two_val", proof: true)

#note("backup-dare-ex")

== Информационная форма

#set text(size: 16pt)

- Обновление ковариации допускает запись через обратные матрицы (информационная
  форма); из неё немедленно следует обратимость апостериорной ковариации

#v(4pt)

#slide-snippet("kalman.v", "update_cov_information_form")

#note("backup-info")

== Ограничения извлечения

#set text(size: 16pt)

- Стационарное $P_ss$ невычислимо как предел: берётся конечная итерация
  `riccati_step` до приемлемости невязки неподвижной точки
- Прогон фильтра формализован целиком: шумы из четырёхточечной модели и
  генератор Лемера определены внутри Rocq, вхождение ошибки в коридор
  $plus.minus 2 sigma_k$ доказано (`sim_run_in_band`)
- Параметры модели $F, G, H, Q, R, P_0$ остаются аргументами извлечённых
  функций: настройка на этапе вызова
- Подход через CoqEAL не зависит от внешнего экстрактора и даёт формализованное
  соответствие спецификации и кода

#note("backup-limits")

== Соответствие теорем и файлов

#set text(size: 11pt)

#table(
  columns: (1fr, auto, auto),
  inset: (x: 8pt, y: 3pt),
  stroke: unn-colors.panel + 1pt,
  fill: (x, y) => if y == 0 { unn-colors.panel-light },
  table.header([Свойство], [Утверждение], [Файл]),
  [Инвариант шага фильтра], `kf_step_psd`, `kalman.v`,
  [Несмещённость], `unbiased`, `kalman.v`,
  [Оптимальность усиления], `filter_gain_optimal`, `kalman.v`,
  [Грамиан и наблюдаемость], `obsv_gram_pd_of_observable`, `obsv_bound.v`,
  [Двойственность], `stabilizable_dual`, `ctrl_gram_dual`,
  `duality.v`, [Уравнение Ляпунова], `lyap_sol`,
  `lyap_sol_unique`, `lyapunov.v`, [Решение ДАУР],
  `dare_stabilizing_sol`, `Pss_unique_pd`, `dare.v`,
  [Устойчивость контура], `Fp_schur`, `dare.v`,
  [Сходимость фильтра], `kalman_filter_frob_cvgn`, `dare.v`,
  [Уточнения CoqEAL], `riccati_iter_seqmx_correct`, `riccati_seqmx.v`,
  [Обращение матрицы], `fl_inv_correct`, `faddeev.v`,
)

Профиль аксиом ключевых теорем: три аксиомы модуля `boolp` библиотеки mathcomp и
назначение полюсов (`pole_placement_detect`).

#note("backup-table")
