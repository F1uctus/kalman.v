#import "../lib.typ": *
#import "../packages/local/textmate/0.1.0/lib.typ": to-sublime-syntax
#import "@preview/codly:1.3.0": *
#show: codly-init

#import "@preview/codly-languages:0.1.10": *
#codly(languages: codly-languages)

#show: phd-appendix

#let rocqSyntax = to-sublime-syntax(json(bytes(read("../assets/rocq.tmLanguage.json"))))
#let source = read("../theories/kalman.v")
#show raw: set text(font: "Iosevka")

= Примеры вставки листингов программного кода <app:A>

#figure(
  raw(
    source,
    lang: "rocq",
    syntaxes: bytes(rocqSyntax),
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
