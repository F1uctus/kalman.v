#import "../lib.typ": *

#part_count.step()

Вернёмся к задаче оценки состояния системы.
Так как нам известны и матрицы $F, G, H$, и
векторы $u_k$, $y_k$, используем принцип
обратной связи (включим в уравнение наблюдаемые
измерения системы), чтобы минимизировать оценку.
Уравнение состояния переписывается следующим образом:

$
  hat(x)_(i+1) = F hat(x)_i + G u_i + K (y_i - hat(y)_i)
  quad "где" quad
  hat(y) = H hat(x).
$
Заметим, что теперь ошибка оценки подчинена уравнению:
$
  tilde(x)_(k+1)
  = F tilde(x)_k - K tilde(y)_k
  = (F - K H) tilde(x)_k,
$
поэтому
$
  tilde(x)_(k)
  = (F tilde(x)_k - K H)^k tilde(x)_0
$
и подбором матрицы $K$ можно добиться $tilde(x)_k -> 0$.

#rocq-snippet("kalman.v", "Definition predict_state ")

//#rocq-snippet("kalman.v", "Definition predict_cov ")
#rocq-snippet("kalman.v", "Definition innov_cov ")
#rocq-snippet("kalman.v", "Definition kalman_gain ")
#rocq-snippet("kalman.v", "Definition update_state ")
#rocq-snippet("kalman.v", "Definition update_cov ")
