#import "lib.typ": *
#import "../viz/lyapunov.typ": lyapunov-figure
#import "../viz/riccati-monotone.typ": riccati-monotone-figure
#import "../viz/dare-cone.typ": dare-cone-figure
#import "../viz/schur-stability.typ": schur-stability-figure
#import "../viz/dare-epsn.typ": dare-epsn-figure

== Результат 4: топология и пределы

#set text(size: 16pt)

#two-col(
  columns: (1fr, 280pt),
  [
    - Сходимость матриц по норме Фробениуса; монотонная ограниченная
      последовательность эрмитовых матриц сходится (`mx_mono_cvgn`)
    - Дискретное уравнение Ляпунова $X = A X A^* + Q$ решается в виде степенного
      ряда (`lyap_sol`); решение единственно при устойчивости $A$
  ],
  align(center + horizon, slide-fig(lyapunov-figure(style: slide-viz))),
)

== Результат 4: монотонность Риккати

#set text(size: 16pt)

#two-col(
  columns: (1fr, 280pt),
  [
    - Итерация Риккати из $P_0 = 0$ монотонно не убывает в порядке Лёвнера
      (`riccati_iter0_mono`)
    - Детектируемость даёт равномерную верхнюю границу траектории: решение
      уравнения Ляпунова с фиксированным стабилизирующим усилением
  ],
  align(center + horizon, slide-fig(riccati-monotone-figure(
    style: slide-viz,
  ))),
)

== Результат 4: решение ДАУР

#set text(size: 16pt)

#two-col(
  columns: (1fr, 300pt),
  [
    Схема области сходимости на конусе неотрицательно определённых матриц:
    $
      0 = P_0 prec.eq P_1 prec.eq dots.c prec.eq P_"bnd"
    $

    - Предел существует и решает ДАУР (`dare_psd_sol`)
    - Управляемость пары $(F, G Q G^*)$ даёт $P_(s s) succ 0$ (`Pss_pd`)
    - Решение единственно среди положительно определённых (`Pss_unique_pd`)
    - Итог: `dare_stabilizing_sol`
  ],
  align(center + horizon, slide-fig(dare-cone-figure(
    style: slide-viz,
    dir: ttb,
  ))),
)

== Результат 4: устойчивость контура

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
    style: (..slide-viz, label: 18pt, tick: 13pt, legend: 14pt, subcaption: 15pt),
    dir: ttb,
  ))),
)

== Результат 4: количественная сходимость

#set text(size: 16pt)

#two-col(
  columns: (1fr, 280pt),
  [
    - Глобальная сходимость из любого неотрицательно определённого $P_0$
    - Форма $epsilon$--$N$ по норме Фробениуса (`kalman_filter_frob_cvgn`):
      $
        forall epsilon > 0 thick exists N(epsilon):
        quad
        norm(P_k - P_(s s))_F < epsilon
      $
      при $k >= N(epsilon)$; то же для усиления
      $K_k -> K_(s s)$
    - Свойство перенесено на ковариацию работающего фильтра над любыми потоками
      входов и измерений
  ],
  align(center + horizon, slide-fig(dare-epsn-figure(
    style: (..slide-viz, label: 16pt, tick: 13pt, subcaption: 14pt),
    dir: ttb,
  ))),
)
