// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../slides-speech.typ": note
#import "../viz/observer-block.typ": observer-block-figure

== Модель и оптимальный наблюдатель

#set text(size: 16pt)

#two-col(
  columns: (340pt, 1fr),
  [
    #set text(size: 14pt, hyphenate: true)

    Два уравнения, состояния и наблюдения:
    $
      bold(x)_(k+1) & = F bold(x)_k + G bold(u)_k + G bold(w)_(k+1), \
          bold(y)_k & = H bold(x)_k + bold(v)_k.
    $

    Возмущения с нулевым средним и заданными ковариациями:
    $""
    EE bold(w)_j bold(w)_k^* = Q delta_(j k) succ.eq 0,
    EE bold(v)_j bold(v)_k^* = R delta_(j k) succ 0.
    ""$

    После наблюдения $bold(y)_k$ правим оценку:
    $""
    hat(bold(x))_(k|k) = hat(bold(x))_(k|k-1)
    + K (bold(y)_k - H hat(bold(x))_(k|k-1)).
    ""$
    $K$ ищем из условия минимальности ковариации ошибки оценки
    $P_(k|k) = EE err(x)_(k|k) err(x)_(k|k)^*$ после поправки. Матрица $min$
    $=>$ её след (сумма дисперсий $sum_i EE |err(x)_i|^2$) минимален; этому
    условию отвечает единственная $K = K_(f,k)$.
  ],
  align(center + horizon, box(width: 330pt, observer-block-figure(
    style: (label: 14pt),
  ))),
)

#note("model")

== Метод

#set text(size: 15pt)

- Модель, шаги фильтра и их свойства оформлены как определения и теоремы.
- Доказательства проверяются системой #Rocq. В ВКР утверждения цитируются из
  кода.

#v(8pt)

$""
K_(f,k) = P_(k|k-1) H† R_(e,k)^(-1),
quad "где"
thick R_(e,k) = H P_(k|k-1) H† + R,
quad P_(k|k-1) = EE err(x)_(k|k-1) err(x)_(k|k-1)^*,
quad err(x)_(k|k-1) = bold(x)_k - hat(bold(x))_(k|k-1)
""$:

#slide-snippet("riccati_def.v", "filter_gain")

#v(8pt)

$""
P_(k+1|k+1) = "riccati_step"(P_(k|k)),
thick "где"
thick "riccati_step" := (P |-> (E_n - K H) P) compose (P |-> F P F† + G Q G†)""$:

#slide-snippet("riccati_def.v", "riccati_step")

#note("method")
