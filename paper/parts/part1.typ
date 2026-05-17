#import "../lib.typ": *

#part_count.step()

= Спецификация алгоритма

Вернёмся к задаче оценки состояния системы.
Так как нам известны и матрицы $F, G, H$, и
векторы $u_k$, $y_k$, используем принцип
обратной связи (включим в уравнение наблюдаемые
измерения системы), чтобы минимизировать ошибку оценки.
Получим уравнение оценки состояния:
$
  hat(x)_(k+1)
  = F hat(x)_k + G u_k + K (y_k - hat(y)_k),
  quad "где" quad
  hat(y)_k = H hat(x)_k.
$

$
  tilde(y)_k
  = y_k - hat(y)_k
  = H x_k + v_k - H hat(x)_k
  = H (x_k - hat(x)_k) + v_k
  = H tilde(x)_k + v_k.
$

Заметим, что теперь ошибка оценки подчинена уравнению:
$
  tilde(x)_(k+1)
  = F tilde(x)_k + G u_k - K tilde(y)_k
  = (F - K H) tilde(x)_k
  + underline(G u_k) - underline(K v_k)
  .
$
Утверждать что $tilde(x)_k --> 0$ выполняется при
каких-либо условиях нельзя, потому что в уравнении
присутствуют ненулевые #underline[возмущающие слагаемые].
Вместо этого заметим, что $tilde(x)_k$ будет колебаться
в окрестности своего среднего значения, и вычисляя это
среднее, получим:
$
  EE tilde(x)_(k+1)
  = (F - K H)^k dot EE tilde(x)_k.
$
Теперь можно переформулировать нашу задачу более конкретно:
_нужно определённым образом подбирая матрицу $K$
добиться $EE tilde(x)_k --> 0$_.

#definition(title: "Шаг построения новой оценки состояния")[
  $hat(x)_(k+1)^- = F hat(x)_k^+ + G u_k$.

  #rocq-snippet("kalman.v", "Definition predict_state ")
]

#definition(title: "Ковариация предсказания")[
  $P_(k+1)^- := F P_k^+ F^* + G Q G^*$.

  #rocq-snippet("kalman.v", "Definition predict_cov ")
]

#definition(title: "Инновационная ковариация")[
  $S_k = H P_k^- H^* + R$.

  #rocq-snippet("kalman.v", "Definition innov_cov ")
]

#definition(title: "Усиление Калмана")[
  $K_k = P_k^- H^* S_k^(-1)$.

  #rocq-snippet("kalman.v", "Definition kalman_gain ")
]

#definition(title: "Обновление")[
  $hat(x)_k^+ = hat(x)_k^- + K_k (y_k - H hat(x)_k^-)$.

  #rocq-snippet("kalman.v", "Definition update_state ")
]

#definition(title: "Обновление ковариации")[
  $P_k^+ = (E_n - K_k H) P_k^-$.

  #rocq-snippet("kalman.v", "Definition update_cov ")
]

Эквивалентная _форма Джозефа_:
$ P_k^+ = (E_n - K_k H) P_k^- (E_n - K_k H)^top + K_k R K_k^top. $
