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


#rocq-snippet("kalman.v", "Definition predict_state ")

//#rocq-snippet("kalman.v", "Definition predict_cov ")
#rocq-snippet("kalman.v", "Definition innov_cov ")
#rocq-snippet("kalman.v", "Definition kalman_gain ")
#rocq-snippet("kalman.v", "Definition update_state ")
#rocq-snippet("kalman.v", "Definition update_cov ")
