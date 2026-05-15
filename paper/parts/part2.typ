#import "../lib.typ": *

#part_count.step()

= Алгебраические и вероятностные предпосылки формализации фильтра Калмана <ch:prelim>

Ниже определения и соответствия в Rocq; доказательства в тексте опускаются (см. формализацию).

== Вещественные скаляры и матрицы

*Учебник.* Рассматривается поле вещественных чисел $RR$ с полным порядком.
Матрицы размеров $m times n$ образуют пространство $RR^(m times n)$; произведение
совместимых матриц, транспонирование $A^top$, след $"Tr"(A)$ определяются
стандартно. Для $n in NN$ единичная матрица это $E_n in RR^(n times n)$,
$E_n A = A E_n = A$ для любой $A in RR^(n times n)$.

*Rocq.* Тип скаляров задаётся параметром `R : realType` (`mathcomp.reals`).
Матрицы #raw("'M[R]_(m, n)"), столбцы #raw("'cV[R]_n"), строки #raw("'rV[R]_n").
Операции: #raw("*m"), #raw("^T"), #raw("\\tr"). Единичная матрица: `1%:M`
(размер выводится из контекста), что сопоставляется с $E_n$.

== Порядок Лёвнера

*Учебник.* Для симметричных $A, B in RR^(n times n)$ пишут $A prec.eq B$, если
$B - A succ.curly.eq 0$.

*Rocq.*

#raw(block: true, lang: "coq", "Definition psd_le n (A B : 'M[R]_n) : Prop := psd (B - A).")

Согласованность с конгруэнцией и транзитивность доказаны в `psd_order.v`.

== Дискретная модель состояний и один шаг фильтра Калмана <sec:prelim-model>

*Учебник.* Линейная дискретная система
$ x_(k+1) = F x_k + B u_k + w_(k+1), quad z_k = H x_k + v_k, $
где $Q succ.curly.eq 0$, матрица $R$ положительно определена ковариации
(или их аналоги) шумов процесса и измерения. Для симметричной
$P_k^- succ.curly.eq 0$ _предсказание_:
$
  hat(x)_k^- = F hat(x)_(k-1)^+ + B u_(k-1), quad
  P_k^- = F P_(k-1)^+ F^top + Q.
$
Инновационная ковариация $S_k = H P_k^- H^top + R$, усиление Калмана
$K_k = P_k^- H^top S_k^(-1)$, _обновление_:
$
  hat(x)_k^+ = hat(x)_k^- + K_k (z_k - H hat(x)_k^-), quad
  P_k^+ = (E_n - K_k H) P_k^-.
$
Эквивалентная _форма Джозефа_:
$ P_k^+ = (E_n - K_k H) P_k^- (E_n - K_k H)^top + K_k R K_k^top. $

*Rocq.* Параметры `F`, `B`, `H`, `Q`, `Rcov` и гипотезы `Q_psd`, `R_pd`; шаги
`predict_state`, `predict_cov`, `innov_cov`, `kalman_gain`, `update_state`,
`update_cov`, `joseph_form` в секции `KalmanFilter` файла `kalman.v`. В коде
`1%:M` соответствует $E_n$ в формулах обновления.

#raw(
  block: true,
  lang: "coq",
  "Definition predict_cov (P_prev : 'M[R]_n) : 'M[R]_n :=
  F *m P_prev *m F^T + Q.

Definition innov_cov (P_pred : 'M[R]_n) : 'M[R]_m :=
  H *m P_pred *m H^T + Rcov.

Definition kalman_gain (P_pred : 'M[R]_n) : 'M[R]_(n, m) :=
  P_pred *m H^T *m invmx (innov_cov P_pred).

Definition update_cov (P_pred : 'M[R]_n) : 'M[R]_n :=
  let K := kalman_gain P_pred in
  (1%:M - K *m H) *m P_pred.

Definition joseph_form (P_pred : 'M[R]_n) : 'M[R]_n :=
  let K := kalman_gain P_pred in
  let ImKH := 1%:M - K *m H in
  ImKH *m P_pred *m ImKH^T + K *m Rcov *m K^T.",
)

== Информационная форма (обратие апостериорной ковариации)

*Учебник.* Если $P_k^-$ и $R$ положительно определены, то
$ (P_k^+)^(-1) = (P_k^-)^(-1) + H^top R^(-1) H. $

*Rocq.* Лемма `update_cov_inverse` (при гипотезе `pd P_pred`): равенство для
`invmx (update_cov P_pred)` - чисто алгебраическое следствие тождеств для
усиления Калмана и обратимости `innov_cov` и `Rcov`.

== Оператор математического ожидания и несмещённость

*Учебник.* Ожидание $EE$ линейно, $EE[A X] = A EE[X]$ для постоянной матрицы
$A$ совместимых размеров; если $EE[w_k] = EE[v_k] = 0$, то при стандартной
линейной рекурсии ошибки и нулевом стартовом $EE[e_0]$ имеем $EE[e_k] = 0$ для
всех $k$.

*Rocq.* Абстрактный оператор `Exp` с аксиомами `Exp_add`, `Exp_scale`,
`Exp_mulmx_l` и нулевыми средними шумов; определения `x_true`, `x_hat`, `err`;
теорема `unbiased`.

== Оптимальность усиления Калмана в классе линейных обновлений

*Учебник.* Для произвольной матрицы усиления $K'$ того же размера, что и $K$,
апостериорная ковариация в форме Джозефа удовлетворяет
$ P^+(K') = P^+(K) + (K' - K) S (K' - K)^top, $
где $S = H P^- H^top + R$. Отсюда $P^+(K) prec.eq P^+(K')$ и
$"Tr" P^+(K) <= "Tr" P^+(K')$.

*Rocq.* `alt_update_cov`, лемма `alt_update_cov_diff`, теорема
`kalman_gain_optimal`; стационарное условие `gain_stationary_point`
($K S = P^- H^top$ в матричной записи).

Условие минимума следа с $E_n$:
$ "Tr"((E_n - K H) P^-) <= "Tr"((E_n - K' H) P^- (E_n - K' H)^top + K' R K'^top). $
