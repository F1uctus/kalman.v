// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Защитная презентация ВКР. Сборка:
//   TYPST_PACKAGE_PATH=paper/packages typst compile paper/slides.typ \
//     paper/slides.pdf --root . --package-path paper/packages

#import "slides/lib.typ": *
#import "slides-speech.typ": note

#show: unn-theme.with(config-info(
  title: [Формальная верификация фильтра Калмана и его свойств],
  subtitle: [Выпускная квалификационная работа бакалавра],
  author: [студент гр. 3822Б1МА1 И.И. Никитин],
  supervisor: [Ph.D., доцент кафедры АГиДМ \ Е.М. Макаров],
  specialty: [01.03.01 Математика],
  program: [Общий профиль],
  // TODO: Уточнить дату защиты перед печатью.
  date: datetime(year: 2026, month: 6, day: 18),
))

#show: codly-init.with()
#show "†": math.attach("", tr: sym.ast)
#show: show-markup-shorthands

#title-slide()

#note("title")

#include "slides/01-intro.typ"
#include "slides/02-model.typ"
#include "slides/03-correctness.typ"
#include "slides/04-structure.typ"
#include "slides/05-asymptotics.typ"
#include "slides/06-extraction.typ"
#include "slides/07-conclusion.typ"

#thanks-slide(
  contact: [github.com/F1uctus/kalman.v],
  qr: "https://github.com/F1uctus/kalman.v",
)

#note("thanks")

// Резервные слайды.
#show: appendix

#include "slides/90-backup.typ"
