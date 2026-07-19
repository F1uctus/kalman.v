// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *

#show: template.with(
  organization: "МИНИСТЕРСТВО НАУКИ И ВЫСШЕГО ОБРАЗОВАНИЯ РОССИЙСКОЙ ФЕДЕРАЦИИ",
  in-organization: [
    Федеральное государственное автономное образовательное учреждение \ высшего
    образования \ *"Национальный исследовательский \ Нижегородский
    государственный университет им. Н.И. Лобачевского" \ (ННГУ)*
  ],
  faculty: "Институт информационных технологий, математики и механики",
  department: "Алгебры, геометрии и дискретной математики",
  specialty-number: "01.03.01",
  specialty-title: "Математика",
  specialty-profile: "Общий профиль",

  title: "Формальная верификация фильтра Калмана и его свойств",

  author-group: "3822Б1МА1",
  author-last-name: "Никитин",
  author-first-name: "Илья Иванович",
  supervisor-regalia: "Ph.D., доцент кафедры АГиДМ ИИТММ ННГУ",
  supervisor-last-name: "Макаров",
  supervisor-first-name: "Евгений Маратович",

  city: "Нижний Новгород",
)

#show heading.where(level: 1): set heading(numbering: "Глава 1.")
#show: great-theorems-init

// Основные части документа
#include "./parts/intro.typ"

#include "./parts/part1.typ"

#include "./parts/part2.typ"

#include "./parts/part3.typ"

#include "./parts/part4.typ"

#include "./parts/part5.typ"

// Выключить нумерацию выходных данных
#show heading: set heading(numbering: none)

// Заключение
#include "./parts/conclusion.typ"

// Выходные данные
// = Список сокращений и условных обозначений
// #import "./common/acronyms.typ": acronyms-entries
// #import "./common/symbols.typ": symbols-entries
// #print-glossary()

//= Словарь терминов
//#import "./common/glossary.typ": glossary-entries
//#print-glossary(glossary-entries)

// Остальные источники из external.bib, не упомянутые в тексте напрямую.
// form: none помещает запись в список литературы без видимой ссылки и
// сохраняет нумерацию уже процитированных источников.
#{
  cite(<welch2006>, form: none)
  cite(<affeldt2023>, form: none)
  cite(<mathcomp2022>, form: none)
  cite(<stoorvogel1994>, form: none)
  cite(<mo2015>, form: none)
  cite(<mathlib2021>, form: none)
  cite(<wikipedia2026>, form: none)
  cite(<bernard2017>, form: none)
  cite(<balonin2015>, form: none)
}

#bibliography(
  title: "Список литературы",
  ("./common/external.bib", "./common/author.bib"),
  style: "gost-r-705-2008-numeric",
)

// #show outline: set heading(outlined: true)

// #outline(title: "Список рисунков", target: figure.where(kind: image))

// #outline(title: "Список таблиц", target: figure.where(kind: table))

// Приложения
#include "./parts/appendix.typ"

#metadata("thesis-end") <thesis-end>

// Проверка заморозки печатной раскладки.
// Отключается флагом --input assert-pages=off (используется thesis-lint).
#context {
  if sys.inputs.at("assert-pages", default: "on") != "off" {
    let heads = query(heading.where(level: 1))
    let pages = heads.map(h => h.location().page())
    let frozen = (2, 4, 5, 6, 13, 20, 27, 37, 66, 74, 75)
    let total = query(<thesis-end>).first().location().page()
    let frozen-total = 75
    let msg = (
      "Печатная раскладка сместилась."
      + " Число страниц: " + str(total)
      + " (ожидалось " + str(frozen-total) + ")."
      + " Начала разделов первого уровня: " + repr(pages)
      + " (ожидалось " + repr(frozen) + ")."
      + " Для принятия новой раскладки запустите thesis-lint --update."
    )
    assert(pages == frozen and total == frozen-total, message: msg)
  }
}
