(*
  Дискретное алгебраическое уравнение Риккати (ДАУР, DARE). Существование и
  неподвижная точка стационарной ковариации.

  - $ P = F P F† + G Q G† - K_p R_e K_p† $
  - $ R_e = R + H P_pss H†. $

  - `Pss := mx_mono_lim (fun k => iter k riccati_step 0)` - предел монотонной
    траектории `iter k riccati_step 0` в матричной топологии
    (получается через `mxmonotone.mx_mono_cvgn`).
  - `Pss_cvgn` - сходимость итерации из нуля к $P_ss$.
  - `Pss_psd` - неотрицательная определённость предельной матрицы.
  - `Pss_fix` - $P_ss = "riccati_step" P_ss$
    (по непрерывности шага Риккати и единственности предела в матричной топологии).

  Схема.
  1.  Равномерная верхняя оценка `Pseq_bnd` - для каждой итерации
      $"iter" k "riccati_step" 0 prec.eq P_bnd$ в порядке Лёвнера. Эта оценка
      выводится из спектральной устойчивости по Шуру замкнутого контура
      $M_c = (E - K_0 H) F$
      (`spec_rad_lt1 Mc`, для стабилизирующего усиления $K_0$), а не из
      контракции системной матрицы $"frob_sq" F < 1$: выделение полного квадрата
      даёт $"riccati_step" Sigma prec.eq M_c Sigma M_c† + W_c$, откуда
      $"iter" k "riccati_step" 0 prec.eq "lyap_partial" M_c W_c k prec.eq P_bnd$,
      где $P_bnd$ - равномерная мажоранта из суммируемости грамиана при
      устойчивости по Шуру - (`lyap_partial_le_bnd_schur`, spec_rad.v);
      @kailath2000[§ 14.5].
  2.  `riccati_iter0_mono` даёт монотонность.
  3.  `mx_mono_cvgn` - сходимость в матричной топологии.
  4.  `cvgn_riccati_step` (доказано здесь же) - непрерывность шага Риккати на
      неотрицательно определённых входах. Композиция с `Pss_cvgn` и
      единственностью предела (`cvg_unique` + `norm_hausdorff`) даёт неподвижную
      точку.
  5.  Положительная определённость $P_ss$ (`Pss_pd`) выводится из полной
      управляемости `FG_ctrl : controllable F (G Q G†)` гипотеза
  - @kailath2000[App. E, Theorem E.6.2 "Positive Definite Solution"]:
  предсказанная ss-ковариация $P_pss = F_p P_pss F_p† + (K_p R K_p† + G Q G†)$
  (`riccati_closed_loop_identity`) положительно определена через грамиан
  управляемости замкнутого контура (`gramian_infty.controllable_oi_gram_pd`),
  затем $P_ss = "update_cov" P_pss$ сохраняет положительную определённость
  (`update_cov_pd`).
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import mxnotation mxdefinite mxloewner spectral mxherm
  mxfrob mxtopo mxmonotone kalman riccati_mono obsv_bound lyapunov
  gramian_infty spec_rad detectability riccati_unique.
From Kalman Require riccati_cont.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

Section DARE.

  (* Каноническое вложение ℝ ↪ ℂ. *)
  Variables (ℝ : realType) (ℂ : numClosedFieldType).
  Variable r2c : {rmorphism ℝ -> ℂ}.
  Variable c2r : ℂ -> ℝ.
  Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
  Hypothesis r2cK : cancel r2c c2r.
  Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
  Hypothesis c2r_continuous : continuous (c2r : ℂ -> ℝ).
  Hypothesis r2c_continuous : continuous (r2c : ℝ -> ℂ).

  (* Аксиома Архимеда для `ℂ` нужна для $A^k -> 0$ при устойчивости по Шуру. *)
  Hypothesis ℂ_archi : Num.archimedean_axiom ℂ.

  (*
    Параметры динамической системы Калмана. Размерность состояния положительна
    (`n = n'.+1`): спектральное разложение Шура требует `n > 0`.
  *)
  Variables (m p : nat).
  Variable (n' : nat).
  Local Notation n := (n'.+1).
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variables (Q : 'M[ℂ]_m) (R : 'M[ℂ]_p).
  Hypothesis Q_psd : psd Q.
  Hypothesis R_pd : pd R.

  (*
    Невырожденность шума: шум процесса входит во все направления состояния. Это
    стандартное предположение классического фильтра Калмана - матрица $G Q G†$
    положительно определена, что гарантирует положительную определённость
    установившейся ковариации $P_ss$.

    - @kailath2000[App. E, Theorem E.6.2 "Positive Definite Solution"].

    Полная управляемость пары процессного шума `(F, G Q^½)`
    (через неотрицательно определённый вес $G Q G†$) влечёт положительную
    определённость $P_ss$. Существование лишь _неотрицательно_ определённого
    стабилизирующего решения дано в Theorem E.5.1.
  *)
  Hypothesis FG_ctrl : controllable F (G *m Q *m G^t*).

  (*
    Неотрицательная определённость веса процессного шума
    (из `Q_psd`, без положительно определённого возбуждения).
  *)
  Lemma GQGt_psd : psd (G *m Q *m G^t*).
  Proof.
    exact: psd_lcongr G Q_psd.
  Qed.

  (* Стабилизируемость пары шума, выводимая из управляемости. *)
  Lemma FG_stab : stabilizable F (G *m Q *m G^t*).
  Proof.
    exact: controllable_stabilizable FG_ctrl.
  Qed.

  (*
    Детектируемость влечёт стабилизирующее усиление и устойчивость по Шуру
    замкнутого контура.

    Требуем детектируемость пары F_detectable : detectable F H
    (PBH: каждый собственный вектор $F$ с $|λ| >= 1$ наблюдаем через $H$).
    Отсюда `detectable_stabilizing_filter` даёт стабилизирующее усиление $K_0$,
    делающее апостериорный замкнутый контур $M_c := (E - K_0 H) F$ спектрально
    устойчивым по Шуру. Выделение полного квадрата по $K_0$ даёт неравенство
    $"riccati_step" Sigma prec.eq M_c Sigma M_c† + W_c$,
    $W_c := (E - K_0 H) G Q G† (E - K_0 H)† + K_0 R K_0†$, откуда следует
    равномерная мажоранта $P_bnd$
    (через суммируемость грамиана при устойчивости по Шуру, `lyap_partial_le_bnd_schur`).
    Суперрешение
    (матрица $X$ с $"riccati_step" X prec.eq X$, мажорирующая итерацию сверху)
    строится как $"lyap_sol" M_c W_c + a ("lyap_sol" M_c E)$ (см. ниже): это
    возмущение по Ляпунову замкнутого контура, корректное для любого устойчивого
    по Шуру $M_c$.

    - @kailath2000[§ 14.5].
  *)
  Hypothesis F_detectable : detectable F H.

  (*
    Стабилизирующий коэффициент усиления $K_0$ извлекается из детектируемости
    конструктивным выбором `cid` из существования
    (`detectable_stabilizing_filter`).
  *)
  Definition K0 : 'M[ℂ]_(n, p) :=
    proj1_sig (cid (detectable_stabilizing_filter F_detectable)).

  Local Notation Mc := ((1%:M - K0 *m H) *m F).
  Local Notation Wc :=
    ((1%:M - K0 *m H) *m (G *m Q *m G^t*) *m (1%:M - K0 *m H)^t*
     + K0 *m R *m K0^t*).

  (* Спектральная устойчивость по Шуру апостериорного замкнутого контура. *)
  Lemma Mc_schur : spec_rad_lt1 Mc.
  Proof.
    exact: proj2_sig (cid (detectable_stabilizing_filter F_detectable)).
  Qed.

  (* Весовая матрица $W_c$ замкнутого контура неотрицательно определена. *)
  Lemma Wc_psd : psd Wc.
  Proof.
    apply: psd_add.
    - exact: psd_lcongr (1%:M - K0 *m H) (psd_lcongr G Q_psd).
    - exact: psd_lcongr K0 (pd_psd R_pd).
  Qed.

  (*
    Неравенство с выделением полного квадрата по усилению $K_0$.

    - @kailath2000[§ 14.2];
    - @kailath2000[App. E, Lemma E.3.1 "Monotonicity Properties of α(·)"].
  *)
  Lemma riccati_step_le_Mc (Sigma : 'M[ℂ]_n) :
    psd Sigma ->
    psd_le (riccati_step F G H Q R Sigma) (Mc *m Sigma *m Mc^t* + Wc).
  (*
    Схема: $"riccati_step" Σ <= M_c Σ M_c† + W_c$. Через `alt_update_cov_diff`
    (апостериорное усиление K0):
    $"update_cov"("predict" Σ) <= "alt_update_cov" K_0$
    $("predict" Σ) = (E − K_0 H)(F Σ F† + G Q G†)(E − K_0 H)† + K_0 R K_0† = M_c Σ M_c† + W_c$.
  *)
  Proof.
    move=> psdS.
    have psdPred : psd (predict_cov F G Q Sigma)
      := predict_cov_psd F G Q_psd psdS.
    have hle : psd_le (update_cov H R (predict_cov F G Q Sigma))
                      (alt_update_cov H R K0 (predict_cov F G Q Sigma)).
      rewrite /psd_le (alt_update_cov_diff H R_pd K0 psdPred).
      rewrite addrAC subrr add0r.
      exact: psd_lcongr (K0 - kalman_gain H R (predict_cov F G Q Sigma))
                        (pd_psd (innov_cov_pd H R_pd psdPred)).
    have heq : alt_update_cov H R K0 (predict_cov F G Q Sigma)
             = Mc *m Sigma *m Mc^t* + Wc.
      rewrite /alt_update_cov /predict_cov /=.
      set ImKH := 1%:M - K0 *m H.
      have hsplit : forall Xa Xb : 'M[ℂ]_n,
          ImKH *m (Xa + Xb) *m ImKH^t*
          = ImKH *m Xa *m ImKH^t* + ImKH *m Xb *m ImKH^t*.
        by move=> Xa Xb; rewrite mulmxDr mulmxDl.
      rewrite hsplit.
      have h1 : ImKH *m (F *m Sigma *m F^t*) *m ImKH^t*
              = Mc *m Sigma *m Mc^t*.
        by rewrite trmxC_mul !mulmxA.
      by rewrite h1 addrA.
    rewrite /riccati_step heq in hle; exact: hle.
  Qed.

  (*
    Равномерная верхняя мажоранта частичных сумм Ляпунова замкнутого контура -
    через суммируемость грамиана при устойчивости по Шуру
    (`lyap_partial_le_bnd_schur`, spec_rad.v). Конкретная матрица извлекается из
    существования.
  *)
  Definition Pbnd : 'M[ℂ]_n :=
    proj1_sig (cid (lyap_partial_le_bnd_schur ℂ_archi Wc_psd Mc_schur)).

  (*
    $"iter" k "riccati_step" 0 <= "lyap_partial" M_c W_c k$ - индукция через
    выделение полного квадрата + лево-конгруэнтную монотонность + тождество
    сдвига частичной суммы Ляпунова.
  *)
  Lemma Pseq_le_lyap_partial k :
    psd_le (iter k (riccati_step F G H Q R) 0) (lyap_partial Mc Wc k).
  Proof.
    elim: k => [|k IH].
    - rewrite lyap_partial0 /=; apply: psd_le_refl; exact: psd0.
    - rewrite iterS.
      have psd_k : psd (iter k (riccati_step F G H Q R) 0)
        := riccati_iter0_psd F G H Q_psd R_pd k.
      apply: (psd_le_trans (riccati_step_le_Mc psd_k)).
      rewrite (lyap_partial_shift Mc Wc k) [_ + Wc]addrC.
      apply: psd_le_add2l; apply: psd_le_lcongr; exact: IH.
  Qed.

  Lemma lyap_partial_le_Pbnd k : psd_le (lyap_partial Mc Wc k) Pbnd.
  Proof.
    exact: (proj2_sig
      (cid (lyap_partial_le_bnd_schur ℂ_archi Wc_psd Mc_schur)) k).
  Qed.

  (* Траектория из нуля и её базовые свойства. *)
  Local Notation Pseq := (fun k => iter k (riccati_step F G H Q R) 0).

  Lemma Pseq_psd k : psd (Pseq k).
  Proof.
    exact: (riccati_iter0_psd F G H Q_psd R_pd k).
  Qed.

  Lemma Pseq_mono k : psd_le (Pseq k) (Pseq k.+1).
  Proof.
    exact: (riccati_iter0_mono F G H Q_psd R_pd k).
  Qed.

  Lemma Pseq_bnd k : psd_le (Pseq k) Pbnd.
  Proof.
    apply: (psd_le_trans (Pseq_le_lyap_partial k)).
    exact: lyap_partial_le_Pbnd k.
  Qed.

  (*
    Существование предела $P_ss$ в матричной топологии.

    - @kailath2000[App. E, § E.3 "Existence of Solutions to the DARE"].
  *)
  Definition Pss : 'M[ℂ]_n := mx_mono_lim Pseq.

  (*
    Сходимость траектории из нуля.

    Последовательность $P_seq$ сходится к $P_ss$ в матричной топологии.

    - @kailath2000[§ 14.5, Theorem 14.5.1 "Sufficiency"].
  *)
  Theorem Pss_cvgn :
    Pseq @ \oo --> Pss.
  Proof.
    apply: (@mx_mono_cvgn ℝ ℂ r2c c2r
            ler_r2c c2rK r2c_continuous
            n Pseq Pbnd Pseq_psd Pseq_mono Pseq_bnd).
  Qed.

  Lemma Pss_is_cvgn : cvgn Pseq.
  Proof.
    by apply/cvg_ex; exists Pss; exact: Pss_cvgn.
  Qed.

  (*
    Неотрицательная определённость предела.

    - @kailath2000[App. E, § E.3 "Existence of Solutions to the DARE"].
  *)
  Theorem Pss_psd :
    psd Pss.
  Proof.
    exact: (@mx_mono_lim_psd ℝ ℂ r2c c2r
            ler_r2c c2rK c2r_continuous r2c_continuous
            n Pseq Pbnd Pseq_psd Pseq_mono Pseq_bnd).
  Qed.

  Theorem Pss_le_bnd :
    psd_le Pss Pbnd.
  Proof.
    exact: (@mx_mono_lim_le ℝ ℂ r2c c2r
            ler_r2c c2rK c2r_continuous r2c_continuous
            n Pseq Pbnd Pseq_psd Pseq_mono Pseq_bnd).
  Qed.

  (*
    Оптимальность установившейся ковариации.
    - @kailath2000[§ 14.2, факт b];
    - @kailath2000[§ 14.1.3];
    - @kailath2000[Prob. 14.4].

    (§ 14.2, обсуждение нулевой Риккати-рекурсии (14.2.1), факт b, c. 507): для
    любого усиления $K$, делающего замкнутый контур наблюдателя $M = F - K_p H$
    устойчивым ($K_p := F K$), нулевая Риккати-итерация мажорируется сверху
    $P^degree_i <= Pi$, $Pi = M Pi M† + (G Q G† + K_p R K_p†)$, где
    $Pi = "lyap_sol" M W$ - установившаяся ковариация ошибки суб-оптимального
    наблюдателя с усилением $K$. "Наблюдатель с усилением K не может превзойти
    оптимальный фильтр Калмана" (cf. Prob. 14.4) - отсюда оптимальность
    (минимальность) $P_ss$.

    Наша `iter k riccati_step 0` - это в точности $P^degree_i$ (14.2.1), а
    `Pss = mx_mono_lim` - её предел $P^degree$. Эта же оценка снизу $P^degree_i$
    суб-оптимальным наблюдателем - основной шаг ограниченности в Theorem 14.5.1
    (см. также § 14.1.3, c. 502).
  *)
  Section FixedGainBound.

    (* Произвольное усиление `K` (не обязательно калмановское). *)
    Variable K : 'M[ℂ]_(n, p).

    (*
      Предсказательное усиление $K_p = F K$ и замкнутый контур наблюдателя
      $M = F - F K H = F (E - K H)$ (предикторная форма).
    *)
    Definition cl_gain : 'M[ℂ]_(n, p) := F *m K.
    Definition cl_loop : 'M[ℂ]_n := F - cl_gain *m H.
    Definition cl_weight : 'M[ℂ]_n :=
      G *m Q *m G^t* + cl_gain *m R *m cl_gain^t*.

    (* M = F (E − K H). *)
    Lemma cl_loop_factor : F *m (1%:M - K *m H) = cl_loop.
    Proof. by rewrite /cl_loop /cl_gain mulmxBr mulmx1 mulmxA. Qed.

    Lemma cl_weight_psd : psd cl_weight.
    Proof.
      rewrite /cl_weight; apply: psd_add.
      - exact: psd_lcongr G Q_psd.
      - exact: psd_lcongr cl_gain (pd_psd R_pd).
    Qed.

    (*
      Выделение полного квадрата (Lem 14.5.1 для произвольного `K`): один
      предсказательный шаг Риккати мажорируется замкнутым контуром наблюдателя.
      $"update_cov" <= "alt_update_cov"_K$
      (разность - конгруэнция неотрицательно определённых матриц $(K - K_kalman) R_e (dot)†$),
      далее монотонность `predict_cov` и тождество
      $F dot "alt_update_cov"_K (Sigma F† + G Q G†) = M Sigma M† + W$.
    *)
    Lemma pred_update_le (Sigma : 'M[ℂ]_n) :
      psd Sigma ->
      psd_le (predict_cov F G Q (update_cov H R Sigma))
             (cl_loop *m Sigma *m cl_loop^t* + cl_weight).
    Proof.
      move=> psdS.
      have hle : psd_le (update_cov H R Sigma) (alt_update_cov H R K Sigma).
        rewrite /psd_le (alt_update_cov_diff H R_pd K psdS).
        rewrite addrAC subrr add0r.
        exact: psd_lcongr (K - kalman_gain H R Sigma)
                          (pd_psd (innov_cov_pd H R_pd psdS)).
      have key := predict_cov_mono F G Q hle.
      have heq : predict_cov F G Q (alt_update_cov H R K Sigma)
               = cl_loop *m Sigma *m cl_loop^t* + cl_weight.
        have hsplit : forall Xa Xb : 'M[ℂ]_n,
            F *m (Xa + Xb) *m F^t* = F *m Xa *m F^t* + F *m Xb *m F^t*.
          by move=> Xa Xb; rewrite mulmxDr mulmxDl.
        have h1 : F *m ((1%:M - K *m H) *m Sigma *m (1%:M - K *m H)^t*) *m F^t*
                = cl_loop *m Sigma *m cl_loop^t*.
          by rewrite -cl_loop_factor trmxC_mul !mulmxA.
        have h2 : F *m (K *m R *m K^t*) *m F^t*
                = cl_gain *m R *m cl_gain^t*.
          by rewrite /cl_gain trmxC_mul !mulmxA.
        rewrite /predict_cov /alt_update_cov hsplit h1 h2 /cl_weight.
        by rewrite -addrA [cl_gain *m R *m cl_gain^t* + _]addrC.
      by rewrite heq in key.
    Qed.

    (* Предсказанная ковариация после k полных шагов из нуля. *)
    Definition Spred (k : nat) : 'M[ℂ]_n :=
      predict_cov F G Q (iter k (riccati_step F G H Q R) 0).

    Lemma Spred_psd k : psd (Spred k).
    Proof.
      apply: (predict_cov_psd F G Q_psd).
      exact: (riccati_iter0_psd F G H Q_psd R_pd k).
    Qed.

    Lemma Spred_recr k :
      Spred k.+1 = predict_cov F G Q (update_cov H R (Spred k)).
    Proof. by rewrite /Spred iterS /riccati_step. Qed.

    (*
      Spred k <= lyap_partial M W (k+1) - индукция через выделение полного
      квадрата + лево-конгруэнтную монотонность + сдвиг частичной суммы.
    *)
    Lemma Spred_le k :
      psd_le (Spred k) (lyap_partial cl_loop cl_weight k.+1).
    Proof.
      elim: k => [|k IH].
      - rewrite (lyap_partial_shift cl_loop cl_weight 0) lyap_partial0.
        rewrite mulmx0 mul0mx addr0.
        rewrite /Spred /= /predict_cov mulmx0 mul0mx add0r /cl_weight.
        rewrite -[X in psd_le X _]addr0.
        apply: psd_le_add2l.
        apply/psd_le0_psd.
        exact: psd_lcongr cl_gain (pd_psd R_pd).
      - rewrite Spred_recr.
        apply: (psd_le_trans (pred_update_le (Spred_psd k))).
        rewrite (lyap_partial_shift cl_loop cl_weight k.+1).
        rewrite [cl_loop *m Spred k *m cl_loop^t* + cl_weight]addrC.
        apply: psd_le_add2l.
        apply: psd_le_lcongr.
        exact: IH.
    Qed.

    (*
      Факт (b), конечная (грамианная) форма: нулевая Риккати-итерация <=
      конечный управляемый Грамиан замкнутого контура любого усиления `K`
      (= ковариация суб-оптимального наблюдателя).
    *)
    Theorem riccati_iter_le_lyap_partial k :
      psd_le (iter k (riccati_step F G H Q R) 0)
             (lyap_partial cl_loop cl_weight k).
    Proof.
      case: k => [|k].
      - rewrite lyap_partial0 /=; apply: psd_le_refl; exact: psd0.
      - rewrite iterS /riccati_step.
        apply: (psd_le_trans (B := Spred k)).
        + exact: (update_cov_le H R_pd (Spred_psd k)).
        + exact: Spred_le k.
    Qed.

    (*
      Установившаяся форма $Pi = "lyap_sol" M W$ при устойчивости по Шуру
      замкнутого контура наблюдателя $M$.
    *)
    Hypothesis K_stab : spec_rad_lt1 cl_loop.

    (* Факт (b), установившаяся форма: $P^degree_i <= Pi$ для всех i. *)
    Lemma riccati_iter_le_fixed_gain_lyap_sol k :
      psd_le (iter k (riccati_step F G H Q R) 0)
             (lyap_sol cl_loop cl_weight).
    Proof.
      apply: (psd_le_trans (riccati_iter_le_lyap_partial k)).
      exact: (lyap_partial_le_sol_schur ler_r2c c2rK c2r_continuous
                r2c_continuous ℂ_archi cl_weight_psd K_stab k).
    Qed.

  (*
    Оптимальность установившейся ковариации.

    Для любого стабилизирующего наблюдателя с усилением $K$ предельная
    ковариация $P_ss$ не превосходит установившуюся ковариацию ошибки этого
    наблюдателя в порядке Лёвнера.

    - @kailath2000[App. E, § E.4 "Properties of the Maximal Solution"].
  *)
    Theorem Pss_le_fixed_gain_lyap_sol :
      psd_le Pss (lyap_sol cl_loop cl_weight).
    Proof.
      apply: (@mx_mono_lim_le ℝ ℂ r2c c2r
              ler_r2c c2rK c2r_continuous r2c_continuous
              n Pseq (lyap_sol cl_loop cl_weight)
              Pseq_psd Pseq_mono).
      exact: riccati_iter_le_fixed_gain_lyap_sol.
    Qed.

  End FixedGainBound.

  (*
    Непрерывность шага Риккати на неотрицательно определённых входах.

    Используем элементарные леммы о непрерывности из mxtopo и riccati_cont
    (cvgn_invmx). Имена `predict_cov`, `innov_cov`, `update_cov`, `riccati_step`
    ниже относятся к kalman.v.
  *)
  Lemma cvgn_predict_cov_k (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L ->
    (fun k => predict_cov F G Q (Pf k)) @ \oo --> predict_cov F G Q L.
  Proof.
    move=> HP.
    rewrite /predict_cov; under eq_cvg=> k do rewrite /predict_cov.
    apply: cvgn_addmx; last exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    apply: cvgn_mulmx (cvg_cst _) HP.
  Qed.

  Lemma cvgn_innov_cov_k (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L ->
    (fun k => innov_cov H R (Pf k)) @ \oo --> innov_cov H R L.
  Proof.
    move=> HP.
    rewrite /innov_cov; under eq_cvg=> k do rewrite /innov_cov.
    apply: cvgn_addmx; last exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    apply: cvgn_mulmx (cvg_cst _) HP.
  Qed.

  Lemma cvgn_kalman_gain_k (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L -> innov_cov H R L \in unitmx ->
    (fun k => kalman_gain H R (Pf k)) @ \oo --> kalman_gain H R L.
  Proof.
    move=> HP Sunit.
    rewrite /kalman_gain; under eq_cvg=> k do rewrite /kalman_gain.
    apply: cvgn_mulmx.
    - apply: cvgn_mulmx HP _; exact: cvg_cst.
    - exact: riccati_cont.cvgn_invmx (cvgn_innov_cov_k HP) Sunit.
  Qed.

  Lemma cvgn_update_cov_k (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L -> innov_cov H R L \in unitmx ->
    (fun k => update_cov H R (Pf k)) @ \oo --> update_cov H R L.
  Proof.
    move=> HP Sunit.
    rewrite /update_cov; under eq_cvg=> k do rewrite /update_cov.
    apply: cvgn_mulmx; last exact: HP.
    apply: cvgn_submx; first exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    exact: cvgn_kalman_gain_k HP Sunit.
  Qed.

  Lemma cvgn_riccati_step_k (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L -> innov_cov H R (predict_cov F G Q L) \in unitmx ->
    (fun k => riccati_step F G H Q R (Pf k)) @ \oo -->
      riccati_step F G H Q R L.
  Proof.
    move=> HP Sunit.
    rewrite /riccati_step; under eq_cvg=> k do rewrite /riccati_step.
    apply: cvgn_update_cov_k Sunit.
    exact: cvgn_predict_cov_k.
  Qed.

  (*
    Неподвижная точка Риккати.

    $P_ss = "riccati_step"(P_ss)$.

    - @kailath2000[§ 14.5, Theorem 14.5.1 "Sufficiency"].
  *)

  Theorem Pss_fix : Pss = riccati_step F G H Q R Pss.
  Proof.
    (* Шаг 1: invertibility of innov_cov ∘ predict_cov at Pss *)
    have predPss_psd : psd (predict_cov F G Q Pss) := predict_cov_psd F G Q_psd Pss_psd.
    have Sunit : innov_cov H R (predict_cov F G Q Pss) \in unitmx
      := innov_cov_inv H R_pd predPss_psd.
    (* Шаг 2: сходимость к riccati_step Pss по непрерывности *)
    have HriccCvg : (fun k => riccati_step F G H Q R (Pseq k)) @ \oo -->
                    riccati_step F G H Q R Pss
      := cvgn_riccati_step_k Pss_cvgn Sunit.
    (* Шаг 3: `riccati_step (Pseq k) = Pseq k.+1` - сама определимость iter *)
    have eqf : (fun k => riccati_step F G H Q R (Pseq k))
            = (fun k => Pseq k.+1).
      by apply/funext=> k.
    rewrite eqf in HriccCvg.
    (*
      Шаг 4: `(fun k => Pseq k.+1) @ ∞ --> Pss` - сдвиг сходящейся
      последовательности. Используем `cvg_comp` с `addn 1 @ ∞ --> ∞` и
      переписываем `addn 1 = (fun k => k.+1)` через `add1n`.
    *)
    have HshiftCvg : (fun k : nat => Pseq k.+1) @ \oo --> Pss.
      have Hsh : addn 1 @ \oo --> (\oo : set_system nat) := cvg_addnl 1.
      have Hcomp : (Pseq \o addn 1) @ \oo --> Pss
        := cvg_comp (addn 1) Pseq Hsh Pss_cvgn.
      have eq_shift : Pseq \o addn 1 = (fun k => Pseq k.+1).
        by apply/funext=> k.
      by rewrite -eq_shift.
    (* Шаг 5: единственность предела в матричной топологии *)
    have HausM : hausdorff_space ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ).
      exact: norm_hausdorff.
    have HshiftCvg_n :
        ((fun k => Pseq k.+1) : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
          @ \oo --> (Pss : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)).
      exact: HshiftCvg.
    have HriccCvg_n :
        ((fun k => Pseq k.+1) : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
          @ \oo --> (riccati_step F G H Q R Pss
                      : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)).
      exact: HriccCvg.
    exact: (cvg_unique HausM HshiftCvg_n HriccCvg_n).
  Qed.

  (*
    Сводный результат: неотрицательно определённая неподвижная точка DARE.

    - @kailath2000[App. E, § E.3 "Existence of Solutions to the DARE"].
  *)
  Theorem dare_psd_sol :
    exists Pss0 : 'M[ℂ]_n,
      [/\ psd Pss0,
          Pss0 = riccati_step F G H Q R Pss0,
          Pseq @ \oo --> Pss0 &
          psd_le Pss0 Pbnd].
  Proof.
    exists Pss; split.
    - exact: Pss_psd.
    - exact: Pss_fix.
    - exact: Pss_cvgn.
    - exact: Pss_le_bnd.
  Qed.

  (*
    Тождества замкнутого контура для предсказанной ковариации $P_pss$.

    - @kailath2000[§ 14.5].
  *)

  (* Сокращения. *)
  Local Notation P_pss := (predict_cov F G Q Pss).
  Local Notation Kf := (kalman_gain H R P_pss).
  Local Notation Kp := (F *m Kf).
  Local Notation Fp := (F - Kp *m H).
  Local Notation R_e := (innov_cov H R P_pss).

  Lemma P_pss_psd : psd P_pss.
  Proof. apply: predict_cov_psd; [exact: Q_psd | exact: Pss_psd]. Qed.

  Lemma R_e_unit : R_e \in unitmx.
  Proof. apply: innov_cov_inv; [exact: R_pd | exact: P_pss_psd]. Qed.

  (* $P_ss = (E - "Kf" H) P_pss = "update_cov" P_pss$ (неподвижная точка). *)
  Lemma Pss_eq_update : Pss = update_cov H R P_pss.
  Proof.
    have := Pss_fix.
    by rewrite /riccati_step.
  Qed.

  (* Свёртка усиления: F (E - Kf H) = Fp. *)
  Lemma F_update_factor : F *m (1%:M - Kf *m H) = Fp.
  Proof.
    by rewrite mulmxBr mulmx1 mulmxA.
  Qed.

  (*
    Предиктор на неподвижной точке свёрнут на замкнутый контур:
    $P_pss = F_p P_pss F† + G Q G†$.
  *)
  Lemma predict_cov_closed_loop :
    predict_cov F G Q Pss = Fp *m P_pss *m F^t* + G *m Q *m G^t*.
  Proof.
    by rewrite {1}/predict_cov {1}Pss_eq_update /update_cov mulmxA F_update_factor.
  Qed.

  (* Важное перекрёстное тождество: $F_p P_pss H† = K_p R$. *)
  Lemma Fp_Ppss_Ht : Fp *m P_pss *m H^t* = Kp *m R.
  Proof.
    rewrite mulmxBl mulmxBl.
    rewrite -[F *m P_pss *m H^t*]mulmxA -(kalman_gain_normal_eq H R_pd P_pss_psd).
    rewrite mulmxA.
    rewrite /innov_cov mulmxDr !mulmxA.
    by rewrite addrAC subrr add0r.
  Qed.

  (*
    Тождество Ляпунова замкнутого контура для предсказанной ss-ковариации.

    - @kailath2000[§ 14.5, Theorem 14.5.1 "Sufficiency"].
  *)
  Theorem riccati_closed_loop_identity :
    predict_cov F G Q Pss =
      Fp *m predict_cov F G Q Pss *m Fp^t* +
      (F *m kalman_gain H R (predict_cov F G Q Pss)) *m R *m
        (F *m kalman_gain H R (predict_cov F G Q Pss))^t* +
      G *m Q *m G^t*.
  Proof.
    rewrite {1}predict_cov_closed_loop.
    congr (_ + _).
    have Fpt : Fp^t* = F^t* - H^t* *m Kp^t*.
      by rewrite trmxCB [(Kp *m H)^t*]trmxC_mul.
    have expand : Fp *m P_pss *m Fp^t*
                = Fp *m P_pss *m F^t* - Kp *m R *m Kp^t*.
      rewrite Fpt mulmxBr.
      congr (_ - _).
      by rewrite mulmxA Fp_Ppss_Ht.
    by rewrite expand subrK.
  Qed.

  (*
    Положительная определённость предела DARE.

    Полная управляемость пары $(F, G Q^(1\/2))$ влечёт $"Pss" succ 0$.

    - @kailath2000[App. E, Theorem E.6.2 "Positive Definite Solution"].
  *)
  Theorem Pss_pd :
    pd Pss.
  (*
    Предсказанная установившаяся ковариация
    $P_pss = F_p P_pss F_p† + (K_p R K_p† + G Q G†)$ есть неподвижная точка
    уравнения Ляпунова замкнутого контура; её положительную определённость даёт
    управляемость исходной пары $(F, G Q G†)$
    (коррекция по выходу управляемость не сохраняет, но перенос условия PBH на ядре даёт результат).
    Затем $P_ss = "update_cov" H R P_pss$ сохраняет положительную
    определённость.
  *)
  Proof.
    have Ppd : pd P_pss.
      apply: (controllable_oi_gram_pd (A := F) (Kp := Kp) (Hm := H)
                (Z := G *m Q *m G^t*) (R := R) GQGt_psd R_pd (P := P_pss)).
      - exact: P_pss_psd.
      - by rewrite {1}riccati_closed_loop_identity addrA.
      - exact: FG_ctrl.
    rewrite Pss_eq_update.
    apply: update_cov_pd; first exact: R_pd.
    exact: Ppd.
  Qed.

  (*
    Сходимость с произвольного неотрицательно определённого начала + сходимость
    коэффициента усиления Калмана + единственность положительно определённой
    неподвижной точки.

    `riccati_iter_cvgn` («глобальная сходимость»): итерация ДАУР из любого
    неотрицательно определённого начала сходится к $P_ss$ в матричной топологии.
    Это стандартный результат классической теории ДАУР, требующий устойчивости
    замкнутого контура; у нас он доказан (теорема ниже) через суперрешение +
    теорема о двух милиционерах при спектральной устойчивости по Шуру
    `spec_rad_lt1 Mc`.

    - @kailath2000[§ 14.5].

    Из него немедленно следуют:
    1.  Сходимость усиления Калмана
        (по непрерывности `kalman_gain ∘ predict_cov`) - `Pss_gain_cvgn`.
    2.  Единственность положительно определённой неподвижной точки: любая
        положительно определённая неподвижная точка `Pi`
        (как константная последовательность) сходится к самой себе и
        одновременно к $P_ss$, откуда `Pi = Pss`
        (Хаусдорфовость матричной топологии) - `Pss_unique_pd`.
  *)

  (*
    Глобальная сходимость через суперрешение + теорему о двух милиционерах.

    Схема: показываем, что $X_oo + a Y_oo$
    ($X_oo := "lyap_sol" M_c W_c$, $Y_oo := "lyap_sol" M_c E$, $a >= 0$) -
    суперрешение, то есть $"riccati_step"(X_oo + a Y_oo) <= X_oo + a Y_oo$
    (`riccati_step_supersol`). Тогда верхняя траектория
    $"iter"_k "riccati_step"(X_oo + a Y_oo)$ монотонно убывает
    (в порядке Лёвнера) и сходится к неподвижной точке $L$
    (через mxmonotone.mx_mono_dec_cvgn). По единственности положительно
    определённой неподвижной точки `Pss_unique` имеем $L = P_ss$. Для
    произвольного неотрицательно определённого $P_0$ берём $a := "tr" P_0$
    (тогда $P_0 <= a E <= a Y_oo <= X_oo + a Y_oo$, т.к. $E <= Y_oo$); теорема о
    двух милиционерах с `iter k r.s. 0` и оценкой $"frob_sq" <= ("tr")^2$ даёт
    сходимость к $P_ss$. Суперрешение работает при спектральной устойчивости по
    Шуру замкнутого контура `spec_rad_lt1 Mc`
    (а не системной $"frob_sq" F < 1$): возмущение по Ляпунову $Y_oo$ заменяет
    скаляр $E$, не требуя оценки операторной нормы $M_c$.

    Единственность положительно определённой неподвижной точки. Классический
    результат теории ДАУР: любая положительно определённая неподвижная точка
    совпадает с Pss. Доказана через Lemma 14.4.1 (Local Identities) для разности
    двух решений `riccati_step_fix_unique` (riccati_unique.v): разность
    предсказанных ковариаций удовлетворяет
    $M_1 - M_2 = F_p(M_1)(M_1 - M_2)F_p(M_2)†$ с обоими устойчивыми по Шуру
    контурами (`lyap_inv_spec_rad`), откуда `lyap_two_sided_zero_schur` даёт
    ноль.

    - @kailath2000[§ 14.5].
  *)
  Lemma Pss_unique (L : 'M[ℂ]_n) :
    psd L -> L = riccati_step F G H Q R L -> L = Pss.
  Proof.
    move=> HL Hf.
    exact: (riccati_step_fix_unique ℂ_archi Q_psd R_pd FG_stab
              HL (pd_psd Pss_pd) Hf Pss_fix).
  Qed.

  (*
    Суперрешение Риккати: $"lyap_sol" M_c W_c + a dot "lyap_sol" M_c E$
    ($a >= 0$).

    $X_oo := "lyap_sol" M_c W_c$ - решение уравнения Ляпунова замкнутого контура
    $X_oo = M_c X_oo M_c† + W_c$; $Y_oo := "lyap_sol" M_c E$ - положительно
    определённое возмущение, $Y_oo = M_c Y_oo M_c† + E >= E$. Тогда для любого
    вещественного $a >= 0$ матрица $X_oo + a Y_oo$ - суперрешение:
    $ "riccati_step" (X_oo + a Y_oo) <= M_c (X_oo + a Y_oo) M_c† + W_c \ = X_oo + a (M_c Y_oo M_c†) = X_oo + a (Y_oo - E) \ = (X_oo + a Y_oo) - a E <= X_oo + a Y_oo. $
    Схема: возмущение по Ляпунову `Yinf` (а не скаляр на `E`) делает
    суперрешение корректным при устойчивости по Шуру `spec_rad_lt1 Mc`.
  *)

  Local Notation Xinf := (lyap_sol Mc Wc).
  Local Notation Yinf := (lyap_sol Mc 1%:M).

  Lemma Xinf_psd : psd Xinf.
  Proof.
    exact: (lyap_sol_psd_schur ler_r2c c2rK c2r_continuous r2c_continuous
              ℂ_archi Wc_psd Mc_schur).
  Qed.

  Lemma Xinf_fix : Xinf = Mc *m Xinf *m Mc^t* + Wc.
  Proof.
    exact: (lyap_sol_fix_schur ler_r2c c2rK r2c_continuous
              ℂ_archi Wc_psd Mc_schur).
  Qed.

  Lemma Yinf_psd :
    psd Yinf.
  Proof.
    apply: (lyap_sol_psd_schur ler_r2c c2rK c2r_continuous r2c_continuous ℂ_archi);
      [exact: pd_psd (pd1 ℂ n) | exact: Mc_schur].
  Qed.

  Lemma Yinf_fix :
    Yinf = Mc *m Yinf *m Mc^t* + 1%:M.
  Proof.
    apply: (lyap_sol_fix_schur ler_r2c c2rK r2c_continuous ℂ_archi);
      [exact: pd_psd (pd1 ℂ n) | exact: Mc_schur].
  Qed.

  (* Yinf >= E (нижняя оценка - позволит `a Yinf` мажорировать любое `P0`). *)
  Lemma I_le_Yinf :
    psd_le (1%:M : 'M[ℂ]_n) Yinf.
  Proof.
    rewrite /psd_le {1}Yinf_fix addrK.
    exact: psd_lcongr Mc Yinf_psd.
  Qed.

  (* Главная техническая лемма: $X_oo + a Y_oo$ - суперрешение Риккати. *)
  Lemma riccati_step_supersol (a : ℂ) :
    a \is Num.real -> 0 <= a ->
    psd_le (riccati_step F G H Q R (Xinf + a *: Yinf)) (Xinf + a *: Yinf).
  Proof.
    move=> a_real a_ge0.
    have psdS : psd (Xinf + a *: Yinf).
      apply: psd_add; [exact: Xinf_psd | exact: psd_scaler a_real a_ge0 Yinf_psd].
    apply: (psd_le_trans (riccati_step_le_Mc psdS)).
    (* Mc (Xinf + a Yinf) Mc† + Wc = Xinf + a Yinf − a E. *)
    have expand : Mc *m (Xinf + a *: Yinf) *m Mc^t* + Wc
                = Xinf + a *: Yinf - a *: 1%:M.
      rewrite mulmxDr mulmxDl.
      have eqaY : Mc *m (a *: Yinf) *m Mc^t* = a *: (Mc *m Yinf *m Mc^t*).
        by rewrite -scalemxAr -scalemxAl.
      rewrite eqaY.
      rewrite [Mc *m Xinf *m Mc^t* + a *: (Mc *m Yinf *m Mc^t*) + Wc]addrAC.
      rewrite -Xinf_fix.
      have eqY : Mc *m Yinf *m Mc^t* = Yinf - 1%:M.
        by rewrite {2}Yinf_fix addrK.
      by rewrite eqY scalerBr scalemx1 addrA.
    rewrite expand /psd_le.
    have ->: (Xinf + a *: Yinf) - (Xinf + a *: Yinf - a *: 1%:M) = a *: 1%:M.
      by rewrite opprB addrCA subrr addr0.
    exact: psd_scale1 a_real a_ge0.
  Qed.

  (*
    Верхняя траектория из $X_oo + a E$ монотонно убывает к Pss
    (через mx_mono_dec_cvgn + Pss_unique).

    Неотрицательная определённость и монотонное убывание для любого
    вещественного $a >= 0$.
  *)
  Lemma Pup_psd (a : ℂ) (a_real : a \is Num.real) (a_ge0 : 0 <= a)
      (k : nat) :
    psd (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)).
  Proof.
    elim: k => [|k IH] /=.
    - apply: psd_add; [exact: Xinf_psd | exact: psd_scaler a_real a_ge0 Yinf_psd].
    - by apply: riccati_step_psd; [exact: Q_psd | exact: R_pd | exact: IH].
  Qed.

  Lemma Pup_anti (a : ℂ) (a_real : a \is Num.real) (a_ge0 : 0 <= a)
      (k : nat) :
    psd_le (iter k.+1 (riccati_step F G H Q R) (Xinf + a *: Yinf))
          (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)).
  Proof.
    elim: k => [|k IH] /=.
    - exact: riccati_step_supersol a_real a_ge0.
    - have psd_k : psd (iter k.+1 (riccati_step F G H Q R) (Xinf + a *: Yinf))
        := Pup_psd a_real a_ge0 k.+1.
      have psd_Sk : psd (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf))
        := Pup_psd a_real a_ge0 k.
      by apply: riccati_step_mono; [exact: Q_psd | exact: R_pd |
                                    exact: psd_k | exact: psd_Sk | exact: IH].
  Qed.

  (* Предел верхней траектории. *)
  Definition Pup_lim (a : ℂ) (a_real : a \is Num.real)
      (a_ge0 : 0 <= a) : 'M[ℂ]_n :=
    mx_mono_dec_lim
      (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)).

  Lemma Pup_cvgn (a : ℂ) (a_real : a \is Num.real) (a_ge0 : 0 <= a) :
    (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)) @ \oo -->
    Pup_lim a_real a_ge0.
  Proof.
    rewrite /Pup_lim.
    apply: mx_mono_dec_cvgn;
      [exact: ler_r2c | exact: c2rK | exact: r2c_continuous
      | exact: (Pup_psd a_real a_ge0) | exact: (Pup_anti a_real a_ge0)].
  Qed.

  Lemma Pup_lim_psd (a : ℂ) (a_real : a \is Num.real)
      (a_ge0 : 0 <= a) : psd (Pup_lim a_real a_ge0).
  Proof.
    exact: (@mx_mono_dec_lim_psd ℝ ℂ r2c c2r
              ler_r2c c2rK c2r_continuous r2c_continuous
              n (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf))
              (Pup_psd a_real a_ge0) (Pup_anti a_real a_ge0)).
  Qed.

  (* Pup_lim - неподвижная точка riccati_step (по непрерывности). *)
  Lemma Pup_lim_fix (a : ℂ) (a_real : a \is Num.real)
      (a_ge0 : 0 <= a) :
    Pup_lim a_real a_ge0 = riccati_step F G H Q R (Pup_lim a_real a_ge0).
  Proof.
    set L := Pup_lim a_real a_ge0.
    have Lpsd : psd L := Pup_lim_psd a_real a_ge0.
    have Hcvg : (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf))
                  @ \oo --> L.
      exact: Pup_cvgn a_real a_ge0.
    have predL_psd : psd (predict_cov F G Q L)
      by apply: predict_cov_psd; [exact: Q_psd | exact: Lpsd].
    have Sunit : innov_cov H R (predict_cov F G Q L) \in unitmx
      := innov_cov_inv H R_pd predL_psd.
    have HriccCvg :
        (fun k => riccati_step F G H Q R
                      (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)))
          @ \oo --> riccati_step F G H Q R L
      := cvgn_riccati_step_k Hcvg Sunit.
    have eqf :
        (fun k => riccati_step F G H Q R
                    (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)))
      = (fun k => iter k.+1 (riccati_step F G H Q R) (Xinf + a *: Yinf)).
      by apply/funext.
    rewrite eqf in HriccCvg.
    have HshiftCvg :
        (fun k : nat => iter k.+1 (riccati_step F G H Q R) (Xinf + a *: Yinf))
          @ \oo --> L.
      have Hsh : addn 1 @ \oo --> (\oo : set_system nat) := cvg_addnl 1.
      have Hcomp :
          ((fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)) \o addn 1)
            @ \oo --> L
        := cvg_comp (addn 1)
                    (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf))
                    Hsh Hcvg.
      have eq_shift :
          (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)) \o addn 1
        = (fun k => iter k.+1 (riccati_step F G H Q R) (Xinf + a *: Yinf)).
        by apply/funext.
      by rewrite -eq_shift.
    have HausM : hausdorff_space ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)
      by exact: norm_hausdorff.
    have HshiftCvg_n :
        ((fun k => iter k.+1 (riccati_step F G H Q R) (Xinf + a *: Yinf))
          : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
          @ \oo --> (L : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      := HshiftCvg.
    have HriccCvg_n :
        ((fun k => iter k.+1 (riccati_step F G H Q R) (Xinf + a *: Yinf))
          : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
          @ \oo --> (riccati_step F G H Q R L
                      : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      := HriccCvg.
    exact: (cvg_unique HausM HshiftCvg_n HriccCvg_n).
  Qed.

  (*
    Главное следствие: Pup_lim = Pss. Единственность неотрицательно определённой
    неподвижной точки (`Pss_unique`) - `Pup_lim` неотрицательно определена
    (`Pup_lim_psd`) и неподвижна (`Pup_lim_fix`).
  *)
  Lemma Pup_lim_eq_Pss (a : ℂ) (a_real : a \is Num.real)
      (a_ge0 : 0 <= a) : Pup_lim a_real a_ge0 = Pss.
  Proof.
    apply: Pss_unique.
    - exact: Pup_lim_psd a_real a_ge0.
    - exact: Pup_lim_fix a_real a_ge0.
  Qed.

  (* Сходимость самой верхней траектории к Pss. *)
  Lemma Pup_cvgn_Pss (a : ℂ) (a_real : a \is Num.real)
      (a_ge0 : 0 <= a) :
    (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)) @ \oo --> Pss.
  Proof.
    have := @Pup_cvgn a a_real a_ge0.
    by rewrite (Pup_lim_eq_Pss a_real a_ge0).
  Qed.

  (*
    Для произвольного неотрицательно определённого P0 - сходимость к Pss.
    Выбираем a := tr P0; тогда P0 <= a E <= Xinf + a E (начальное суперрешение),
    теорема о двух милиционерах с нижней (Pseq) и верхней (Pup) траекториями.

    - @kailath2000[§ 14.5, Theorem 14.5.1 "A Sufficiency Result"].
  *)
  Theorem riccati_iter_cvgn (P0 : 'M[ℂ]_n) (HP0 : psd P0) :
    (fun k => iter k (riccati_step F G H Q R) P0) @ \oo --> Pss.
  Proof.
    pose a : ℂ := \tr P0.
    have a_ge0 : 0 <= a := psd_tr_ge0 HP0.
    have a_real : a \is Num.real by exact: ger0_real.
    (* P0 <= a E <= a Yinf <= Xinf + a Yinf (старт верхней траектории). *)
    have P0_le_aI : psd_le P0 (a *: (1%:M : 'M[ℂ]_n)) := psd_le_trace_id HP0.
    have HXinf0 : psd_le 0 Xinf by apply/psd_le0_psd; exact: Xinf_psd.
    have aI_le_aY : psd_le (a *: (1%:M : 'M[ℂ]_n)) (a *: Yinf)
      := psd_le_scaler a_real a_ge0 I_le_Yinf.
    have aY_le_Psup : psd_le (a *: Yinf) (Xinf + a *: Yinf).
      have h := psd_le_add2r (a *: Yinf) HXinf0.
      by rewrite add0r in h.
    have P0_le_Psup : psd_le P0 (Xinf + a *: Yinf)
      := psd_le_trans P0_le_aI (psd_le_trans aI_le_aY aY_le_Psup).
    (*
      Теорема о двух милиционерах:
      $"iter"_k "r.s." 0 <= "iter"_k "r.s." P_0 <= "iter"_k "r.s."(X_oo + a E)$
    *)
    have Pseq_le_iterP0 : forall k,
      psd_le (iter k (riccati_step F G H Q R) 0)
            (iter k (riccati_step F G H Q R) P0).
      elim=> [|k IH] /=.
      - by apply/psd_le0_psd.
      - have psd_L : psd (iter k (riccati_step F G H Q R) 0) := Pseq_psd k.
        have psd_M : psd (iter k (riccati_step F G H Q R) P0)
          := riccati_iter_psd F G H Q_psd R_pd k HP0.
        by apply: riccati_step_mono;
          [exact: Q_psd | exact: R_pd | exact: psd_L | exact: psd_M | exact: IH].
    have iterP0_le_Pup : forall k,
      psd_le (iter k (riccati_step F G H Q R) P0)
            (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)).
      elim=> [|k IH] /=; first exact: P0_le_Psup.
      have psd_M : psd (iter k (riccati_step F G H Q R) P0)
        := riccati_iter_psd F G H Q_psd R_pd k HP0.
      have psd_U : psd (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf))
        := Pup_psd a_real a_ge0 k.
      by apply: riccati_step_mono;
        [exact: Q_psd | exact: R_pd | exact: psd_M | exact: psd_U | exact: IH].
    (* Сходимости низа и верха к Pss. *)
    have Lcvg : (fun k => iter k (riccati_step F G H Q R) 0) @ \oo --> Pss
      := Pss_cvgn.
    have Ucvg : (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf))
                  @ \oo --> Pss
      := Pup_cvgn_Pss a_real a_ge0.
    (* Разность верхней и нижней траекторий сходится к 0. *)
    have UL_cvg :
        (fun k => iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)
                - iter k (riccati_step F G H Q R) 0) @ \oo --> (0 : 'M[ℂ]_n).
      have := cvgn_submx Ucvg Lcvg.
      by rewrite subrr.
    (* tr(U_k - L_k) -> 0. *)
    have trUL_cvg :
        (fun k => \tr (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)
                      - iter k (riccati_step F G H Q R) 0))
          @ \oo --> (\tr (0 : 'M[ℂ]_n)).
      exact: cvgn_mxtrace UL_cvg.
    have trUL_cvg0 :
        (fun k => \tr (iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)
                      - iter k (riccati_step F G H Q R) 0))
          @ \oo --> (0 : ℂ).
      have htr0 : \tr (0 : 'M[ℂ]_n) = (0 : ℂ) by rewrite mxtrace0.
      by rewrite -htr0.
    (* tr(X_k - L_k) -> 0 через теорему о двух милиционерах. *)
    pose XL k := iter k (riccati_step F G H Q R) P0
                - iter k (riccati_step F G H Q R) 0.
    pose UL k := iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)
                - iter k (riccati_step F G H Q R) 0.
    have XL_psd : forall k, psd (XL k).
      by move=> k; rewrite /XL; exact: Pseq_le_iterP0.
    have XL_le_UL : forall k, \tr (XL k) <= \tr (UL k).
      move=> k.
      apply: psd_le_trace.
      rewrite /XL /UL.
      have ->: iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)
            - iter k (riccati_step F G H Q R) 0
            - (iter k (riccati_step F G H Q R) P0
                - iter k (riccati_step F G H Q R) 0)
            = iter k (riccati_step F G H Q R) (Xinf + a *: Yinf)
              - iter k (riccati_step F G H Q R) P0.
        by rewrite opprB addrA subrK.
      exact: iterP0_le_Pup.
    have trXL_cvg0 : (fun k => \tr (XL k)) @ \oo --> (0 : ℂ).
      apply: (cvgC_le0_squeeze (t := fun k => \tr (UL k))).
      - by move=> k; apply: psd_tr_ge0; exact: XL_psd.
      - exact: XL_le_UL.
      - exact: trUL_cvg0.
    (* frob_sq (XL k) <= (tr(XL k))² -> 0. *)
    have frob_XL_cvg0 :
        (fun k => frob_sq (XL k)) @ \oo --> (0 : ℂ).
      apply: (cvgC_le0_squeeze (t := fun k => (\tr (XL k)) ^+ 2)).
      - by move=> k; exact: frob_sq_ge0.
      - by move=> k; apply: frob_sq_le_tr_sq; exact: XL_psd.
      - (* (tr(XL k))² -> 0² = 0. *)
        have trXL_cvg0_o :
            ((fun k => \tr (XL k)) : nat -> ℂ^o) @ \oo --> (0 : ℂ^o)
          := trXL_cvg0.
        have Hmul0 : (fun k => \tr (XL k) * \tr (XL k)) @ \oo --> (0 : ℂ^o).
          have HM := cvgM trXL_cvg0_o trXL_cvg0_o.
          rewrite mulr0 in HM.
          exact: HM.
        suff -> : (fun k : nat => (\tr (XL k)) ^+ 2)
                = (fun k => \tr (XL k) * \tr (XL k)) by exact: Hmul0.
        by apply/funext=> k; rewrite expr2.
    (* X_k - L_k -> 0 в матричной топологии. *)
    have XL_cvg :
        (fun k => XL k) @ \oo --> (0 : 'M[ℂ]_n).
      have := @frob_sq_cvgn0_to_mxcvgn ℂ n n XL (0 : 'M[ℂ]_n).
      apply.
      by under eq_cvg=> k do rewrite subr0.
    (* iter k r.s. P0 = XL k + iter k r.s. 0 -> 0 + Pss = Pss. *)
    have decomp :
        (fun k => iter k (riccati_step F G H Q R) P0)
      = (fun k => XL k + iter k (riccati_step F G H Q R) 0).
      apply/funext=> k; rewrite /XL.
      by rewrite subrK.
    rewrite decomp.
    have := cvgn_addmx XL_cvg Lcvg.
    by rewrite add0r.
  Qed.

  (*
    Сходимость матрицы усиления Калмана в матричной топологии.

    Усиление Калмана, вычисленное по $"iter" k thin "riccati_step" thin P_0$,
    сходится к $K_(s s) := "kalman_gain"("predict_cov" P_ss$.

    - @kailath2000[§ 14.5, Theorem 14.5.1 "Sufficiency"].
  *)
  Theorem Pss_gain_cvgn (P0 : 'M[ℂ]_n) (HP0 : psd P0) :
    (fun k => kalman_gain H R
                (predict_cov F G Q
                  (iter k (riccati_step F G H Q R) P0)))
      @ \oo --> kalman_gain H R (predict_cov F G Q Pss).
  Proof.
    have HPcvg := riccati_iter_cvgn HP0.
    have HpredCvg :
      (fun k => predict_cov F G Q (iter k (riccati_step F G H Q R) P0))
        @ \oo --> predict_cov F G Q Pss
      := cvgn_predict_cov_k HPcvg.
    have predPss_psd : psd (predict_cov F G Q Pss)
      := predict_cov_psd F G Q_psd Pss_psd.
    have Sunit : innov_cov H R (predict_cov F G Q Pss) \in unitmx
      := innov_cov_inv H R_pd predPss_psd.
    exact: cvgn_kalman_gain_k HpredCvg Sunit.
  Qed.

  (*
    Единственность положительно определённой неподвижной точки.

    Если $P_i succ 0$ и $P_i = "riccati_step"(P_i)$, то $P_i = P_ss$.

    - @kailath2000[App. E, Theorem E.5.1 "Algebraic Riccati Equation"].
  *)
  Theorem Pss_unique_pd (Pi : 'M[ℂ]_n) :
    pd Pi -> Pi = riccati_step F G H Q R Pi -> Pi = Pss.
  Proof.
    move=> HPi_pd Hfp.
    (* $"iter"_k "riccati_step" Pi = Pi$ для всех k (Pi - неподвижная точка). *)
    have HiterPi : forall k, iter k (riccati_step F G H Q R) Pi = Pi.
      by elim=> [//|k IH] /=; rewrite IH -Hfp.
    (* Константная последовательность Pi сходится к Pi. *)
    have HconstCvg :
        (fun k => iter k (riccati_step F G H Q R) Pi) @ \oo --> Pi.
      have Heq : (fun k => iter k (riccati_step F G H Q R) Pi)
              = (fun _ : nat => Pi)
        by apply/funext=> k; exact: HiterPi.
      by rewrite Heq; exact: cvg_cst.
    (* Та же последовательность сходится к Pss по `riccati_iter_cvgn`. *)
    have HarbCvg :
        (fun k => iter k (riccati_step F G H Q R) Pi) @ \oo --> Pss
      := riccati_iter_cvgn (pd_psd HPi_pd).
    (* Хаусдорфова единственность предела в матричной топологии. *)
    have HausM : hausdorff_space ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ).
      exact: norm_hausdorff.
    have HconstCvg_n :
        ((fun k => iter k (riccati_step F G H Q R) Pi)
          : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
          @ \oo --> (Pi : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      := HconstCvg.
    have HarbCvg_n :
        ((fun k => iter k (riccati_step F G H Q R) Pi)
          : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
          @ \oo --> (Pss : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      := HarbCvg.
    exact: (cvg_unique HausM HconstCvg_n HarbCvg_n).
  Qed.

  (*
    Сводный результат: полная теорема о DARE.

    - @kailath2000[App. E, Theorem E.5.1 "Algebraic Riccati Equation"].
  *)
  Theorem dare_stabilizing_sol :
    exists Pss0 : 'M[ℂ]_n,
      [/\ Pss0 = riccati_step F G H Q R Pss0,
          pd Pss0,
          psd_le Pss0 Pbnd,
          (forall P0, psd P0 ->
            (fun k => iter k (riccati_step F G H Q R) P0) @ \oo --> Pss0) &
          (forall Pi, pd Pi -> Pi = riccati_step F G H Q R Pi -> Pi = Pss0)].
  Proof.
    exists Pss; split.
    - exact: Pss_fix.
    - exact: Pss_pd.
    - exact: Pss_le_bnd.
    - by move=> P0 HP0; exact: riccati_iter_cvgn.
    - exact: Pss_unique_pd.
  Qed.

  (*
    От топологической сходимости к $epsilon$--$N$ форме.

    Если $P_k -> L$ в матричной топологии, то для любого $epsilon > 0$
    существует $N$, начиная с которого $"Tr"((P_k - L)† (P_k - L)) < epsilon$.

    - @kailath2000[§ 14.5, Theorem 14.5.1 "Sufficiency"].
  *)
  Lemma cvgn_frob_sq_eps_N r c
      (Pf : nat -> 'M[ℂ]_(r, c)) (L : 'M[ℂ]_(r, c)) :
    Pf @ \oo --> L ->
    forall eps : ℂ, 0 < eps ->
      exists N : nat, forall k, (N <= k)%N ->
        \tr ((Pf k - L)^t* *m (Pf k - L)) < eps.
  (*
    1.  $P_k - L -> 0$ (через $"cvgn_submx"$ и сходимость постоянной);
    2.  $(P_k - L)† -> 0$ (через $"cvgn_trmxC"$);
    3.  $(P_k - L)† (P_k - L) -> 0$ (через $"cvgn_mulmx"$);
    4.  $"Tr"((P_k - L)† (P_k - L)) -> 0$ (через $"cvgn_mxtrace"$);
    5.  переход к скалярному типу и оценка расстояния дают
        $|"Tr"(dots)| < epsilon$ в окрестности бесконечности;
    6.  неотрицательность квадрата нормы Фробениуса снимает модуль, а фильтр по
        натуральному ряду раскрывается в $exists N$, $forall k >= N$.
  *)
  Proof.
    move=> HPcvg eps eps_pos.
    have FF : Filter (\oo : set_system nat) by typeclasses eauto.
    have HsubCvg :
        ((fun k => Pf k - L) : nat -> 'M[ℂ]_(r, c)) @ \oo -->
          (0 : 'M[ℂ]_(r, c)).
      have HLcst : ((fun _ : nat => L) : nat -> 'M[ℂ]_(r, c)) @ \oo --> L
        by exact: cvg_cst.
      have HD := cvgn_submx HPcvg HLcst.
      by rewrite subrr in HD.
    have Htr0 :
        ((fun k => (Pf k - L)^t*) : nat -> 'M[ℂ]_(c, r)) @ \oo -->
          (0 : 'M[ℂ]_(c, r)).
      have := cvgn_trmxC HsubCvg.
      by rewrite trmxC0.
    have HmulCvg :
        ((fun k => (Pf k - L)^t* *m (Pf k - L)) : nat -> 'M[ℂ]_c) @ \oo -->
          (0 : 'M[ℂ]_c).
      have := cvgn_mulmx Htr0 HsubCvg.
      by rewrite mulmx0.
    have HtraceCvg :
        (fun k => \tr ((Pf k - L)^t* *m (Pf k - L))) @ \oo -->
          (\tr (0 : 'M[ℂ]_c)).
      exact: cvgn_mxtrace HmulCvg.
    have HtraceCvg0 :
        (fun k => \tr ((Pf k - L)^t* *m (Pf k - L))) @ \oo --> (0 : ℂ).
      have Htr0c : \tr (0 : 'M[ℂ]_c) = (0 : ℂ) by rewrite mxtrace0.
      by rewrite -Htr0c.
    have HtraceCvg_o :
        ((fun k => \tr ((Pf k - L)^t* *m (Pf k - L))) : nat -> ℂ^o) @ \oo -->
          (0 : ℂ^o)
      := HtraceCvg0.
    have /cvgrPdistC_lt /(_ eps eps_pos) Hnear := HtraceCvg_o.
    case: Hnear => N _ HN.
    exists N => k Hk.
    have := HN k Hk; rewrite /= subr0 => Hnorm.
    have Hpos : 0 <= \tr ((Pf k - L)^t* *m (Pf k - L))
      := frob_sq_ge0 (Pf k - L).
    by rewrite -(ger0_norm Hpos).
  Qed.

  (*
    Сходимость в стационарный режим (полная форма).

    Объединение положительно определённой неподвижной точки и $epsilon$--$N$
    сходимости как траектории, так и матрицы усиления.

    - @kailath2000[App. E, Theorem E.5.1 "Algebraic Riccati Equation"];
    - @kailath2000[§ 14.5, Theorem 14.5.1 "A Sufficiency Result"].
  *)
  Theorem dare_stabilizing_sol_frob :
    exists Pss0 : 'M[ℂ]_n,
      Pss0 = riccati_step F G H Q R Pss0 /\ pd Pss0 /\
      forall (P0 : 'M[ℂ]_n), psd P0 ->
        (forall eps : ℂ, eps > 0 ->
          exists N : nat, forall k, (N <= k)%N ->
            \tr ((iter k (riccati_step F G H Q R) P0 - Pss0)^t* *m
                (iter k (riccati_step F G H Q R) P0 - Pss0)) < eps) /\
        (forall eps : ℂ, eps > 0 ->
          exists N : nat, forall k, (N <= k)%N ->
            \tr ((kalman_gain H R
                    (predict_cov F G Q
                      (iter k (riccati_step F G H Q R) P0)) -
                  kalman_gain H R (predict_cov F G Q Pss0))^t* *m
                (kalman_gain H R
                    (predict_cov F G Q
                      (iter k (riccati_step F G H Q R) P0)) -
                  kalman_gain H R (predict_cov F G Q Pss0))) < eps).
  Proof.
    exists Pss; split; first exact: Pss_fix.
    split; first exact: Pss_pd.
    move=> P0 HP0; split.
    - exact: cvgn_frob_sq_eps_N (riccati_iter_cvgn HP0).
    - exact: cvgn_frob_sq_eps_N (Pss_gain_cvgn HP0).
  Qed.

  (*
    Сходимость матрицы усиления Калмана по норме Фробениуса.

    Главный результат проекта: формальная гарантия того, что вычисление усиления
    Калмана в стационарном режиме даёт сколь угодно точное приближение по норме
    Фробениуса к предельному значению.

    - @kailath2000[§ 14.5, Theorem 14.5.1 "Sufficiency"].
  *)
  Theorem kalman_gain_frob_cvgn (P0 : 'M[ℂ]_n) :
    psd P0 ->
    exists (Pss0 : 'M[ℂ]_n) (Kp : 'M[ℂ]_(n, p)),
      [/\ Pss0 = riccati_step F G H Q R Pss0,
          pd Pss0,
          Kp = kalman_gain H R (predict_cov F G Q Pss0) &
          forall eps : ℂ, eps > 0 ->
            exists N : nat, forall k, (N <= k)%N ->
              \tr ((kalman_gain H R
                      (predict_cov F G Q
                        (iter k (riccati_step F G H Q R) P0)) - Kp)^t* *m
                  (kalman_gain H R
                      (predict_cov F G Q
                        (iter k (riccati_step F G H Q R) P0)) - Kp)) < eps].
  Proof.
    move=> HP0.
    exists Pss, (kalman_gain H R (predict_cov F G Q Pss)); split.
    - exact: Pss_fix.
    - exact: Pss_pd.
    - by [].
    - exact: cvgn_frob_sq_eps_N (Pss_gain_cvgn HP0).
  Qed.

  (*
    Сходимость траектории Риккати в форме Фробениуса.

    - @kailath2000[§ 14.5, Theorem 14.5.1 "Sufficiency"].
  *)
  Theorem riccati_frob_cvgn (P0 : 'M[ℂ]_n) :
    psd P0 ->
    exists Pss0 : 'M[ℂ]_n,
      [/\ Pss0 = riccati_step F G H Q R Pss0,
          pd Pss0 &
          forall eps : ℂ, eps > 0 ->
            exists N : nat, forall k, (N <= k)%N ->
              \tr ((iter k (riccati_step F G H Q R) P0 - Pss0)^t* *m
                  (iter k (riccati_step F G H Q R) P0 - Pss0)) < eps].
  Proof.
    move=> HP0.
    exists Pss; split.
    - exact: Pss_fix.
    - exact: Pss_pd.
    - exact: cvgn_frob_sq_eps_N (riccati_iter_cvgn HP0).
  Qed.

  (*
    Стабильность замкнутого контура F_p.
    $P_pss = F_p dot P_pss dot F_p† + K_p dot R dot K_p† + G dot Q dot G†$. где:
    - P_pss = predict_cov Pss = F Pss F† + GQG†
      (предсказательная ss-ковариация),
    - Kf = kalman_gain P_pss (усиление фильтра),
    - Kp = F ⋅ Kf (предсказательное усиление),
    - Fp = F - Kp ⋅ H (замкнутый контур в предикторной форме).

    Откуда непосредственно следует сжатие в порядке Лёвнера.

    - @kailath2000[§ 14.5]:
  *)

  (* Сжатие в порядке Лёвнера: Fp P_pss Fp† <= P_pss. *)
  Theorem Fp_Ppss_le :
    psd_le (Fp *m P_pss *m Fp^t*) P_pss.
  Proof.
    rewrite /psd_le.
    rewrite {1}riccati_closed_loop_identity.
    have ->: Fp *m P_pss *m Fp^t* + Kp *m R *m Kp^t* + G *m Q *m G^t*
          - Fp *m P_pss *m Fp^t*
          = Kp *m R *m Kp^t* + G *m Q *m G^t*.
      set X := Fp *m P_pss *m Fp^t*.
      set Y := Kp *m R *m Kp^t*.
      set Z := G *m Q *m G^t*.
      by rewrite addrC addrA addrA addNr add0r.
    apply: psd_add.
    - exact: psd_lcongr (pd_psd R_pd).
    - exact: psd_lcongr Q_psd.
  Qed.

  (*
    Спектральная устойчивость по Шуру матрицы замкнутого контура `Fp`. $P_pss$ -
    положительно определённая неподвижная точка предсказанной ковариации с
    положительно определённым весом $K_p R K_p† + G Q G†$; инверсия Ляпунова
    (`riccati_unique.Fp_schur`) даёт `spec_rad_lt1 Fp`.

    - @kailath2000[App. E, Lemma E.4.2 "Stable F − K_{P,Z} H"].
  *)
  Theorem Fp_schur :
    spec_rad_lt1 Fp.
  Proof.
    apply: (riccati_unique.Fp_schur Q_psd R_pd FG_stab (M := P_pss)).
    - exact: P_pss_psd.
    - by rewrite -Pss_eq_update.
  Qed.

  (*
    Мера `O_P` - бесконечный грамиан наблюдаемости замкнутого контура `Fp` под
    весом $H† R^(-1) H$.
    $
      O_P := "lyap_sol" (F_p†) (H† dot R^(-1) dot H) \
         <=> O_P = F_p† dot O_P dot F_p + H† dot R^(-1) dot H.
    $
    - @kailath2000[§ 14].
    Для произвольного начала $P_0$ отклонение ковариации
    $P_k - P_ss$ от установившейся распространяется замкнутым контуром `Fp`
    (предикторная форма $F - K_p H$). Энергия этого распространения в норме с
    весом $R^(-1)$ равна бесконечной сумме $sum_k (F_p†)^k (H† R^(-1) H) F_p^k$, т.е.
    бесконечным грамианом наблюдаемости замкнутого контура под весом $H† R^(-1) H$.
    Сходимость суммы обеспечена устойчивостью по Шуру `Fp_schur`, через
    устойчивый по Шуру `lyap_sol_*_schur`; невырожденность веса, а с ней
    положительная определённость `O_P` - наблюдаемостью пары $[F_p, H]$.
  *)
  Definition OP : 'M[ℂ]_n :=
    obsv_gram_infty_w Fp (H^t* *m invmx R *m H).

  (*
    Вес $H† R^(-1) H$ неотрицательно определён
    ($R^(-1)$ положительно определена, конгруэнция сохраняет знак).
  *)
  Lemma OP_weight_psd :
    psd (H^t* *m invmx R *m H).
  Proof.
    exact: psd_congr (pd_psd (pd_inv R_pd)).
  Qed.

  Theorem OP_psd :
    psd OP.
  Proof.
    rewrite /OP /obsv_gram_infty_w.
    exact: (lyap_sol_psd_schur ler_r2c c2rK c2r_continuous r2c_continuous
              ℂ_archi OP_weight_psd (spec_rad_lt1_trmxC Fp_schur)).
  Qed.

  Theorem OP_fix :
    OP = Fp^t* *m OP *m Fp + H^t* *m invmx R *m H.
  Proof.
    rewrite /OP /obsv_gram_infty_w.
    rewrite {1}(lyap_sol_fix_schur ler_r2c c2rK r2c_continuous ℂ_archi
                  OP_weight_psd (spec_rad_lt1_trmxC Fp_schur)).
    by rewrite trmxCK.
  Qed.

  (*
    Сходимость фильтра Калмана.

    Связывает определения (`kf_step`, `kf_state`, `kf_P`) со сходимостью ДАУР.
    Главное наблюдение: ковариационная часть полного цикла
    «предсказание–обновление» фильтра - это в точности `riccati_step`, не
    зависящая от данных (управляющих входов `us` и измерений `ys`), поэтому
    траектория ковариации фильтра из любого неотрицательно определённого начала
    сходится к $P_ss$, а матрица усиления Калмана - к стационарной, по норме
    Фробениуса (следствие `dare_stabilizing_sol_frob`). Один шаг фильтра двигает
    ковариацию ровно как `riccati_step` (по определению:
    ```
    kf_P (kf_update (kf_predict st u) y)
    = update_cov (predict_cov (kf_P st))
    = riccati_step (kf_P st))...
    ```).
  *)
  Lemma kf_cov_step (st : kf_state ℂ n) (u : 'cV[ℂ]_m) (y : 'cV[ℂ]_p) :
    kf_P (kf_step F G H Q R st u y) = riccati_step F G H Q R (kf_P st).
  Proof. by []. Qed.

  (*
    Траектория фильтра с произвольными последовательностями управления и
    измерения.
  *)
  Fixpoint kf_run (st0 : kf_state ℂ n) (us : nat -> 'cV[ℂ]_m)
      (ys : nat -> 'cV[ℂ]_p) (k : nat) : kf_state ℂ n :=
    match k with
    | 0%N => st0
    | k'.+1 => kf_step F G H Q R (kf_run st0 us ys k') (us k') (ys k')
    end.

  (*
    Ковариация фильтра на шаге `k` = итерация Риккати из начальной ковариации;
    данные `us`/`ys` на неё не влияют.
  *)
  Lemma kf_run_cov (st0 : kf_state ℂ n)
      (us : nat -> 'cV[ℂ]_m)
      (ys : nat -> 'cV[ℂ]_p)
      (k : nat) :
    kf_P (kf_run st0 us ys k) = iter k (riccati_step F G H Q R) (kf_P st0).
  Proof.
    by elim: k => [//|k IH]; rewrite iterS -IH.
  Qed.

  (*
    Фильтр Калмана из любого неотрицательно определённого начала при любых
    последовательностях измерений имеет сходящуюся к $P_ss$ ковариацию и
    сходящееся к стационарному коэффициенту усиления (по норме Фробениуса).
  *)
  Theorem kalman_filter_frob_cvgn
      (st0 : kf_state ℂ n) (us : nat -> 'cV[ℂ]_m) (ys : nat -> 'cV[ℂ]_p) :
    psd (kf_P st0) ->
    exists Pss0 : 'M[ℂ]_n,
      [/\ Pss0 = riccati_step F G H Q R Pss0,
          pd Pss0,
          (forall eps : ℂ, eps > 0 ->
            exists N : nat, forall k, (N <= k)%N ->
              \tr ((kf_P (kf_run st0 us ys k) - Pss0)^t* *m
                  (kf_P (kf_run st0 us ys k) - Pss0)) < eps) &
          (forall eps : ℂ, eps > 0 ->
            exists N : nat, forall k, (N <= k)%N ->
              \tr ((kalman_gain H R
                      (predict_cov F G Q (kf_P (kf_run st0 us ys k))) -
                    kalman_gain H R (predict_cov F G Q Pss0))^t* *m
                  (kalman_gain H R
                      (predict_cov F G Q (kf_P (kf_run st0 us ys k))) -
                    kalman_gain H R (predict_cov F G Q Pss0))) < eps)].
  Proof.
    move=> psd0.
    have [Pss0 [HPfix [HPpd Hconv]]] := dare_stabilizing_sol_frob.
    have [Hcov Hgain] := Hconv (kf_P st0) psd0.
    exists Pss0; split.
    - exact: HPfix.
    - exact: HPpd.
    - move=> eps eps_pos; have [N HN] := Hcov eps eps_pos.
      by exists N => k Hk; rewrite kf_run_cov; apply: HN.
    - move=> eps eps_pos; have [N HN] := Hgain eps eps_pos.
      by exists N => k Hk; rewrite kf_run_cov; apply: HN.
  Qed.

End DARE.
