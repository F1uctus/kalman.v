#import "lib.typ": *
#import "../viz/kalman-run.typ": kalman-run-figure

== Результат 5: извлечение исполняемого кода

#set text(size: 16pt)

- Уточнения CoqEAL: исполняемый шаг над списочными матрицами совпадает
  со спецификацией (`riccati_step_seqmx_correct`,
  `riccati_iter_seqmx_correct`)
- Обращение матрицы: метод Фаддеева и Леверье, доказанный корректным
  (`fl_inv_correct`)
- Код извлечён в OCaml; параметры модели остаются аргументами функций

#v(10pt)

#trust-chain(
  [спецификация \ #Rocq],
  [код \ OCaml],
  [данные \ JSON],
  [графики \ Typst],
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

#slide-fig(kalman-run-figure(), s: 0.9, max-h: 185pt)

#v(2pt)

Прогон извлечённого фильтра: ошибка оценки остаётся в коридоре
$plus.minus 2 sigma_k$, ширина коридора задана извлечённой ковариацией
Риккати и выходит на стационар.
