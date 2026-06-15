// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../viz/orthogonality.typ": orthogonality-figure

== Результат 1: корректность шага

#set text(size: 16pt)

Полный шаг: предсказание, затем обновление в форме Джозефа,
$
  P_(k+1|k) = F P_(k|k) F^* + G Q G^*,
  quad
  P_(k|k) = (E - K H) P_(k|k-1) (E - K H)^* + K R K^*.
$

- Инновационная ковариация $R_(e,k) = H P_(k|k-1) H^* + R$ положительно
  определена при $R succ 0$ (`innov_cov_pd`), отсюда обратима
- Форма Джозефа сохраняет неотрицательную определённость ковариации:

#v(2pt)

#slide-snippet("kalman.v", "kf_step_psd")

== Результат 2: несмещённость

#set text(size: 16pt)

Рекурсия ошибки $err(x) = bold(x) - est(x)$ (управление сокращается):
$
  err(x)_(k+1|k) = F err(x)_(k|k) + G bold(w)_(k+1),
  quad
  err(x)_(k+1|k+1) = err(x)_(k+1|k) - K_(f,k+1) e_(k+1).
$

При шумах с нулевым средним и $EE err(x)_0 = 0$ среднее ошибки остаётся нулевым
на каждом шаге, причём при произвольном усилении наблюдателя:

#slide-snippet("kalman.v", "unbiased", size: 12pt)

== Результат 2: оптимальность

#set text(size: 16pt)

#two-col(
  columns: (1fr, 300pt),
  [
    - `filter_gain_optimal`: усиление Калмана минимизирует след апостериорной
      ковариации среди всех усилений; доказательство ведётся выделением полного
      квадрата
    - `filter_gain_normal_eq`: стационарное условие
      $
        K_k R_(e,k) = P_(k|k-1) H^*
      $
      выражает ортогональность ошибки и инновации
  ],
  align(center + horizon, slide-fig(orthogonality-figure(
    style: (label: 11pt, annot: 10pt),
  ))),
)
