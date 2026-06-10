#import "lib.typ": *
#import "../viz/gramian.typ": gramian-figure
#import "../viz/duality-mirror.typ": duality-mirror-figure

== Результат 3: наблюдаемость и управляемость

#set text(size: 16pt)

#two-col(
  columns: (1fr, 270pt),
  [
    - Ранговые критерии: пара $(H, F)$
      наблюдаема, пара $(F, G)$ управляема,
      если соответствующие блочные матрицы
      имеют полный ранг $n$
    - Грамианы дают конструктивную форму:
      суммы неотрицательно определённых
      слагаемых
    - При наблюдаемости грамиан из $n$
      слагаемых положительно определён
      (`obsv_gram_pd_of_observable`),
      симметрично для управляемости
  ],
  align(center + horizon, slide-fig(gramian-figure())),
)

== Результат 3: детектируемость и двойственность

#set text(size: 16pt)

#two-col(
  columns: (1fr, 250pt),
  [
    - Спектральный критерий PBH: достаточно
      контролировать собственные направления
      на единичной окружности и вне её
    - `detectable_stabilizing`: детектируемость
      даёт стабилизирующее усиление
      наблюдателя
    - Двойственность оценивания и управления:
      `stabilizable_dual`, `ctrl_gram_dual`
      переносят факты между парами
      $(H, F)$ и $(F^*, H^*)$
  ],
  align(center + horizon, slide-fig(duality-mirror-figure)),
)
