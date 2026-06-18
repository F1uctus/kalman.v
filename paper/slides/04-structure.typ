// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "lib.typ": *
#import "../slides-speech.typ": note
#import "../viz/gramian.typ": gramian-figure
#import "../viz/duality-mirror.typ": duality-mirror-figure

== 3.1. Наблюдаемость и управляемость

#set text(size: 14pt)

Это условия сходимости $P_(k|k) -> P_(oo) (= P_ss)$, где предел есть решение
ДАУР $P_ss = "riccati_step"(P_ss)$. Из них следуют $exists! P_(oo)$ и
$P succ 0$. Далее их ослабляют до детектируемости и стабилизируемости.

#two-col(
  columns: (1fr, auto),
  [
    - _Критерии ранга_, наблюдаемость $(H, F)$ и управляемость $(F, G)$:
      $"rank"(H^*, F^* H^*, dots.h, (F^*)^(n-1) H^*) = n,
      quad "rank"(G, F G, dots.h, F^(n-1) G) = n.$
    - _Грамианы_, суть решения уравнений Ляпунова ($succ.eq 0$), и конечные
      суммы, сходящиеся к этим решениям: \
      $
        cal(O)_oo = F^* cal(O)_oo F + H^* R^(-1) H, quad
        cal(C)_oo = F cal(C)_oo F^* + G Q G^*, \
        cal(O)_k = sum_(j=0)^(k-1) (F^j)^* H^* R^(-1) H F^j, quad
        cal(C)_k = sum_(j=0)^(k-1) F^j G Q G^* (F^j)^*.
      $
    - _Наблюдаемость (управляемость)_ $<=>$ $cal(O)_n succ 0$
      ($cal(C)_n succ 0$): \
      $quad quad
      x^* cal(O)_n x = sum_(j=0)^(n-1) (H F^j x)^* R^(-1) (H F^j x), quad
      x^* cal(O)_n x = 0 <=> x = 0.$
  ],
  align(center + horizon, slide-fig(
    gramian-figure(
      kmax: 3,
      style: (..slide-viz, label: 17pt, annot: 14pt),
    ),
    max-h: 190pt,
  )),
)

#note("r3-obsv")

== 3.2. Детектируемость и двойственность

#set text(size: 14pt, hyphenate: true)

#two-col(
  columns: (1fr, 300pt),
  [
    - Критерий ПБХ (для векторов с $|lambda| >= 1$). Детектируемость $(H, F)$ по
      правым, стабилизируемость $(F, G)$ по левым собственным векторам:
      $
        F v = lambda v, |lambda| >= 1 => H v != 0;
        quad w F = lambda w, |lambda| >= 1 => w G != 0.
      $
    - Детектируемость даёт усиление $L$, при котором матрица замкнутого контура
      $F - L H$ (динамики ошибки оценки) устойчива по Шуру
      $exists L: rho(F - L H) < 1$, что ограничивает ${P_(k|k)}$ сверху и даёт
      сходимость.
    - Двойственность оценивания и управления:
      $
        (H, F) "детектируема" <=> (F^*, H^*) "стабилизируема",
        \
        W_o (F, H) = W_c (F^*, H^*).
      $
  ],
  align(center + horizon, slide-fig(
    duality-mirror-figure(
      style: slide-viz,
      xcol: 4.4,
    ),
  )),
)

#note("r3-dual")
