(*
  Дискретное уравнение Ляпунова: `X = A ⋅ X ⋅ A† + Q`.

  Условия устойчивости и разрешимости:
  1.  Матрица Q должна быть эрмитовой и неотрицательно определённой
      (обычно задаёт внешние шумы или веса);
  2.  Дискретная система асимптотически устойчива тогда и только тогда, когда
      все собственные значения матрицы A по модулю строго меньше единицы
      (лежат внутри единичного круга); равносильно - для любого положительно
      определённого Q уравнение X = A X A† + Q имеет единственное положительно
      определённое решение X;
  3.  При только неотрицательно определённой Q решение X также неотрицательно
      определено
      (для положительной определённости нужна наблюдаемость пары (A, Q^½)).
      Достаточное (более сильное) условие - A есть сжатие в норме Фробениуса
      (frob_sq A < 1), откуда сразу следует |λ| < 1.

  При таких условиях частичная сумма
  `lyap_partial A Q N := ∑_(k<N) A^k Q (A†)^k` монотонно возрастает в порядке
  Лёвнера и равномерно ограничена (в том же порядке) матрицей, пропорциональной
  единичной (эквивалентно, ограничена по спектральной норме). Поэтому через
  `mx_mono_lim` определён предел `lyap_sol A Q`, являющийся решением
  (неотрицательно определённой неподвижной точкой) уравнения Ляпунова.

  Единственность эрмитовых неподвижных точек разрешается чисто алгебраически
  через `predict_diff_frob_bound`: для разности `D = X1 - X2` имеем
  `D = A D A† => frob_sq D <= (frob_sq A)² * frob_sq D`, и из
  `(frob_sq A)² < 1 => frob_sq D = 0`.

  Определения:
  - Область неопределенности: В зависимости от ранга ковариационной матрицы это
    множество является либо ограниченным (эллипсоид при полном ранге), либо
    неограниченным вдоль некоторых направлений
    (цилиндр при наличии нулевых собственных значений).

  - ([kailath2000], App. D, § D.1);
  - ([kailath2000], App. D, Theorem D.3.1 "Lyapunov Condition").
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import mxnotation mxdefinite mxloewner spectral mxherm mxfrob mxtopo mxmonotone.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* Частичные суммы Ляпунова, приближающиеся к решению уравнения Ляпунова. *)
Section LyapunovPartialSum.

  Variable (ℂ : numClosedFieldType).
 
  Variable (n : nat).
  Variables (A Q : 'M[ℂ]_n).

  Hypothesis Q_psd : psd Q.

  Definition lyap_partial (N : nat) : 'M[ℂ]_n :=
    \sum_(k < N) A^+k *m Q *m (A^t*)^+k.

  Lemma lyap_partial0 : lyap_partial 0 = 0.
  Proof.
    by rewrite /lyap_partial big_ord0.
  Qed.

  (*
    Поскольку матрица шума `Q` определена неотрицательно, `A^N Q (A†)^N` также
    гарантированно будет неотрицательно определён. Следовательно, по правилам
    порядка Лёвнера: `P_N <= P_(N+1)`

    Геометрически: область неопределённости монотонно расширяется. Область на
    шаге `N+1` полностью включает в себя область шага `N`.
  *)
  Lemma lyap_partial_recr N :
    lyap_partial N.+1 =
      lyap_partial N + A^+N *m Q *m (A^t*)^+N.
  Proof.
    by rewrite /lyap_partial big_ord_recr.
  Qed.

  (*
    Слагаемое шума, добавляемое на `k`-й итерации неотрицательно определено.

    Геометрически: шум не сужает область неопределённости ни по какому
    направлению.
  *)
  Lemma lyap_partial_term_psd (k : nat) :
    psd (A^+k *m Q *m (A^t*)^+k).
  Proof.
    have -> :
      A^+k *m Q *m (A^t*)^+k = A^+k *m Q *m (A^+k)^t*.
      by rewrite trmxCX.
    exact: psd_lcongr Q_psd.
  Qed.

  (*
    Накопленная за N шагов матрица неопределенности (сумма шумов) неотрицательно
    определена.

    Геометрически: Каждое слагаемое, согласно `lyap_partial_term_psd` -
    неотрицательно определенная матрица. Функция lyap_partial N это сумма таких
    матриц. В геометрии квадратичных форм сложение неотрицательно определённых
    матриц соответствует сумме Минковского для их эллипсоидов
    (или, точнее, сложению 'стоимостей' неопределенности в каждом направлении).
    Лемма доказывает, что результат такого сложения `psd (lyap_partial N)`
    всегда остается выпуклым эллипсоидом, задаваемым `x† P_N x = 1`.
  *)
  Lemma lyap_partial_psd N :
    psd (lyap_partial N).
  Proof.
    elim: N => [|N IH]; first by rewrite lyap_partial0; exact: psd0.
    by rewrite lyap_partial_recr; exact: psd_add IH (lyap_partial_term_psd N).
  Qed.

  (*
    Монотонность по N: разность двух соседних членов неотрицательно определена.
  *)
  Lemma lyap_partial_mono N :
    psd_le (lyap_partial N) (lyap_partial N.+1).
  Proof.
    rewrite /psd_le lyap_partial_recr.
    have ->: lyap_partial N + A^+N *m Q *m (A^t*)^+N - lyap_partial N
          = A^+N *m Q *m (A^t*)^+N.
      by rewrite [_ + _ - _]addrAC subrr add0r.
    exact: lyap_partial_term_psd.
  Qed.

  (*
    Тождество сдвига: `lyap_partial N+1 = Q + A * lyap_partial N * A†`.
    Доказывается индукцией по `N`.
  *)
  Lemma lyap_partial_shift N :
    lyap_partial N.+1 = Q + A *m lyap_partial N *m A^t*.
  Proof.
    elim: N => [|N IH].
      rewrite lyap_partial_recr lyap_partial0 add0r.
      rewrite expr0 mul1mx expr0 mulmx1.
      by rewrite mulmx0 mul0mx addr0.
    rewrite lyap_partial_recr {1}IH.
    rewrite lyap_partial_recr.
    rewrite mulmxDr mulmxDl -addrA.
    congr (_ + _); congr (_ + _).
    by rewrite exprS exprSr !mulmxA.
  Qed.

  (*
    Нижняя оценка любой неотрицательно определённой неподвижной точки уравнения
    Ляпунова `P = A P A† + Q` её частичными суммами: `lyap_partial N <= P`.
    Чисто алгебраически (конечная частичная сумма), без устойчивости: разность
    `P − lyap_partial (N+1) = A (P − lyap_partial N) A†` неотрицательно
    определена, по индукции.
  *)
  Lemma lyap_partial_fix_le (P : 'M[ℂ]_n) :
    psd P -> P = A *m P *m A^t* + Q ->
    forall N, psd_le (lyap_partial N) P.
  Proof.
    move=> Ppsd Pfix; elim => [|N IH].
      by rewrite /psd_le lyap_partial0 subr0.
    rewrite /psd_le lyap_partial_shift.
    have -> : P - (Q + A *m lyap_partial N *m A^t*)
            = A *m (P - lyap_partial N) *m A^t*.
      rewrite mulmxBr mulmxBl {1}Pfix.
      by rewrite opprD addrA addrK.
    exact: psd_lcongr A IH.
  Qed.

  (*
    Квадратичная форма частичной суммы в точке `v` как сумма W-форм на
    сопряжённых итерациях `(A†)^j v`, аналогично `obsv_bound.ctrl_gram_qform`
    для факторизованной весовой матрицы. Лемма используется для выделения
    поточечного зануления `Q ((A†)^j v) = 0` из условия неотрицательной
    определённости квадратичной формы `v^* (lyap_partial N) v = 0`.
  *)
  Lemma lyap_partial_qform (v : 'cV[ℂ]_n) N :
    \tr (v^t* *m lyap_partial N *m v)
    = \sum_(j < N) \tr (((A^t*)^+j *m v)^t* *m Q *m ((A^t*)^+j *m v)).
  Proof.
    elim: N => [|N IH].
      by rewrite lyap_partial0 mulmx0 mul0mx mxtrace0 big_ord0.
    rewrite lyap_partial_recr big_ord_recr /=.
    rewrite mulmxDr mulmxDl mxtraceD IH.
    congr (_ + _).
    by rewrite trmxC_mul trmxCX trmxCK !mulmxA.
  Qed.

  (*
    Геометрическая оценка следа.

    При условии `frob_sq A < 1` след частичной суммы равномерно ограничен
    `tr Q / (1 - frob_sq A)`.
  *)
  Lemma lyap_partial_tr_bound (Ac : frob_sq A < 1) (N : nat) :
    \tr (lyap_partial N) <= \tr Q / (1 - frob_sq A).
  Proof.
    have trQ_ge0 : 0 <= \tr Q by exact: psd_tr_ge0.
    have d_gt0 : 0 < 1 - frob_sq A by rewrite subr_gt0.
    have d_neq0 : (1 - frob_sq A) != 0 by rewrite gt_eqF.
    have key : \tr Q + frob_sq A * (\tr Q / (1 - frob_sq A))
            = \tr Q / (1 - frob_sq A).
      apply: (mulIf d_neq0).
      rewrite divfK // mulrDl -mulrA divfK // mulrBr mulr1.
      by rewrite [\tr Q * frob_sq A]mulrC subrK.
    elim: N => [|N IH].
      rewrite lyap_partial0 mxtrace0.
      by apply: divr_ge0; [exact: trQ_ge0 | exact: ltW d_gt0].
    rewrite lyap_partial_shift mxtraceD.
    rewrite -[X in _ <= X]key lerD2l.
    apply: (@le_trans _ _ (frob_sq A * \tr (lyap_partial N))).
      by apply: tr_conj_frob_le; exact: lyap_partial_psd.
    apply: ler_pM => //.
    - exact: frob_sq_ge0.
    - by apply: psd_tr_ge0; exact: lyap_partial_psd.
  Qed.

  (* Равномерная неотрицательно определённая мажоранта частичной суммы. *)
  Definition lyap_bnd : 'M[ℂ]_n :=
    (\tr Q / (1 - frob_sq A)) *: 1%:M.

  Lemma lyap_partial_le_bnd (Ac : frob_sq A < 1) N :
    psd_le (lyap_partial N) lyap_bnd.
  Proof.
    apply: (psd_le_trans (B := \tr (lyap_partial N) *: 1%:M)).
      exact: psd_le_trace_id (lyap_partial_psd N).
    rewrite /lyap_bnd.
    have trQ_ge0 : 0 <= \tr Q by exact: psd_tr_ge0.
    have d_gt0 : 0 < 1 - frob_sq A by rewrite subr_gt0.
    apply: psd_le_scale1.
    - by apply: ger0_real; apply: psd_tr_ge0; exact: lyap_partial_psd.
    - by apply: ger0_real; apply: divr_ge0; [exact: trQ_ge0 | exact: ltW d_gt0].
    - exact: lyap_partial_tr_bound.
  Qed.

  (*
    Аддитивность и блочная декомпозиция (для устойчивой по Шуру суммируемости).
  *)

  (*
    Аддитивность по индексу: частичная сумма на [0, n+m) распадается на блок [0,
    n) + сдвинутый блок A^n · (сумма на [0,m)) · (A†)^n.
  *)
  Lemma lyap_partial_add nn mm :
    lyap_partial (nn + mm)
    = lyap_partial nn + A^+nn *m lyap_partial mm *m (A^t*)^+nn.
  Proof.
    elim: mm => [|mm IH].
    - by rewrite addn0 lyap_partial0 mulmx0 mul0mx addr0.
    - rewrite addnS lyap_partial_recr IH lyap_partial_recr.
      rewrite mulmxDr mulmxDl -addrA; congr (_ + _); congr (_ + _).
      have e1 : A^+(nn + mm) = A^+nn *m A^+mm by rewrite mulmxE -exprD.
      have e2 : (A^t*)^+(nn + mm) = (A^t*)^+mm *m (A^t*)^+nn
        by rewrite mulmxE -exprD addnC.
      by rewrite e1 e2 !mulmxA.
  Qed.

  (* Монотонность частичной суммы по индексу (через аддитивность). *)
  Lemma lyap_partial_le_mono nn mm :
    (nn <= mm)%N -> psd_le (lyap_partial nn) (lyap_partial mm).
  Proof.
    move=> hle.
    rewrite -(subnKC hle) lyap_partial_add /psd_le.
    rewrite [_ + _ - _]addrAC subrr add0r.
    have ->: A^+nn *m lyap_partial (mm - nn) *m (A^t*)^+nn
           = A^+nn *m lyap_partial (mm - nn) *m (A^+nn)^t*
      by rewrite trmxCX.
    exact: psd_lcongr (A^+nn) (lyap_partial_psd (mm - nn)).
  Qed.

End LyapunovPartialSum.

(*
  Блочная декомпозиция: сумма на [0, N0 M) есть частичная сумма Ляпунова для
  матрицы `B := A^N0` с весом `W0 := lyap_partial A Q N0`. Это сводит случай
  устойчивости по Шуру к ограничению `frob_sq B < 1`.
*)
Lemma lyap_partial_block (ℂ : numClosedFieldType) (n : nat)
    (A Q : 'M[ℂ]_n) N0 M :
  lyap_partial A Q (N0 * M)
  = lyap_partial (A^+N0) (lyap_partial A Q N0) M.
Proof.
elim: M => [|M IH].
- by rewrite muln0 !lyap_partial0.
- rewrite mulnSr (lyap_partial_add A Q) IH lyap_partial_recr.
  congr (_ + _).
  by rewrite !exprM trmxCX.
Qed.

(* Единственность эрмитовых неподвижных точек. *)
Section LyapunovFixpointUnique.

  Variable (ℂ : numClosedFieldType).
  Variable (n : nat).
  Variables (A Q : 'M[ℂ]_n).

  Hypothesis A_contract : frob_sq A < 1.

  (*
    Коэффициент сжатия c := (frob_sq A)² строго меньше 1. Доказательство: 0 <=
    frob_sq A < 1 => (frob_sq A)² <= frob_sq A < 1.
  *)
  Lemma frob_sq_A_sq_lt1 :
    (frob_sq A) ^+ 2 < 1.
  Proof.
    have fa_ge0 : 0 <= frob_sq A := frob_sq_ge0 A.
    have fa_le1 : frob_sq A <= 1 := ltW A_contract.
    have step : (frob_sq A) ^+ 2 <= frob_sq A.
      rewrite expr2 -[X in _ <= X]mul1r.
      by apply: ler_pM=> //; apply: mulr_ge0.
    exact: le_lt_trans step A_contract.
  Qed.

  (*
    Разность решений дискретного уравнения Ляпунова удовлетворяет однородному
    уравнению D = A D A†.
  *)
  Lemma lyap_fixed_diff_eq (X1 X2 : 'M[ℂ]_n) :
    X1 = A *m X1 *m A^t* + Q ->
    X2 = A *m X2 *m A^t* + Q ->
    X1 - X2 = A *m (X1 - X2) *m A^t*.
  Proof.
    move=> eq1 eq2.
    rewrite mulmxBr mulmxBl.
    have e1 : X1 - Q = A *m X1 *m A^t* by rewrite {1}eq1 addrK.
    have e2 : X2 - Q = A *m X2 *m A^t* by rewrite {1}eq2 addrK.
    by rewrite -e1 -e2 opprB addrA subrK.
  Qed.

  (*
    Единственность эрмитовой неподвижной точки.
    - ([kailath2000], App. D, Lemma D.1.1 "Uniqueness of Solutions").
  *)
  Theorem lyap_fix_unique (X1 X2 : 'M[ℂ]_n) :
    X1 \is hermsymmx -> X2 \is hermsymmx ->
    X1 = A *m X1 *m A^t* + Q ->
    X2 = A *m X2 *m A^t* + Q ->
    X1 = X2.
  Proof.
    move=> H1 H2 eq1 eq2.
    set D := X1 - X2.
    have D_eq : D = A *m D *m A^t* := lyap_fixed_diff_eq eq1 eq2.
    have D_herm : D \is hermsymmx.
      apply/is_hermitianmxP; rewrite expr0 scale1r.
      rewrite trmxCB.
      rewrite -(hermsym_eq H1) -(hermsym_eq H2).
      by [].
    (* frob_sq D <= c * frob_sq D, c < 1 => frob_sq D = 0. *)
    have key : frob_sq D <= (frob_sq A) ^+ 2 * frob_sq D.
      rewrite {1}D_eq.
      exact: predict_diff_frob_bound D_herm.
    have c_lt1 : (frob_sq A) ^+ 2 < 1 := frob_sq_A_sq_lt1.
    have fd_ge0 : 0 <= frob_sq D := frob_sq_ge0 D.
    have fd_eq0 : frob_sq D = 0.
      apply: le_anti; apply/andP; split; last exact: fd_ge0.
      (*
        `frob_sq D - c * frob_sq D <= 0 => (1 - c) * frob_sq D <= 0`
        `=> frob_sq D <= 0`.
      *)
      have step : frob_sq D - (frob_sq A) ^+ 2 * frob_sq D <= 0.
        by rewrite subr_le0.
      have factor : frob_sq D - (frob_sq A) ^+ 2 * frob_sq D
                  = (1 - (frob_sq A) ^+ 2) * frob_sq D.
        by rewrite mulrBl mul1r.
      rewrite factor in step.
      have d_gt0 : 0 < 1 - (frob_sq A) ^+ 2 by rewrite subr_gt0.
      by rewrite -(ler_pM2l d_gt0) mulr0; exact: step.
    have D_zero : D = 0 by exact: frob_sq_eq0 fd_eq0.
    by apply/eqP; rewrite -subr_eq0 -/D D_zero.
  Qed.

End LyapunovFixpointUnique.

(* Существование неотрицательно определённого решения уравнения Ляпунова. *)
Section LyapunovSolutionExistence.

  (* Каноническое вложение ℝ ↪ ℂ. *)
  Variables (ℝ : realType) (ℂ : numClosedFieldType).
  Variable r2c : {rmorphism ℝ -> ℂ}.
  Variable c2r : ℂ -> ℝ.

  Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
  Hypothesis r2cK : cancel r2c c2r.
  Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
  Hypothesis c2r_continuous : continuous (c2r : ℂ -> ℝ).
  Hypothesis r2c_continuous : continuous (r2c : ℝ -> ℂ).

  Variable (n : nat).
  Variables (A Q : 'M[ℂ]_n).

  Hypothesis Q_psd : psd Q.
  Hypothesis A_contract : frob_sq A < 1.

  Local Notation P := (lyap_partial A Q).

  (*
    Предел частичных сумм (ряд `∑ Aᵏ Q (A†)ᵏ` - решение уравнения Ляпунова).
    - ([kailath2000], App. D, Lemma D.1.2 "Properties of the Lyapunov Equation").
  *)
  Definition lyap_sol : 'M[ℂ]_n :=
    mx_mono_lim P.

  Lemma P_psd k :
    psd (P k).
  Proof.
    apply: lyap_partial_psd; exact: Q_psd.
  Qed.

  Lemma P_mono k :
    psd_le (P k) (P k.+1).
  Proof.
    exact: lyap_partial_mono.
  Qed.

  Lemma P_bnd k :
    psd_le (P k) (lyap_bnd A Q).
  Proof.
    apply: lyap_partial_le_bnd; [exact: Q_psd | exact: A_contract].
  Qed.

  Theorem lyap_sol_cvgn :
    P @ \oo --> lyap_sol.
  Proof.
    apply: (@mx_mono_cvgn ℝ ℂ r2c c2r
            ler_r2c c2rK r2c_continuous
            n P (lyap_bnd A Q) P_psd P_mono P_bnd).
  Qed.

  Lemma lyap_sol_is_cvgn : cvgn P.
  Proof.
    by apply/cvg_ex; exists lyap_sol; exact: lyap_sol_cvgn.
  Qed.

  (*
    Неотрицательная определённость решения при неотрицательно определённом Q.
    - ([kailath2000], App. D, Lemma D.1.2 "Properties of the Lyapunov Equation").
  *)
  Theorem lyap_sol_psd :
    psd lyap_sol.
  Proof.
    exact: (@mx_mono_lim_psd ℝ ℂ r2c c2r
            ler_r2c c2rK c2r_continuous r2c_continuous
            n P (lyap_bnd A Q) P_psd P_mono P_bnd).
  Qed.

  Lemma lyap_sol_hermsym :
    lyap_sol \is hermsymmx.
  Proof.
    exact: psd_hermsym lyap_sol_psd.
  Qed.

  Theorem lyap_sol_le_bnd :
    psd_le lyap_sol (lyap_bnd A Q).
  Proof.
    exact: (@mx_mono_lim_le ℝ ℂ r2c c2r
            ler_r2c c2rK c2r_continuous r2c_continuous
            n P (lyap_bnd A Q) P_psd P_mono P_bnd).
  Qed.

  (* Неподвижная точка: lyap_sol = A * lyap_sol * A† + Q. *)

  (* Сдвиг сходящейся последовательности (k -> k+1) тоже сходится к lyap_sol. *)
  Lemma lyap_partial_shift_cvgn :
    (fun k => P k.+1) @ \oo --> lyap_sol.
  Proof.
    have HP : P @ \oo --> lyap_sol := lyap_sol_cvgn.
    have Hsh : addn 1 @ \oo --> (\oo : set_system nat) := cvg_addnl 1.
    have Hcomp : (P \o addn 1) @ \oo --> lyap_sol
      := cvg_comp (addn 1) P Hsh HP.
    have Heq : P \o (addn 1) = (fun k => P k.+1).
      by apply/funext=> k; rewrite /= add1n.
    by rewrite -Heq.
  Qed.

  (* Непрерывность правой части шага Ляпунова. *)
  Lemma cvgn_lyap_step (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L ->
    (fun k => Q + A *m Pf k *m A^t*) @ \oo --> Q + A *m L *m A^t*.
  Proof.
    move=> HPf.
    apply: cvgn_addmx; first exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    exact: cvgn_mulmx (cvg_cst _) HPf.
  Qed.

  (*
    Решение уравнения Ляпунова является его неподвижной точкой.
    - ([kailath2000], App. D, Lemma D.1.2 "Properties of the Lyapunov Equation").
  *)
  Theorem lyap_sol_fix :
    lyap_sol = A *m lyap_sol *m A^t* + Q.
  Proof.
    have Hshift : (fun k => P k.+1) @ \oo --> lyap_sol
      := lyap_partial_shift_cvgn.
    have eqf : (fun k => P k.+1) = (fun k => Q + A *m P k *m A^t*).
      by apply/funext=> k; exact: lyap_partial_shift.
    rewrite eqf in Hshift.
    have Hrhs : (fun k => Q + A *m P k *m A^t*) @ \oo -->
                Q + A *m lyap_sol *m A^t*
      := cvgn_lyap_step lyap_sol_cvgn.
    have HausM : hausdorff_space ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ).
      exact: norm_hausdorff.
    have Hshift_n :
        (fun k => Q + A *m P k *m A^t*)
          @ \oo --> (lyap_sol : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      by exact: Hshift.
    have Hrhs_n :
        (fun k => Q + A *m P k *m A^t*)
          @ \oo --> ((Q + A *m lyap_sol *m A^t*)
                      : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      by exact: Hrhs.
    have eqLim : lyap_sol = Q + A *m lyap_sol *m A^t*
      := cvg_unique HausM Hshift_n Hrhs_n.
    by rewrite [LHS]eqLim addrC.
  Qed.

  (*
    Единственность среди эрмитовых решений (частный случай lyap_fix_unique).
    - ([kailath2000], App. D, Lemma D.1.1 "Uniqueness of Solutions").
  *)
  Theorem lyap_sol_unique (X : 'M[ℂ]_n) :
    X \is hermsymmx ->
    X = A *m X *m A^t* + Q ->
    X = lyap_sol.
  Proof.
    move=> Hherm Heq.
    apply: (lyap_fix_unique A_contract Hherm lyap_sol_hermsym Heq).
    exact: lyap_sol_fix.
  Qed.

End LyapunovSolutionExistence.

Section InputToStateStability.

  Variable (ℂ : numClosedFieldType).

  (*
    В mathcomp аксиома (принцип) Архимеда формулируется следующим образом:
    ```
    Definition archimedean_axiom (R : numDomainType) : Prop :=
      ∀ x : R, ∃ ub : nat, `|x| < ub%:R.
    ```
    Здесь `R` - (частично!) упорядоченная нормированная область целостности. Как
    подчеркивалось в работах, посвященных теореме Линдемана - Вейерштрасса,
    установление этой аксиомы на поле комплексных чисел открывает возможность
    определения конструктивных булевых предикатов. Здесь мы тоже её установим.
  *)
  Hypothesis ℂ_archi : Num.archimedean_axiom ℂ.

  Lemma lin_filter_cvgn0 (r : ℂ) (u v : nat -> ℂ) :
    0 <= r -> r < 1 ->
    (forall k, `|v k.+1| <= r * `|v k| + `|u k|) ->
    u @ \oo --> (0 : ℂ) -> v @ \oo --> (0 : ℂ).
  Proof.
    move=> r_ge0 r_lt1 rec ucvg.
    have hr0 : (fun k => r ^+ k) @ \oo --> (0 : ℂ).
      by rewrite -(cvg_shiftS (fun j => r ^+ j)); apply: r_pow_cvgn0 => //.
    suff HO : (v : nat -> ℂ^o) @ \oo --> (0 : ℂ^o) by exact: HO.
    apply/cvgrPdistC_lt => eps eps_pos.
    set η := eps / 2.
    have η_pos : 0 < η by rewrite divr_gt0.
    have omr_pos : 0 < 1 - r by rewrite subr_gt0.
    have ζ_pos : 0 < (1 - r) * η by rewrite mulr_gt0.
    have ucvg_o : (u : nat -> ℂ^o) @ \oo --> (0 : ℂ^o) by exact: ucvg.
    have /cvgrPdistC_lt /(_ _ ζ_pos) unear := ucvg_o.
    have [N _ HN] := unear.
    have HN' : forall k, (N <= k)%N -> `|u k| <= (1 - r) * η.
      by move=> k Nk; have := HN k Nk; rewrite subr0; apply: ltW.
    have tail : forall m, `|v (N + m)%N| <= r ^+ m * `|v N| + η.
      elim=> [|m IH].
        by rewrite addn0 expr0 mul1r lerDl; apply: ltW.
      rewrite addnS.
      apply: (le_trans (rec (N + m)%N)).
      have hb : `|u (N + m)%N| <= (1 - r) * η by apply: HN'; exact: leq_addr.
      apply: (le_trans (lerD (ler_wpM2l r_ge0 IH) hb)).
      rewrite exprS mulrDr mulrA -addrA -mulrDl.
      have -> : r + (1 - r) = 1 by rewrite addrC subrK.
      by rewrite mul1r.
    have hr : (fun k => r ^+ (k - N)%N) @ \oo --> (0 : ℂ).
      by rewrite (cvg_centern N (fun j => r ^+ j)); exact: hr0.
    have hcvg : (fun k => r ^+ (k - N)%N * `|v N|) @ \oo --> (0 : ℂ).
      have hcst : (fun _ : nat => `|v N|) @ \oo --> (`|v N| : ℂ) by exact: cvg_cst.
      have hh := cvgC_M hr hcst.
      by rewrite mul0r in hh.
    have hcvg_o : ((fun k => r ^+ (k - N)%N * `|v N|) : nat -> ℂ^o)
                  @ \oo --> (0 : ℂ^o) by exact: hcvg.
    have /cvgrPdistC_lt /(_ _ η_pos) hnear := hcvg_o.
    near=> k.
    have k_ge_N : (N <= k)%N by near: k; exact: nbhs_infty_ge.
    have e1 : `|v k| <= r ^+ (k - N)%N * `|v N| + η.
      by rewrite -{1}(subnKC k_ge_N); exact: tail.
    have e2 : `|(r ^+ (k - N)%N * `|v N|) - 0| < η by near: k; exact: hnear.
    rewrite subr0 ger0_norm in e2; last first.
      by apply: mulr_ge0; [exact: exprn_ge0 | exact: normr_ge0].
    rewrite /= subr0.
    apply: (le_lt_trans e1).
    have eps_eq : η + η = eps by rewrite /η -splitr.
    by rewrite -eps_eq ltrD2r.
    Unshelve.
    all: by end_near.
  Qed.

End InputToStateStability.
