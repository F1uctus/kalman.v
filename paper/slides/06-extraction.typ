#import "lib.typ": *
#import "../viz/kalman-run.typ": kalman-run-figure

== Результат 5: извлечение исполняемого кода

#set text(size: 16pt)

- Уточнения CoqEAL: исполняемый шаг над списочными матрицами совпадает со
  спецификацией (`riccati_step_seqmx_correct`, `riccati_iter_seqmx_correct`)
- Обращение матрицы: метод Фаддеева-Леверье, с конструктивным доказательством
  корректности (`fl_inv_correct`)
- Код извлечён в #OCaml#[;] параметры модели остаются аргументами функций

#v(10pt)

#trust-chain(
  [Спецификация \ #Rocq],
  [Код \ #OCaml],
  [Данные],
  [Графики],
)

#pause
#v(10pt)

#align(center, pill(
  [Все графики этой работы построены извлечённым проверенным кодом],
  fill: unn-colors.green,
  text-fill: unn-colors.primary,
))

== Эксперимент

#set text(size: 15pt)

#slide-fig(
  kalman-run-figure(style: slide-viz, size: (6.2, 3.6), dir: ltr),
  max-h: 190pt,
)

#set text(size: 14pt)
Прогон извлечённого фильтра: все данные, включая шумы (четырёхточечная модель,
генератор Лемера внутри Rocq), построены извлечённой программой; вхождение
ошибки в коридор $plus.minus 2 sigma_k$ доказано леммой `sim_run_in_band`.
