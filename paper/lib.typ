#import "@preview/unify:0.7.1": *
#import "@preview/codly:1.3.0": *
#import "@preview/tablex:0.0.9": *
#import "@preview/physica:0.9.5": *
#import "@preview/mannot:0.3.3": *
#import "@preview/great-theorems:0.1.2": *
#import "@preview/rich-counters:0.2.2": *
#import "@preview/glossarium:0.5.6": *
#import "common/glossary.typ": *
#import "common/acronyms.typ": *
#import "common/symbols.typ": *
#import "common/fonts.typ": tnr-font
#import "common/rocq.typ": *

#let to-str(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(to-str).join("")
  } else if content.has("body") {
    to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

// Счетчики
#let part_count = counter("parts")
#let total_part = context [#part_count.final().at(0)]
#let appendix_count = counter("appendix")
#let total_appendix = context [#appendix_count.final().at(0)]
#let total_page = context [#counter(page).final().at(0)]
#let total_fig = context [#counter(figure).final().at(0)]
#let total_table = context [#counter(figure.where(kind: table)).final().at(0)]
#let total_bib = context (
  query(selector(ref)).filter(it => it.element == none).map(it => it.target).dedup().len()
)

// Это входная точка - общий шаблон
#let template(
  author-first-name: "Имя Отчество",
  author-last-name: "Фамилия",
  author-group: "И.О.",
  title: "Длинное-длинное название диссертации из достаточно большого количества сложных и непонятных слов",
  city: "Город",
  year: datetime.today().year(),
  organization: [МИНИСТЕРСТВО НАУКИ И ВЫСШЕГО ОБРАЗОВАНИЯ РОССИЙСКОЙ ФЕДЕРАЦИИ],
  in-organization: [Федеральное государственное автономное образовательное учреждение высшего образования "Длинное название образовательного учреждения "АББРЕВИАТУРА"],
  faculty: "Название института или факультета",
  department: "Название кафедры",
  specialty-number: "XX.XX.XX",
  specialty-title: "Название направления подготовки",
  specialty-profile: "Название профиля подготовки",
  supervisor-first-name: "Имя Отчество",
  supervisor-last-name: "Фамилия",
  supervisor-regalia: "уч. степень, уч. звание",
  font-type: tnr-font,
  font-size: 12pt,
  link-color: blue.darken(60%),
  languages: (:),
  logo: "",
  body,
) = {
  // Определение новых переменных
  let author-name = to-str[#author-last-name #author-first-name]
  let supervisor-name = to-str[#supervisor-last-name #supervisor-first-name]

  // Установка свойств к PDF файлу
  set document(author: author-name, title: title)

  // Установки шрифта
  set text(
    font: font-type,
    lang: "ru",
    size: font-size,
    fallback: true,
    hyphenate: false,
  )

  // Установка свойств страницы
  set page(
    // размер полей (ГОСТ 7.0.11-2011, 5.3.7)
    // ННГУ: Правый отступ 15мм
    margin: (top: 2cm, bottom: 2cm, left: 2.5cm, right: 1.5cm),
  )

  // Установка свойств параграфа
  set par(
    justify: true,
    linebreaks: "optimized",
    // Абзацный отступ. Одинаков по всему тексту и равен пяти знакам (ГОСТ Р 7.0.11-2011, 5.3.7).
    first-line-indent: (amount: 2.5em, all: true),
    // Полуторный интервал (ГОСТ 7.0.11-2011, 5.3.6)
    leading: 1em,
  )

  // форматирование заголовков
  set heading(numbering: "1.", outlined: true, supplement: [Раздел])
  show heading: it => {
    set align(center)
    set text(font: font-type, size: font-size)
    // Заголовки отделяют от текста сверху и снизу тремя интервалами (ГОСТ Р 7.0.11-2011, 5.3.5)

    set block(above: 3em, below: 3em)
    if it.level == 1 {
      pagebreak() // новая страница для разделов 1 уровня
      counter(figure).update(0) // сброс значения счетчика рисунков
      counter(math.equation).update(0) // сброс значения счетчика уравнений
    }
    it
  }

  // Отображение ссылок на figure (рисунки и таблицы) - ничего не отображать
  set ref(supplement: it => {
    if it.func() == figure {}
  })

  // Настройка блоков кода
  show: codly-init.with()
  codly.codly(languages: languages)

  // Инициализация глоссария
  show: make-glossary

  register-glossary(acronyms-entries)
  register-glossary(symbols-entries)
  register-glossary(glossary-entries)

  show link: set text(fill: link-color)

  // Нумерация уравнений
  let eq_number(it) = {
    let part_number = counter(heading.where(level: 1)).get()
    part_number
    it
  }
  set math.equation(
    numbering: num => (
      "(" + (counter(heading.where(level: 1)).get() + (num,)).map(str).join(".") + ")"
    ),
    supplement: [Уравнение],
  )

  // Настройка рисунков (only images — theorem/proof figures use great-theorems kinds)
  show figure.where(kind: image): align.with(center)
  set figure(supplement: [Рисунок])
  set figure.caption(separator: [ -- ])
  set figure(numbering: num => (
    (counter(heading.where(level: 1)).get() + (num,)).map(str).join(".")
  ))

  // Настройка таблиц
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: table): set figure(supplement: [Таблица])
  show figure.where(kind: table): set figure(numbering: num => (
    (counter(heading.where(level: 1)).get() + (num,)).map(str).join(".")
  ))
  // Разбивать таблицы по страницам
  show figure: set block(breakable: true)

  // Настройка списков
  set enum(indent: 2.5em)

  state("section").update("body")

  // титульный лист
  set align(center)
  organization
  v(0em)
  in-organization

  v(2em)
  [*#faculty*]

  v(0.5em)
  [*Кафедра: #department*]

  v(1em)
  [Направление подготовки: #specialty-number -- «#specialty-title»]
  v(0em)
  [Профиль подготовки: «#specialty-profile»]

  v(3em)
  set text(size: font-size + 4pt)
  [*ВЫПУСКНАЯ КВАЛИФИКАЦИОННАЯ РАБОТА*]
  v(1em)
  set text(size: font-size + 2pt)
  [Тема: \ *«#title»*]
  set text(size: font-size)

  v(4fr)
  set align(right)
  table(
    columns: 19em,
    stroke: none,
    inset: 1pt,
    align: left,

    [Выполнил:],

    v(0.2em),
    [студент группы #author-group],

    v(0.2em),
    [#author-name],
    v(0em),
    line(length: 100%, stroke: 0.5pt),
    text(size: 10pt)[#align(center)[ф.и.о.]],

    v(1em + 0.2em),
    line(length: 100%, stroke: 0.5pt),
    text(size: 10pt)[#align(center)[подпись]],
  )
  table(
    columns: 19em,
    stroke: none,
    inset: 1pt,
    align: left,

    [Научный руководитель:],

    v(0.2em),
    [#supervisor-regalia, #supervisor-name],
    v(0em),
    line(length: 100%, stroke: 0.5pt),
    text(size: 10pt)[#align(center)[учёная степень, учёное звание, ф.и.о.]],

    v(1em + 0.2em),
    line(length: 100%, stroke: 0.5pt),
    text(size: 10pt)[#align(center)[подпись]],
  )

  v(4em)
  set align(center)
  [#city \ #year]
  set align(left)
  // конец титульной страницы

  set page(
    numbering: "1", // Установка сквозной нумерации страниц
    number-align: center + bottom,
  )
  counter(page).update(1)

  // Содержание
  outline(title: "Содержание", indent: 1.5em, depth: 3)

  body
}

#let mathcounter = rich-counter(
  identifier: "mathblocks",
  inherited_levels: 1,
)

#let mathblock-inset-x = 10pt
#let mathblock-inset = (
  top: 10pt,
  left: mathblock-inset-x,
  right: mathblock-inset-x,
  bottom: 3pt,
)
#let mathblock-number = state("mathblock-number", none)
#let mathblock-title = state("mathblock-title", none)

#let mathblock-code-bleed(body) = {
  show block.where(width: 100%): it => {
    pad(left: -mathblock-inset-x, right: -mathblock-inset-x)[#it]
  }
  body
}

#let mathblock-head(head-label, titlix, body) = {
  mathblock-code-bleed(context {
    let title = mathblock-title.get()
    [
      #set par(first-line-indent: 0pt)
      *#head-label #mathblock-number.get().*
      #if title != none {
        titlix(title)
      }
      #body
    ]
  })
}

#let make-counted-mathblock(
  head-label,
  blocktitle: none,
  titlix: t => emph[(#t):],
  ..block-args,
) = {
  let blocktitle = if blocktitle != none { blocktitle } else { head-label }
  let env = mathblock(
    blocktitle: blocktitle,
    counter: mathcounter,
    titlix: _ => [],
    prefix: number => {
      mathblock-number.update(number)
      []
    },
    bodyfmt: body => mathblock-head(head-label, titlix, body),
    inset: mathblock-inset,
    clip: true,
    ..block-args,
  )
  (title: none, ..call-args, body) => {
    mathblock-title.update(title)
    env(title: none, ..call-args, body)
  }
}

#let make-uncounted-mathblock(head-label, titlix: t => emph[(#t):], ..block-args) = {
  let env = mathblock(
    blocktitle: head-label,
    titlix: _ => [],
    prefix: [],
    bodyfmt: body => mathblock-code-bleed(context {
      let title = mathblock-title.get()
      [
        *#head-label.*
        #if title != none { titlix(title) }
        #body
        #v(-1em, weak: true)
      ]
    }),
    inset: mathblock-inset,
    clip: true,
    ..block-args,
  )
  (title: none, ..call-args, body) => {
    mathblock-title.update(title)
    env(title: none, ..call-args, body)
  }
}

#let theorem = make-counted-mathblock(
  "Теорема",
  radius: 5pt,
  stroke: rgb(200, 200, 200),
)
#let lemma = make-counted-mathblock(
  "Лемма",
  radius: 5pt,
  stroke: gray + 0.3pt,
)
#let statement = make-counted-mathblock(
  "Утверждение",
  radius: 5pt,
  stroke: rgb(200, 200, 200),
)
#let corollary = make-uncounted-mathblock(
  "Следствие",
  radius: 5pt,
  stroke: rgb(200, 200, 200),
)
#let remark = make-uncounted-mathblock(
  "Замечание",
)
#let definition(name: "", ..args) = make-counted-mathblock(
  "Определение",
  titlix: t => [_ #t: #(math.thick) _],
  radius: 5pt,
  stroke: gray + 0.3pt,
  breakable: false,
)(..args)
#let proof = proofblock(
  prefix: [_Доказательство._],
)
#let proofsketch = proofblock(
  prefix: [_Схема доказательства._],
)

#let hl-r(x) = text(fill: red, $#x$)
#let hl-g(x) = text(fill: rgb("#298E89"), $#x$)
#let half = h(0.5em)
#let eq-no-num = math.equation.with(
  block: true,
  numbering: none,
)

// Set up the styling of the appendix.
#let phd-appendix(body) = {
  // Reset the title numbering.
  counter(heading).update(0)

  // Number headings using letters.
  show heading.where(level: 1): set heading(numbering: "Приложение A. ", supplement: [Приложение])
  show heading.where(level: 2): set heading(numbering: "A.1 ", supplement: [Приложение])

  // Set the numbering of the figures.
  set figure(numbering: x => context {
    let idx = numbering("A", counter(heading).get().first())
    [#idx.#numbering("1", x)]
  })

  // Additional heading styling to update sub-counters.
  show heading: it => {
    appendix_count.step() // Обновление счетчика приложений
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: math.equation)).update(0)
    counter(figure.where(kind: raw)).update(0)

    it
  }

  // Set that we're in the annex
  state("section").update("annex")

  body
}
