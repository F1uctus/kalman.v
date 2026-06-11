#import "lib.typ": *
#import "../viz/observer-block.typ": observer-block-figure

== Модель

#set text(size: 16pt)

#two-col(
  columns: (320pt, 1fr),
  [
    Уравнения состояния и наблюдения:
    $
      bold(x)_(k+1) & = F bold(x)_k + G bold(u)_k + G bold(w)_(k+1), \
          bold(y)_k & = H bold(x)_k + bold(v)_k.
    $

    Шумы с нулевым средним и известными ковариациями:
    $
      EE bold(w)_j bold(w)_k^* = Q delta_(j k) succ.eq 0,
      quad
      EE bold(v)_j bold(v)_k^* = R delta_(j k) succ 0.
    $

    Критерий качества: ковариация ошибки $EE err(x)_(k|k) err(x)_(k|k)^*$
    минимальна в порядке Лёвнера.
  ],
  align(center + horizon, box(width: 300pt, observer-block-figure(
    style: (label: 12pt),
  ))),
)

== Метод

#set text(size: 16pt)

- Модель, шаги фильтра и их свойства оформлены как определения и теоремы в `.v`
  файлах
- Доказательства проверяются системой #Rocq. Текст ВКР цитирует утверждения
  напрямую из исходного кода

#v(4pt)

#slide-snippet("riccati_def.v", "filter_gain")
#slide-snippet("riccati_def.v", "riccati_step")

#v(4pt)

Дальше: пять групп доказанных результатов в этой нотации.
