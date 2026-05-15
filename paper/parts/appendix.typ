#import "../lib.typ": *

#show: phd-appendix

= Примеры вставки листингов программного кода <app:A>

#figure(
  raw(
    rocq-src("kalman.v"),
    lang: "rocq",
    syntaxes: bytes(rocq-syntax),
    theme: "../assets/rocq.tmTheme",
    block: true,
  ),
  caption: [Листинг программного кода на языке программирования Rocq],
)

= Очень длинное название второго приложения, в~котором продемонстрирована работа с~длинными таблицами <app:B>

== Подраздел приложения <app:B2>

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr),
    table.header([*Заголовок 1*], [*Заголовок 2*], [*Заголовок 3*], [*Заголовок 4*]),
    ..for x in range(1, 50) {
      ([#x], [#x], [#x], [#x])
    },
  ),
  caption: [Очень длинное название таблицы],
)
