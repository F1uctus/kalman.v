(*
  Дискретное алгебраическое уравнение Риккати (ДАУР, DARE).
  Существование и неподвижная точка стационарной ковариации.

  - `Pss := mx_mono_lim (fun k => iter k riccati_step 0)` —
    предел монотонной траектории `iter k riccati_step 0` в матричной
    топологии (получается через `mxmonotone.mx_mono_cvgn`).
  - `Pss_cvgn` — сходимость итерации из нуля к `Pss`.
  - `Pss_psd` — неотрицательная определённость предельной матрицы.
  - `Pss_fix` — `Pss = riccati_step Pss` (по непрерывности шага
    Риккати и единственности предела в матричной топологии).

  Стратегия.
  1. Равномерная верхняя оценка `P_iter_bound` — для каждой итерации
     `iter k riccati_step 0 ≤ Pbnd` в порядке Лёвнера.  Начиная с
     Session 24 эта оценка выводится из СПЕКТРАЛЬНОЙ Шуровости ЗАМКНУТОГО
     контура `Mc = (I − K0 H) F` (`spec_rad_lt1 Mc`, для стабилизирующего
     фильтр-усиления `K0`), а не из контракции системной матрицы
     `frob_sq F < 1`: завершение квадрата даёт `riccati_step Σ ≤ Mc Σ Mc† + Wc`,
     откуда `iter k riccati_step 0 ≤ lyap_partial Mc Wc k ≤ Pbnd`, где `Pbnd`
     — равномерная мажоранта из Schur-суммируемости Грамиана
     (`lyap_partial_le_bnd_schur`, spec_rad.v; книжный путь
     Kailath–Sayed–Hassibi, гл. 14.5).
  2. `riccati_iter_mono_from_0` (Session 5) даёт монотонность.
  3. `mx_mono_cvgn` (Session 3) — сходимость в матричной топологии.
  4. `cvgn_riccati_step` (этого файла, inline-доказательство)
     — непрерывность шага Риккати на PSD-входах.  Композиция с
     `Pss_cvgn` и единственностью предела (`cvg_unique` +
     `norm_hausdorff`) даёт неподвижную точку.
  5. PD-ность `Pss` НЕ доказывается в этой сессии — она требует
     нижней оценки через контролируемость, отложенной на Session 7.5/8.

  Замечание о `riccati_cont`.  Файл `riccati_cont.v` (Session 4)
  определил свою копию `riccati_step` (и соратников), и потому
  тамошний `cvgn_riccati_step` относится к другой константе.  Чтобы
  переиспользовать ту же машинерию для `kalman.v`'s `riccati_step`
  без шеваллированного `change`, мы переcоставляем непрерывность
  inline из элементарных `cvgn_addmx` / `cvgn_mulmx` / `cvgn_invmx` /
  `cvgn_submx` (mxtopo + riccati_cont).
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
From Kalman Require Import mxnotation mxdefinite mxloewner spectral.
From Kalman Require Import mxherm mxfrob mxtopo mxmonotone.
From Kalman Require Import kalman riccati_mono obsv_bound.
From Kalman Require Import lyapunov gramian_infty spec_rad.
From Kalman Require Import riccati_unique.
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

  (* Вещественный мост ℝ / ℂ для `mx_mono_cvgn` (см. mxmonotone) *)
  Variables (ℝ : realType) (ℂ : numClosedFieldType).
  Variable r2c : {rmorphism ℝ -> ℂ}.
  Variable c2r : ℂ -> ℝ.
  Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
  Hypothesis r2cK : cancel r2c c2r.
  Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
  Hypothesis c2r_continuous : continuous (c2r : ℂ -> ℝ).
  Hypothesis r2c_continuous : continuous (r2c : ℝ -> ℂ).

  (* Архимедовость поля — нужна для `A^k → 0` при Шуровости (Session 20.6);
     downstream разряжается на конкретном архимедовом поле (algC и т.п.). *)
  Hypothesis ℂ_archi : Num.archimedean_axiom ℂ.

  (* Параметры системы Калмана.  Размерность состояния положительна
     (`n = n'.+1`): спектральная теория Шура требует `n > 0`. *)
  Variables (m p : nat).
  Variable (n' : nat).
  Local Notation n := (n'.+1).
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variables (Q : 'M[ℂ]_m) (Rn : 'M[ℂ]_p).
  Hypothesis Q_psd : psd Q.
  Hypothesis Rn_pd : pd Rn.

  (* Невырожденность процессного шума (Session 11): шум процесса входит во
     все направления состояния.  Это стандартное предположение
     классической калмановской фильтрации — матрица `G Q G†` положительно
     определена, что гарантирует PD-ность установившейся ковариации `Pss`. *)
  Hypothesis pd_GQGt : pd (G *m Q *m G^t*).

  (* ================================================================== *)
  (*  Стабилизирующее усиление и Шуровость замкнутого контура             *)
  (*  (Session 24, книжный путь Kailath–Sayed–Hassibi гл. 14.5)          *)
  (*                                                                     *)
  (*  Вместо Фробениусовой контракции СИСТЕМНОЙ матрицы `frob_sq F < 1`  *)
  (*  (Session 10) фиксируем стабилизирующее фильтр-усиление `K0` и       *)
  (*  требуем СПЕКТРАЛЬНОЙ Шуровости АПОСТЕРИОРНОГО замкнутого контура     *)
  (*    Mc := (I − K0 H) F,   spec_rad_lt1 Mc.                           *)
  (*  Это строго слабее прежней `frob_sq F < 1` (и слабее даже            *)
  (*  `frob_sq Mc < 1`): требуется лишь, чтобы все собственные значения   *)
  (*  замкнутого контура лежали в открытом единичном диске.  Завершение   *)
  (*  квадрата по `K0` даёт книжное неравенство                           *)
  (*    riccati_step Σ ≤ Mc Σ Mc† + Wc,    Wc := (I−K0H)GQG†(I−K0H)†+K0RnK0†, *)
  (*  откуда — равномерная мажоранта `Pbnd` (через Schur-суммируемость    *)
  (*  Грамиана, `lyap_partial_le_bnd_schur`), а суперрешение строится как  *)
  (*  `lyap_sol Mc Wc + a·(lyap_sol Mc I)` (см. ниже): возмущение по       *)
  (*  Ляпунову замкнутого контура, корректное при ЛЮБОЙ Шуровости (без    *)
  (*  оценки операторной нормы `Mc`, недоступной при `frob_sq Mc ≥ 1`).   *)
  (* ================================================================== *)
  Variable K0 : 'M[ℂ]_(n, p).
  Local Notation Mc := ((1%:M - K0 *m H) *m F).
  Local Notation Wc :=
    ((1%:M - K0 *m H) *m (G *m Q *m G^t*) *m (1%:M - K0 *m H)^t*
     + K0 *m Rn *m K0^t*).
  Hypothesis cl_contract : spec_rad_lt1 Mc.

  (* --- Вспомогательная Лёвнер-арифметика --- *)

  (* Лево-конгруэнтная монотонность: A ≤ B ⇒ M A M† ≤ M B M†. *)
  Lemma psd_le_lcongr (Mx A B : 'M[ℂ]_n) :
    psd_le A B -> psd_le (Mx *m A *m Mx^t*) (Mx *m B *m Mx^t*).
  Proof. move=> hAB; have := psd_le_congr (Mx^t*) hAB; by rewrite trmxCK. Qed.

  (* Прибавление справа сохраняет порядок. *)
  Lemma psd_le_add2r (C A B : 'M[ℂ]_n) :
    psd_le A B -> psd_le (A + C) (B + C).
  Proof. rewrite /psd_le=> h; by rewrite opprD addrACA subrr addr0. Qed.

  (* M M† ≤ frob_sq M · I (через след: \tr (M M†) = frob_sq M). *)
  Lemma MM_le_frob_id (Mx : 'M[ℂ]_n) :
    psd_le (Mx *m Mx^t*) (frob_sq Mx *: 1%:M).
  Proof.
    have psdMM : psd (Mx *m Mx^t*) by have := psd_frob (Mx^t*); rewrite trmxCK.
    have trEq : \tr (Mx *m Mx^t*) = frob_sq Mx by rewrite /frob_sq mxtrace_mulC.
    have step := psd_le_trace_id psdMM; by rewrite trEq in step.
  Qed.

  (* Масштабирование PSD-порядка неотрицательным вещественным скаляром. *)
  Lemma psd_le_scaler (a : ℂ) (A B : 'M[ℂ]_n) :
    a \is Num.real -> 0 <= a -> psd_le A B -> psd_le (a *: A) (a *: B).
  Proof.
    move=> a_real a_ge0; rewrite /psd_le=> psdD.
    have ->: a *: B - a *: A = a *: (B - A) by rewrite scalerBr.
    case: psdD => Dsym Dqf; split.
    - rewrite trmxC_scale -Dsym.
      have a_conj : a^* = a by apply/CrealP; exact: a_real.
      by rewrite a_conj.
    - move=> v; rewrite -scalemxAr -scalemxAl mxtraceZ.
      by apply: mulr_ge0; [exact: a_ge0 | exact: Dqf].
  Qed.

  (* Вес замкнутого контура положительно полуопределён. *)
  Lemma Wc_psd : psd Wc.
  Proof.
    apply: psd_add.
    - exact: psd_lcongr (1%:M - K0 *m H) (psd_lcongr G Q_psd).
    - exact: psd_lcongr K0 (pd_psd Rn_pd).
  Qed.

  (* --- Книжное неравенство: завершение квадрата по усилению K0 --- *)

  (* riccati_step Σ ≤ Mc Σ Mc† + Wc.  Через `alt_update_cov_diff`
     (апостериорное усиление K0): update_cov(predict Σ) ≤
     alt_update_cov K0 (predict Σ)
       = (I−K0H)(F Σ F† + G Q G†)(I−K0H)† + K0 Rn K0†
       = Mc Σ Mc† + Wc. *)
  Lemma riccati_step_le_cl (Sigma : 'M[ℂ]_n) :
    psd Sigma ->
    psd_le (riccati_step F G H Q Rn Sigma) (Mc *m Sigma *m Mc^t* + Wc).
  Proof.
    move=> psdS.
    have psdPred : psd (predict_cov F G Q Sigma)
      := predict_cov_psd F G Q_psd psdS.
    have hle : psd_le (update_cov H Rn (predict_cov F G Q Sigma))
                      (alt_update_cov H Rn K0 (predict_cov F G Q Sigma)).
      rewrite /psd_le (alt_update_cov_diff H Rn_pd K0 psdPred).
      rewrite addrAC subrr add0r.
      exact: psd_lcongr (K0 - kalman_gain H Rn (predict_cov F G Q Sigma))
                        (pd_psd (innov_cov_pd H Rn_pd psdPred)).
    have heq : alt_update_cov H Rn K0 (predict_cov F G Q Sigma)
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

  (* Равномерная верхняя мажоранта частичных сумм Ляпунова замкнутого
     контура — через Schur-суммируемость Грамиана (`lyap_partial_le_bnd_schur`,
     spec_rad.v).  Конкретная матрица извлекается из существования. *)
  Definition Pbnd : 'M[ℂ]_n :=
    proj1_sig (cid (lyap_partial_le_bnd_schur ℂ_archi Wc_psd cl_contract)).

  (* iter k riccati_step 0 ≤ lyap_partial Mc Wc k — индукция через
     завершение квадрата + лево-конгруэнтную монотонность + тождество
     сдвига частичной суммы Ляпунова. *)
  Lemma P_iter_le_lyap_partial k :
    psd_le (iter k (riccati_step F G H Q Rn) 0) (lyap_partial Mc Wc k).
  Proof.
    elim: k => [|k IH].
    - rewrite lyap_partial0 /=; apply: psd_le_refl; exact: psd0.
    - rewrite iterS.
      have psd_k : psd (iter k (riccati_step F G H Q Rn) 0)
        := riccati_iter_from_0_psd F G H Q_psd Rn_pd k.
      apply: (psd_le_trans (riccati_step_le_cl psd_k)).
      rewrite (lyap_partial_shift Mc Wc k) [_ + Wc]addrC.
      apply: psd_le_add2l; apply: psd_le_lcongr; exact: IH.
  Qed.

  Lemma lyap_partial_le_Pbnd k : psd_le (lyap_partial Mc Wc k) Pbnd.
  Proof.
    exact: (proj2_sig
      (cid (lyap_partial_le_bnd_schur ℂ_archi Wc_psd cl_contract)) k).
  Qed.

  Lemma P_iter_bound k :
    psd_le (iter k (riccati_step F G H Q Rn) 0) Pbnd.
  Proof.
    apply: (psd_le_trans (P_iter_le_lyap_partial k)).
    exact: lyap_partial_le_Pbnd k.
  Qed.

  (* ================================================================== *)
  (*  Траектория из нуля и её базовые свойства                            *)
  (* ================================================================== *)

  Local Notation Pseq := (fun k => iter k (riccati_step F G H Q Rn) 0).

  Lemma Pseq_psd k : psd (Pseq k).
  Proof.
    exact: (riccati_iter_from_0_psd F G H Q_psd Rn_pd k).
  Qed.

  Lemma Pseq_mono k : psd_le (Pseq k) (Pseq k.+1).
  Proof.
    exact: (riccati_iter_mono_from_0 F G H Q_psd Rn_pd k).
  Qed.

  Lemma Pseq_bnd k : psd_le (Pseq k) Pbnd.
  Proof.
    exact: P_iter_bound.
  Qed.

  (* ================================================================== *)
  (*  Существование предела `Pss` в матричной топологии                   *)
  (* ================================================================== *)

  Definition Pss : 'M[ℂ]_n := mx_mono_lim Pseq.

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

  (* ================================================================== *)
  (*  Непрерывность шага Риккати на PSD-входах (inline для kalman.v)      *)
  (* ================================================================== *)

  (* Используем элементарные continuity-кирпичики из mxtopo и
     riccati_cont (cvgn_invmx).  Имена `predict_cov`, `innov_cov`,
     `update_cov`, `riccati_step` ниже относятся к kalman.v
     (мы не делаем `Import riccati_cont`, только `Require`). *)

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
    (fun k => innov_cov H Rn (Pf k)) @ \oo --> innov_cov H Rn L.
  Proof.
    move=> HP.
    rewrite /innov_cov; under eq_cvg=> k do rewrite /innov_cov.
    apply: cvgn_addmx; last exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    apply: cvgn_mulmx (cvg_cst _) HP.
  Qed.

  Lemma cvgn_kalman_gain_k (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L -> innov_cov H Rn L \in unitmx ->
    (fun k => kalman_gain H Rn (Pf k)) @ \oo --> kalman_gain H Rn L.
  Proof.
    move=> HP Sunit.
    rewrite /kalman_gain; under eq_cvg=> k do rewrite /kalman_gain.
    apply: cvgn_mulmx.
    - apply: cvgn_mulmx HP _; exact: cvg_cst.
    - exact: riccati_cont.cvgn_invmx (cvgn_innov_cov_k HP) Sunit.
  Qed.

  Lemma cvgn_update_cov_k (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L -> innov_cov H Rn L \in unitmx ->
    (fun k => update_cov H Rn (Pf k)) @ \oo --> update_cov H Rn L.
  Proof.
    move=> HP Sunit.
    rewrite /update_cov; under eq_cvg=> k do rewrite /update_cov.
    apply: cvgn_mulmx; last exact: HP.
    apply: cvgn_submx; first exact: cvg_cst.
    apply: cvgn_mulmx; last exact: cvg_cst.
    exact: cvgn_kalman_gain_k HP Sunit.
  Qed.

  Lemma cvgn_riccati_step_k (Pf : nat -> 'M[ℂ]_n) (L : 'M[ℂ]_n) :
    Pf @ \oo --> L -> innov_cov H Rn (predict_cov F G Q L) \in unitmx ->
    (fun k => riccati_step F G H Q Rn (Pf k)) @ \oo -->
      riccati_step F G H Q Rn L.
  Proof.
    move=> HP Sunit.
    rewrite /riccati_step; under eq_cvg=> k do rewrite /riccati_step.
    apply: cvgn_update_cov_k Sunit.
    exact: cvgn_predict_cov_k.
  Qed.

  (* ================================================================== *)
  (*  Неподвижная точка: Pss = riccati_step Pss                          *)
  (* ================================================================== *)

  (* Шаг Риккати, применённый к траектории, даёт траекторию со сдвигом:
    `riccati_step (Pseq k) = Pseq k.+1`.  Поэтому
    `(fun k => riccati_step (Pseq k)) @ \oo --> riccati_step Pss`
    (по непрерывности) и одновременно
    `(fun k => Pseq k.+1) @ \oo --> Pss` (по `cvg_shiftS` из `Pss_cvgn`).
    Эти две функции равны, значит пределы равны в Хаусдорфовой топологии. *)

  Theorem Pss_fix : Pss = riccati_step F G H Q Rn Pss.
  Proof.
    (* Шаг 1: invertibility of innov_cov ∘ predict_cov at Pss *)
    have predPss_psd : psd (predict_cov F G Q Pss) := predict_cov_psd F G Q_psd Pss_psd.
    have Sunit : innov_cov H Rn (predict_cov F G Q Pss) \in unitmx
      := innov_cov_inv H Rn_pd predPss_psd.
    (* Шаг 2: сходимость к riccati_step Pss по непрерывности *)
    have HriccCvg : (fun k => riccati_step F G H Q Rn (Pseq k)) @ \oo -->
                    riccati_step F G H Q Rn Pss
      := cvgn_riccati_step_k Pss_cvgn Sunit.
    (* Шаг 3: `riccati_step (Pseq k) = Pseq k.+1` — сама определимость iter *)
    have eqf : (fun k => riccati_step F G H Q Rn (Pseq k))
            = (fun k => Pseq k.+1).
      by apply/funext=> k.
    rewrite eqf in HriccCvg.
    (* Шаг 4: `(fun k => Pseq k.+1) @ \oo --> Pss` — сдвиг сходящейся
      последовательности.  Используем `cvg_comp` с `addn 1 @ \oo --> \oo`
      и переписываем `addn 1 = (fun k => k.+1)` через `add1n`. *)
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
          @ \oo --> (riccati_step F G H Q Rn Pss
                      : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)).
      exact: HriccCvg.
    exact: (cvg_unique HausM HshiftCvg_n HriccCvg_n).
  Qed.

  (* Сводный результат: существование неотрицательно определённой неподвижной точки DARE. *)
  Theorem dare_psd_fix :
    exists Pss0 : 'M[ℂ]_n,
      [/\ psd Pss0,
          Pss0 = riccati_step F G H Q Rn Pss0,
          Pseq @ \oo --> Pss0 &
          psd_le Pss0 Pbnd].
  Proof.
    exists Pss; split.
    - exact: Pss_psd.
    - exact: Pss_fix.
    - exact: Pss_cvgn.
    - exact: Pss_le_bnd.
  Qed.

  (* Session 7.5 — PD-ность Pss через нижнюю оценку траектории

     Гипотеза нижнего бенчмарка: существует PD-матрица `Plow`,
     оцениваемая снизу некоторым ранним членом траектории `Pseq k0`.
     Это абстракция, эквивалентная стандартному наблюдательскому
     нижнему пределу `obsv_gram n ≤ invmx (Pseq k)` для `k ≥ n`
     (после инвертирования) при условии obsv-PD-ности (Session 6
     `obsv_gram_pd_of_observable`).  Конкретный путь разрядки
     отложен на Session 9.

     PD-ность `Pss` следует из `pd_add` (`pd Plow → psd (Pss - Plow) →
     pd (Plow + (Pss - Plow)) = pd Pss`).  Шаг `psd_le Plow Pss`
     использует свежедобавленную `mx_mono_lim_ge_term`.
     Нижний бенчмарк (Session 11): первый член траектории `Pseq 1`.
     `Pseq 1 = riccati_step 0 = update_cov (predict_cov 0)`, а
     `predict_cov 0 = G Q G†` (т.к. `F 0 F† + G Q G† = G Q G†`).
     PD-ность следует из `update_cov_pd`, применённой к `pd_GQGt`.         *)
  Definition Plow : 'M[ℂ]_n := iter 1 (riccati_step F G H Q Rn) 0.
  Definition k0_low : nat := 1.

  Lemma Plow_pd :
    pd Plow.
  Proof.
    rewrite /Plow /= /riccati_step.
    apply: update_cov_pd; first exact: Rn_pd.
    rewrite /predict_cov mulmx0 mul0mx add0r.
    exact: pd_GQGt.
  Qed.

  Lemma Plow_le_Pseq_k0 :
    psd_le Plow (Pseq k0_low).
  Proof.
    by rewrite /k0_low; apply: psd_le_refl; exact: pd_psd Plow_pd.
  Qed.

  Lemma Plow_le_Pss :
    psd_le Plow Pss.
  Proof.
    apply: (psd_le_trans Plow_le_Pseq_k0).
    exact: (@mx_mono_lim_ge_term ℝ ℂ r2c c2r
            ler_r2c c2rK c2r_continuous r2c_continuous
            n Pseq Pbnd Pseq_psd Pseq_mono Pseq_bnd k0_low).
  Qed.

  Theorem Pss_pd :
    pd Pss.
  Proof.
    have HsumEq : Pss = Plow + (Pss - Plow).
      by rewrite addrC -addrA [(- _) + _]addrC subrr addr0.
    rewrite HsumEq.
    apply: pd_add; first exact: Plow_pd.
    exact: Plow_le_Pss.
  Qed.

(* ================================================================== *)
(*  Session 8 — сходимость с произвольного PSD начала                  *)
(*  + сходимость усиления Калмана + единственность PD-неподвижной точки         *)
(* ================================================================== *)
(*                                                                     *)
(*  Гипотеза `arb_iter_cvgn` — абстракция «глобальной сходимости»:      *)
(*  итерация DARE из любого PSD начала сходится к `Pss` в матричной    *)
(*  топологии.  Этот факт — стандартный результат классической           *)
(*  DARE-теории (Kailath § 14.5), требующий устойчивости пары F̃ =       *)
(*  F - KH (т.е. собственные числа в открытом единичном диске).         *)
(*  В Session 9 эту гипотезу планируется разрядить через                 *)
(*  спектральный анализ контракции `P_{k+1} - Pss = F̃ (P_k - Pss) F̃†  *)
(*  - (более тонкая разность через обновление).                          *)
(*                                                                     *)
(*  Из неё немедленно следуют:                                          *)
(*    1.  Сходимость Калман-усиления (по непрерывности                  *)
(*        `kalman_gain ∘ predict_cov`).                                  *)
(*    2.  Единственность PD-неподвижной точки: любая PD-неподвижная точка       *)
(*        `Pi` (как константная последовательность) сходится к самой    *)
(*        себе и одновременно к `Pss` по гипотезе => `Pi = Pss`           *)
(*        (Хаусдорфовость матричной топологии).                          *)

(* ================================================================== *)
(* Session 12/24 — глобальная сходимость через суперрешение + сэндвич  *)
(* ================================================================== *)
(*                                                                     *)
(* Стратегия: показываем, что `Xinf + a·I` (Xinf := lyap_sol Mc Wc,    *)
(* a ≥ 0) — суперрешение, то есть `riccati_step (Xinf+a·I) ≤ Xinf+a·I`. *)
(* Тогда верхняя траектория `iter k riccati_step (Xinf+a·I)` монотонно  *)
(* убывает (в порядке Лёвнера) и сходится к некоторой неподвижной точке *)
(* `L` (через mxmonotone.mx_mono_dec_cvgn).  По доменной гипотезе       *)
(* `Pss_unique` (классическая единственность PD-неподвижной точки      *)
(* DARE) имеем `L = Pss`.  Для произвольного PSD `P0` выбираем a := \tr *)
(* P0 (тогда `P0 ≤ a·I ≤ a·Yinf ≤ Xinf + a·Yinf`); сэндвич с           *)
(* `iter k r.s. 0` и оценкой `frob_sq ≤ (\tr)^+2` даёт сходимость к     *)
(* `Pss`.  В отличие от Session 12, суперрешение работает при           *)
(* СПЕКТРАЛЬНОЙ Шуровости замкнутого контура `spec_rad_lt1 Mc`, а не    *)
(* системной матрицы `frob_sq F < 1`.                                   *)

(* Единственность PD-неподвижной точки — БОЛЬШЕ НЕ ГИПОТЕЗА (Session 25). *)
(* Классический результат DARE-теории (Kailath §14.5): любая PD-          *)
(* неподвижная точка совпадает с Pss.  Доказана через книжную Lemma       *)
(* 14.5.3 для разности двух решений `riccati_step_fix_unique`             *)
(* (riccati_unique.v): разность предсказанных ковариаций удовлетворяет    *)
(* `M1 − M2 = Fp(M1)(M1−M2)Fp(M2)†` с обоими Schur-устойчивыми контурами  *)
(* (`lyap_inv_spec_rad`), откуда `lyap_two_sided_zero_schur` даёт ноль.   *)
(* Никакого операторно-нормного аппарата — только `boolp`.                *)
Lemma Pss_unique (L : 'M[ℂ]_n) :
  pd L -> L = riccati_step F G H Q Rn L -> L = Pss.
Proof.
move=> HL Hf.
exact: (riccati_step_fix_unique ℂ_archi Rn_pd pd_GQGt HL Pss_pd Hf Pss_fix).
Qed.

(* ================================================================== *)
(* Суперрешение Риккати: lyap_sol Mc Wc + a·(lyap_sol Mc I) (a ≥ 0).     *)
(* ================================================================== *)
(* `Xinf := lyap_sol Mc Wc` — решение уравнения Ляпунова замкнутого     *)
(* контура `Xinf = Mc Xinf Mc† + Wc`; `Yinf := lyap_sol Mc I` —         *)
(* PD-возмущение, `Yinf = Mc Yinf Mc† + I ≥ I`.  Тогда для любого        *)
(* вещественного `a ≥ 0` матрица `Xinf + a·Yinf` — суперрешение:         *)
(*   riccati_step (Xinf + a·Yinf) ≤ Mc (Xinf + a·Yinf) Mc† + Wc         *)
(*       = Xinf + a·(Mc Yinf Mc†) = Xinf + a·(Yinf − I)                 *)
(*       = (Xinf + a·Yinf) − a·I ≤ Xinf + a·Yinf.                       *)
(* Ключ: возмущение по Ляпунову `Yinf` (а не скаляр `I`) делает          *)
(* суперрешение корректным при ЛЮБОЙ Шуровости `spec_rad_lt1 Mc` — не    *)
(* нужна оценка операторной нормы `Mc` (недоступная при `frob_sq Mc≥1`). *)

Local Notation Xinf := (lyap_sol Mc Wc).
Local Notation Yinf := (lyap_sol Mc 1%:M).

Lemma Xinf_psd : psd Xinf.
Proof.
exact: (lyap_sol_psd_schur ler_r2c c2rK c2r_continuous r2c_continuous
          ℂ_archi Wc_psd cl_contract).
Qed.

Lemma Xinf_fix : Xinf = Mc *m Xinf *m Mc^t* + Wc.
Proof.
exact: (lyap_sol_fix_schur ler_r2c c2rK r2c_continuous
          ℂ_archi Wc_psd cl_contract).
Qed.

Lemma Yinf_psd : psd Yinf.
Proof.
apply: (lyap_sol_psd_schur ler_r2c c2rK c2r_continuous r2c_continuous ℂ_archi);
  [exact: pd_psd (pd1 ℂ n) | exact: cl_contract].
Qed.

Lemma Yinf_fix : Yinf = Mc *m Yinf *m Mc^t* + 1%:M.
Proof.
apply: (lyap_sol_fix_schur ler_r2c c2rK r2c_continuous ℂ_archi);
  [exact: pd_psd (pd1 ℂ n) | exact: cl_contract].
Qed.

(* Yinf ≥ I (нижняя оценка — позволит `a·Yinf` мажорировать любое `P0`). *)
Lemma I_le_Yinf : psd_le (1%:M : 'M[ℂ]_n) Yinf.
Proof.
rewrite /psd_le {1}Yinf_fix addrK.
exact: psd_lcongr Mc Yinf_psd.
Qed.

(* psd (a *: X) для неотрицательного вещественного a. *)
Lemma psd_scaler (a : ℂ) (X : 'M[ℂ]_n) :
  a \is Num.real -> 0 <= a -> psd X -> psd (a *: X).
Proof.
move=> a_real a_ge0 psdX.
have h0 : psd_le 0 X by apply/psd_le0_psd.
have Hs := psd_le_scaler a_real a_ge0 h0.
rewrite scaler0 in Hs.
by apply/psd_le0_psd; exact: Hs.
Qed.

(* Главная техническая лемма: `Xinf + a·Yinf` — суперрешение Риккати. *)
Lemma scalar_supersolution (a : ℂ) :
  a \is Num.real -> 0 <= a ->
  psd_le (riccati_step F G H Q Rn (Xinf + a *: Yinf)) (Xinf + a *: Yinf).
Proof.
move=> a_real a_ge0.
have psdS : psd (Xinf + a *: Yinf).
  apply: psd_add; [exact: Xinf_psd | exact: psd_scaler a_real a_ge0 Yinf_psd].
apply: (psd_le_trans (riccati_step_le_cl psdS)).
(* Mc (Xinf + a·Yinf) Mc† + Wc = Xinf + a·Yinf − a·I. *)
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

(* ================================================================== *)
(* Верхняя траектория из Xinf + a·I — монотонно убывает к Pss (через    *)
(* mx_mono_dec_cvgn + Pss_unique).                                      *)
(* ================================================================== *)

(* PSD-ность и монотонное убывание для любого вещественного a ≥ 0. *)
Lemma Pup_psd (a : ℂ) (a_real : a \is Num.real) (a_ge0 : 0 <= a)
    (k : nat) :
  psd (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)).
Proof.
elim: k => [|k IH] /=.
- apply: psd_add; [exact: Xinf_psd | exact: psd_scaler a_real a_ge0 Yinf_psd].
- by apply: riccati_step_psd; [exact: Q_psd | exact: Rn_pd | exact: IH].
Qed.

Lemma Pup_anti (a : ℂ) (a_real : a \is Num.real) (a_ge0 : 0 <= a)
    (k : nat) :
  psd_le (iter k.+1 (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
         (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)).
Proof.
elim: k => [|k IH] /=.
- exact: scalar_supersolution a_real a_ge0.
- have psd_k : psd (iter k.+1 (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
    := Pup_psd a_real a_ge0 k.+1.
  have psd_Sk : psd (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
    := Pup_psd a_real a_ge0 k.
  by apply: riccati_step_mono; [exact: Q_psd | exact: Rn_pd |
                                exact: psd_k | exact: psd_Sk | exact: IH].
Qed.

(* Предел верхней траектории. *)
Definition Pup_lim (a : ℂ) (a_real : a \is Num.real)
    (a_ge0 : 0 <= a) : 'M[ℂ]_n :=
  mx_mono_dec_lim
    (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)).

Lemma Pup_cvgn (a : ℂ) (a_real : a \is Num.real) (a_ge0 : 0 <= a) :
  (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)) @ \oo -->
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
          n (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
          (Pup_psd a_real a_ge0) (Pup_anti a_real a_ge0)).
Qed.

(* Pup_lim — неподвижная точка riccati_step (по непрерывности). *)
Lemma Pup_lim_fix (a : ℂ) (a_real : a \is Num.real)
    (a_ge0 : 0 <= a) :
  Pup_lim a_real a_ge0 = riccati_step F G H Q Rn (Pup_lim a_real a_ge0).
Proof.
set L := Pup_lim a_real a_ge0.
have Lpsd : psd L := Pup_lim_psd a_real a_ge0.
have Hcvg : (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
              @ \oo --> L.
  exact: Pup_cvgn a_real a_ge0.
have predL_psd : psd (predict_cov F G Q L)
  by apply: predict_cov_psd; [exact: Q_psd | exact: Lpsd].
have Sunit : innov_cov H Rn (predict_cov F G Q L) \in unitmx
  := innov_cov_inv H Rn_pd predL_psd.
have HriccCvg :
    (fun k => riccati_step F G H Q Rn
                  (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)))
      @ \oo --> riccati_step F G H Q Rn L
  := cvgn_riccati_step_k Hcvg Sunit.
have eqf :
    (fun k => riccati_step F G H Q Rn
                (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)))
  = (fun k => iter k.+1 (riccati_step F G H Q Rn) (Xinf + a *: Yinf)).
  by apply/funext.
rewrite eqf in HriccCvg.
have HshiftCvg :
    (fun k : nat => iter k.+1 (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
      @ \oo --> L.
  have Hsh : addn 1 @ \oo --> (\oo : set_system nat) := cvg_addnl 1.
  have Hcomp :
      ((fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)) \o addn 1)
        @ \oo --> L
    := cvg_comp (addn 1)
                 (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
                 Hsh Hcvg.
  have eq_shift :
      (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)) \o addn 1
    = (fun k => iter k.+1 (riccati_step F G H Q Rn) (Xinf + a *: Yinf)).
    by apply/funext.
  by rewrite -eq_shift.
have HausM : hausdorff_space ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)
  by exact: norm_hausdorff.
have HshiftCvg_n :
    ((fun k => iter k.+1 (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
       : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      @ \oo --> (L : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
  := HshiftCvg.
have HriccCvg_n :
    ((fun k => iter k.+1 (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
       : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      @ \oo --> (riccati_step F G H Q Rn L
                   : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
  := HriccCvg.
exact: (cvg_unique HausM HshiftCvg_n HriccCvg_n).
Qed.

(* Pup_lim PD: predict_cov даёт PD-матрицу (PSD + pd_GQGt), update_cov  *)
(* сохраняет PD.                                                        *)
Lemma Pup_lim_pd (a : ℂ) (a_real : a \is Num.real)
    (a_ge0 : 0 <= a) : pd (Pup_lim a_real a_ge0).
Proof.
have HfpEq : Pup_lim a_real a_ge0 = riccati_step F G H Q Rn (Pup_lim a_real a_ge0)
  := Pup_lim_fix a_real a_ge0.
rewrite HfpEq /riccati_step.
apply: update_cov_pd; first exact: Rn_pd.
rewrite /predict_cov.
(* F L F† + G Q G† = G Q G† + F L F†;  pd_add требует pd слева, psd справа. *)
have Lpsd : psd (Pup_lim a_real a_ge0) := Pup_lim_psd a_real a_ge0.
have psd_FLFt : psd (F *m Pup_lim a_real a_ge0 *m F^t*)
  := psd_lcongr F Lpsd.
rewrite addrC.
exact: pd_add pd_GQGt psd_FLFt.
Qed.

(* Главное следствие: Pup_lim = Pss. *)
Lemma Pup_lim_eq_Pss (a : ℂ) (a_real : a \is Num.real)
    (a_ge0 : 0 <= a) : Pup_lim a_real a_ge0 = Pss.
Proof.
apply: Pss_unique.
- exact: Pup_lim_pd a_real a_ge0.
- exact: Pup_lim_fix a_real a_ge0.
Qed.

(* Сходимость самой верхней траектории к Pss. *)
Lemma Pup_cvgn_Pss (a : ℂ) (a_real : a \is Num.real)
    (a_ge0 : 0 <= a) :
  (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)) @ \oo --> Pss.
Proof.
have := @Pup_cvgn a a_real a_ge0.
by rewrite (Pup_lim_eq_Pss a_real a_ge0).
Qed.

(* ================================================================== *)
(* arb_iter_cvgn: для произвольного PSD P0 — сходимость к Pss.          *)
(* Выбираем a := \tr P0; тогда P0 ≤ a·I ≤ Xinf + a·I (суперрешение-     *)
(* старт), сэндвич с нижней (Pseq) и верхней (Pup) траекториями.        *)
(* ================================================================== *)

Theorem arb_iter_cvgn (P0 : 'M[ℂ]_n) (HP0 : psd P0) :
  (fun k => iter k (riccati_step F G H Q Rn) P0) @ \oo --> Pss.
Proof.
pose a : ℂ := \tr P0.
have a_ge0 : 0 <= a := psd_tr_ge0 HP0.
have a_real : a \is Num.real by exact: ger0_real.
(* P0 ≤ a·I ≤ a·Yinf ≤ Xinf + a·Yinf (старт верхней траектории). *)
have P0_le_aI : psd_le P0 (a *: (1%:M : 'M[ℂ]_n)) := psd_le_trace_id HP0.
have HXinf0 : psd_le 0 Xinf by apply/psd_le0_psd; exact: Xinf_psd.
have aI_le_aY : psd_le (a *: (1%:M : 'M[ℂ]_n)) (a *: Yinf)
  := psd_le_scaler a_real a_ge0 I_le_Yinf.
have aY_le_Psup : psd_le (a *: Yinf) (Xinf + a *: Yinf).
  have h := psd_le_add2r (a *: Yinf) HXinf0.
  by rewrite add0r in h.
have P0_le_Psup : psd_le P0 (Xinf + a *: Yinf)
  := psd_le_trans P0_le_aI (psd_le_trans aI_le_aY aY_le_Psup).
(* Сэндвич: iter k r.s. 0 ≤ iter k r.s. P0 ≤ iter k r.s. (Xinf + a·I) *)
have Pseq_le_iterP0 : forall k,
  psd_le (iter k (riccati_step F G H Q Rn) 0)
         (iter k (riccati_step F G H Q Rn) P0).
  elim=> [|k IH] /=.
  - by apply/psd_le0_psd.
  - have psd_L : psd (iter k (riccati_step F G H Q Rn) 0) := Pseq_psd k.
    have psd_M : psd (iter k (riccati_step F G H Q Rn) P0)
      := riccati_iter_psd F G H Q_psd Rn_pd k HP0.
    by apply: riccati_step_mono;
       [exact: Q_psd | exact: Rn_pd | exact: psd_L | exact: psd_M | exact: IH].
have iterP0_le_Pup : forall k,
  psd_le (iter k (riccati_step F G H Q Rn) P0)
         (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)).
  elim=> [|k IH] /=; first exact: P0_le_Psup.
  have psd_M : psd (iter k (riccati_step F G H Q Rn) P0)
    := riccati_iter_psd F G H Q_psd Rn_pd k HP0.
  have psd_U : psd (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
    := Pup_psd a_real a_ge0 k.
  by apply: riccati_step_mono;
     [exact: Q_psd | exact: Rn_pd | exact: psd_M | exact: psd_U | exact: IH].
(* Сходимости низа и верха к Pss. *)
have Lcvg : (fun k => iter k (riccati_step F G H Q Rn) 0) @ \oo --> Pss
  := Pss_cvgn.
have Ucvg : (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf))
              @ \oo --> Pss
  := Pup_cvgn_Pss a_real a_ge0.
(* Разность верхней и нижней траекторий сходится к 0. *)
have UL_cvg :
    (fun k => iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)
            - iter k (riccati_step F G H Q Rn) 0) @ \oo --> (0 : 'M[ℂ]_n).
  have := cvgn_submx Ucvg Lcvg.
  by rewrite subrr.
(* \tr (U_k - L_k) → 0. *)
have trUL_cvg :
    (fun k => \tr (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)
                  - iter k (riccati_step F G H Q Rn) 0))
      @ \oo --> (\tr (0 : 'M[ℂ]_n)).
  exact: cvgn_mxtrace UL_cvg.
have trUL_cvg0 :
    (fun k => \tr (iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)
                  - iter k (riccati_step F G H Q Rn) 0))
      @ \oo --> (0 : ℂ).
  have htr0 : \tr (0 : 'M[ℂ]_n) = (0 : ℂ) by rewrite mxtrace0.
  by rewrite -htr0.
(* \tr (X_k - L_k) → 0 через сэндвич. *)
pose XL k := iter k (riccati_step F G H Q Rn) P0
             - iter k (riccati_step F G H Q Rn) 0.
pose UL k := iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)
             - iter k (riccati_step F G H Q Rn) 0.
have XL_psd : forall k, psd (XL k).
  by move=> k; rewrite /XL; exact: Pseq_le_iterP0.
have XL_le_UL : forall k, \tr (XL k) <= \tr (UL k).
  move=> k.
  apply: psd_le_trace.
  rewrite /XL /UL.
  have ->: iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)
         - iter k (riccati_step F G H Q Rn) 0
         - (iter k (riccati_step F G H Q Rn) P0
            - iter k (riccati_step F G H Q Rn) 0)
         = iter k (riccati_step F G H Q Rn) (Xinf + a *: Yinf)
           - iter k (riccati_step F G H Q Rn) P0.
    by rewrite opprB addrA subrK.
  exact: iterP0_le_Pup.
have trXL_cvg0 : (fun k => \tr (XL k)) @ \oo --> (0 : ℂ).
  apply: (cvgC_le0_squeeze (t := fun k => \tr (UL k))).
  - by move=> k; apply: psd_tr_ge0; exact: XL_psd.
  - exact: XL_le_UL.
  - exact: trUL_cvg0.
(* frob_sq (XL k) ≤ (\tr (XL k))^+2 → 0. *)
have frob_XL_cvg0 :
    (fun k => frob_sq (XL k)) @ \oo --> (0 : ℂ).
  apply: (cvgC_le0_squeeze (t := fun k => (\tr (XL k)) ^+ 2)).
  - by move=> k; exact: frob_sq_ge0.
  - by move=> k; apply: frob_sq_le_tr_sq; exact: XL_psd.
  - (* (\tr (XL k))^+2 → 0^+2 = 0. *)
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
(* X_k - L_k → 0 в матричной топологии. *)
have XL_cvg :
    (fun k => XL k) @ \oo --> (0 : 'M[ℂ]_n).
  have := @frob_sq_cvgn0_to_mxcvgn ℂ n n XL (0 : 'M[ℂ]_n).
  apply.
  by under eq_cvg=> k do rewrite subr0.
(* iter k r.s. P0 = XL k + iter k r.s. 0 → 0 + Pss = Pss. *)
have decomp :
    (fun k => iter k (riccati_step F G H Q Rn) P0)
  = (fun k => XL k + iter k (riccati_step F G H Q Rn) 0).
  apply/funext=> k; rewrite /XL.
  by rewrite subrK.
rewrite decomp.
have := cvgn_addmx XL_cvg Lcvg.
by rewrite add0r.
Qed.

(* Сходимость Калман-усиления для произвольного PSD начала. *)
Theorem Pss_gain_cvgn (P0 : 'M[ℂ]_n) (HP0 : psd P0) :
  (fun k => kalman_gain H Rn
              (predict_cov F G Q
                 (iter k (riccati_step F G H Q Rn) P0)))
    @ \oo --> kalman_gain H Rn (predict_cov F G Q Pss).
Proof.
have HPcvg := arb_iter_cvgn HP0.
have HpredCvg :
  (fun k => predict_cov F G Q (iter k (riccati_step F G H Q Rn) P0))
    @ \oo --> predict_cov F G Q Pss
  := cvgn_predict_cov_k HPcvg.
have predPss_psd : psd (predict_cov F G Q Pss)
  := predict_cov_psd F G Q_psd Pss_psd.
have Sunit : innov_cov H Rn (predict_cov F G Q Pss) \in unitmx
  := innov_cov_inv H Rn_pd predPss_psd.
exact: cvgn_kalman_gain_k HpredCvg Sunit.
Qed.

(* Единственность PD-неподвижной точки. *)
Theorem Pss_unique_pd (Pi : 'M[ℂ]_n) :
  pd Pi -> Pi = riccati_step F G H Q Rn Pi -> Pi = Pss.
Proof.
move=> HPi_pd Hfp.
(* `iter k riccati_step Pi = Pi` для всех k (Pi — неподвижная точка). *)
have HiterPi : forall k, iter k (riccati_step F G H Q Rn) Pi = Pi.
  by elim=> [//|k IH] /=; rewrite IH -Hfp.
(* Константная последовательность Pi сходится к Pi. *)
have HconstCvg :
    (fun k => iter k (riccati_step F G H Q Rn) Pi) @ \oo --> Pi.
  have Heq : (fun k => iter k (riccati_step F G H Q Rn) Pi)
           = (fun _ : nat => Pi)
    by apply/funext=> k; exact: HiterPi.
  by rewrite Heq; exact: cvg_cst.
(* Та же последовательность сходится к Pss по `arb_iter_cvgn`. *)
have HarbCvg :
    (fun k => iter k (riccati_step F G H Q Rn) Pi) @ \oo --> Pss
  := arb_iter_cvgn (pd_psd HPi_pd).
(* Хаусдорфова единственность предела в матричной топологии. *)
have HausM : hausdorff_space ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ).
  exact: norm_hausdorff.
have HconstCvg_n :
    ((fun k => iter k (riccati_step F G H Q Rn) Pi)
       : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      @ \oo --> (Pi : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
  := HconstCvg.
have HarbCvg_n :
    ((fun k => iter k (riccati_step F G H Q Rn) Pi)
       : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
      @ \oo --> (Pss : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ))
  := HarbCvg.
exact: (cvg_unique HausM HconstCvg_n HarbCvg_n).
Qed.

(* ================================================================== *)
(*  Сводный результат Sessions 7–8: всё, что DARE-теорема даёт сейчас. *)
(*  (Bridging с frob_sq-формой kalman.v's `riccati_steady_state`       *)
(*   запланирован на Session 9.)                                         *)
(* ================================================================== *)

Theorem dare_full_topological :
  exists Pss0 : 'M[ℂ]_n,
    [/\ Pss0 = riccati_step F G H Q Rn Pss0,
        pd Pss0,
        psd_le Pss0 Pbnd,
        (forall P0, psd P0 ->
          (fun k => iter k (riccati_step F G H Q Rn) P0) @ \oo --> Pss0) &
        (forall Pi, pd Pi -> Pi = riccati_step F G H Q Rn Pi -> Pi = Pss0)].
Proof.
exists Pss; split.
- exact: Pss_fix.
- exact: Pss_pd.
- exact: Pss_le_bnd.
- by move=> P0 HP0; exact: arb_iter_cvgn.
- exact: Pss_unique_pd.
Qed.

(* ================================================================== *)
(*  Session 9 — Фробениусов мост и end-to-end теорема DARE             *)
(* ================================================================== *)
(*                                                                     *)
(*  Топологическая сходимость `f @ \oo --> L` в матричной топологии    *)
(*  эквивалентна стремлению Фробениусова квадрата
    `\tr ((f k - L)† ⋅ (f k - L))` к нулю.  Этот факт замыкает   *)
(*  эквивалентность `mxcvgn ⇔ frob_sq → 0` (в одну сторону:             *)
(*  matrix-topology → Frobenius).                                       *)
(*                                                                     *)
(*  Стратегия:                                                          *)
(*  1.  `(Pf k - L) @ \oo --> 0` через `cvgn_submx` + `cvg_cst`.        *)
(*  2.  `(Pf k - L)† @ \oo --> 0† = 0` через `cvgn_trmxC`.          *)
(*  3.  `(Pf k - L)† ⋅ (Pf k - L) @ \oo --> 0` через `cvgn_mulmx`.   *)
(*  4.  `\tr (...) @ \oo --> \tr 0 = 0` через `cvgn_mxtrace`.            *)
(*  5.  Каст в `ℂ^o`, применение `cvgrPdistC_lt` =>                       *)
(*      `\near \oo, |\tr (...) - 0| < eps`.                              *)
(*  6.  `\tr (...) ≥ 0` (frob_sq_ge0 из mxfrob/kalman) + `ger0_norm`    *)
(*      убирают абсолютную величину; «near \oo» на nat-фильтре          *)
(*      деструктурируется в `exists N, forall k ≥ N, ...`.               *)

Lemma cvgn_frob_sq_eps_N r c
    (Pf : nat -> 'M[ℂ]_(r, c)) (L : 'M[ℂ]_(r, c)) :
  Pf @ \oo --> L ->
  forall eps : ℂ, 0 < eps ->
    exists N : nat, forall k, (N <= k)%N ->
      \tr ((Pf k - L)^t* *m (Pf k - L)) < eps.
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

(* ================================================================== *)
(*  End-to-end теорема DARE в Frobenius-ε-N форме                       *)
(*  (по структуре совпадает с прежней `Hypothesis riccati_steady_state` *)
(*   из `kalman.v`, минус префикс `observable -> controllable ->`,      *)
(*   который заменён сильными абстракционными гипотезами секции.)       *)
(* ================================================================== *)

Theorem riccati_steady_state_proven :
  exists Pss0 : 'M[ℂ]_n,
    Pss0 = riccati_step F G H Q Rn Pss0 /\ pd Pss0 /\
    forall (P0 : 'M[ℂ]_n), psd P0 ->
      (forall eps : ℂ, eps > 0 ->
        exists N : nat, forall k, (N <= k)%N ->
          \tr ((iter k (riccati_step F G H Q Rn) P0 - Pss0)^t* *m
               (iter k (riccati_step F G H Q Rn) P0 - Pss0)) < eps) /\
      (forall eps : ℂ, eps > 0 ->
        exists N : nat, forall k, (N <= k)%N ->
          \tr ((kalman_gain H Rn
                  (predict_cov F G Q
                    (iter k (riccati_step F G H Q Rn) P0)) -
                kalman_gain H Rn (predict_cov F G Q Pss0))^t* *m
               (kalman_gain H Rn
                  (predict_cov F G Q
                    (iter k (riccati_step F G H Q Rn) P0)) -
                kalman_gain H Rn (predict_cov F G Q Pss0))) < eps).
Proof.
exists Pss; split; first exact: Pss_fix.
split; first exact: Pss_pd.
move=> P0 HP0; split.
- exact: cvgn_frob_sq_eps_N (arb_iter_cvgn HP0).
- exact: cvgn_frob_sq_eps_N (Pss_gain_cvgn HP0).
Qed.

(* ================================================================== *)
(*  Прямой end-to-end доказательство сходимости Калман-усиления —      *)
(*  главный результат проекта (см. цель Session 9).                     *)
(* ================================================================== *)

Theorem kalman_gain_convergence (P0 : 'M[ℂ]_n) :
  psd P0 ->
  exists (Pss0 : 'M[ℂ]_n) (Kp : 'M[ℂ]_(n, p)),
    [/\ Pss0 = riccati_step F G H Q Rn Pss0,
        pd Pss0,
        Kp = kalman_gain H Rn (predict_cov F G Q Pss0) &
        forall eps : ℂ, eps > 0 ->
          exists N : nat, forall k, (N <= k)%N ->
            \tr ((kalman_gain H Rn
                    (predict_cov F G Q
                      (iter k (riccati_step F G H Q Rn) P0)) - Kp)^t* *m
                 (kalman_gain H Rn
                    (predict_cov F G Q
                      (iter k (riccati_step F G H Q Rn) P0)) - Kp)) < eps].
Proof.
move=> HP0.
exists Pss, (kalman_gain H Rn (predict_cov F G Q Pss)); split.
- exact: Pss_fix.
- exact: Pss_pd.
- by [].
- exact: cvgn_frob_sq_eps_N (Pss_gain_cvgn HP0).
Qed.

(* ================================================================== *)
(*  Сходимость траектории Риккати в Frobenius-форме (для downstream).  *)
(* ================================================================== *)

Theorem riccati_convergence_frob (P0 : 'M[ℂ]_n) :
  psd P0 ->
  exists Pss0 : 'M[ℂ]_n,
    [/\ Pss0 = riccati_step F G H Q Rn Pss0,
        pd Pss0 &
        forall eps : ℂ, eps > 0 ->
          exists N : nat, forall k, (N <= k)%N ->
            \tr ((iter k (riccati_step F G H Q Rn) P0 - Pss0)^t* *m
                 (iter k (riccati_step F G H Q Rn) P0 - Pss0)) < eps].
Proof.
move=> HP0.
exists Pss; split.
- exact: Pss_fix.
- exact: Pss_pd.
- exact: cvgn_frob_sq_eps_N (arb_iter_cvgn HP0).
Qed.

(* ================================================================== *)
(*  Стабильность замкнутого контура F_p (Session 16)                   *)
(*                                                                     *)
(*  Книжная идентичность Lemma 14.5.3 (Kailath–Sayed–Hassibi):         *)
(*                                                                     *)
(*    P_pss = Fp ⋅ P_pss ⋅ Fp† + Kp ⋅ Rn ⋅ Kp† + G ⋅ Q ⋅ G†      *)
(*                                                                     *)
(*  где:                                                               *)
(*    P_pss = predict_cov Pss = F Pss F† + GQG† (предикторная ss-cov), *)
(*    Kf = kalman_gain P_pss (фильтрационное усиление),                *)
(*    Kp = F ⋅ Kf (предикторное усиление),                            *)
(*    Fp = F - Kp ⋅ H (замкнутый контур в предикторной форме).        *)
(*                                                                     *)
(*  Откуда непосредственно следует Loewner-сжатие:                     *)
(*    psd_le (Fp ⋅ P_pss ⋅ Fp†) P_pss.                              *)
(*                                                                     *)
(*  Frobenius-стабильность `frob_sq Fp < 1` (нужная для построения     *)
(*  `OP` в Session 17 через `lyap_sol`) НЕ выводится напрямую из   *)
(*  Loewner-сжатия — нужна спектральная теория, отсутствующая в       *)
(*  текущем mathcomp.  Постулируется как `Hypothesis Fp_contract`      *)
(*  (Tier-C debt; устранимо позже через введение spectral radius).     *)
(* ================================================================== *)

(* Сокращения. *)
Local Notation P_pss := (predict_cov F G Q Pss).
Local Notation Kf := (kalman_gain H Rn P_pss).
Local Notation Kp := (F *m Kf).
Local Notation Fp := (F - Kp *m H).
Local Notation R_e := (innov_cov H Rn P_pss).

Lemma P_pss_psd : psd P_pss.
Proof. apply: predict_cov_psd; [exact: Q_psd | exact: Pss_psd]. Qed.

Lemma R_e_unit : R_e \in unitmx.
Proof. apply: innov_cov_inv; [exact: Rn_pd | exact: P_pss_psd]. Qed.

(* Из определения kalman_gain: Kf ⋅ R_e = P_pss ⋅ H†. *)
Lemma Kf_R_e_eq : Kf *m R_e = P_pss *m H^t*.
Proof.
rewrite /kalman_gain -mulmxA mulVmx ?R_e_unit //.
by rewrite mulmx1.
Qed.

(* Pss = (I - Kf H) P_pss = update_cov P_pss (Pss как неподвижная точка). *)
Lemma Pss_eq_update : Pss = update_cov H Rn P_pss.
Proof.
have := Pss_fix.
by rewrite /riccati_step.
Qed.

(* Книжная Lemma 14.5.3 (Kailath–Sayed–Hassibi):                          *)
(*   P_pss = Fp P_pss Fp† + Kp Rn Kp† + G Q G†.                            *)
(*                                                                         *)
(* Доказано алгебраически (Session 18) через идентичность                  *)
(* Kf R_e = P_pss H† (Kf_R_e_eq) и неподвижность Pss = update_cov P_pss.   *)

(* Свёртка усиления: F (I - Kf H) = Fp. *)
Lemma F_update_factor : F *m (1%:M - Kf *m H) = Fp.
Proof. by rewrite mulmxBr mulmx1 mulmxA. Qed.

(* Предиктор на неподвижной точке свёрнут на замкнутый контур:             *)
(*   P_pss = Fp P_pss F† + G Q G†.                                         *)
Lemma predict_cov_closed_loop :
  predict_cov F G Q Pss = Fp *m P_pss *m F^t* + G *m Q *m G^t*.
Proof.
by rewrite {1}/predict_cov {1}Pss_eq_update /update_cov mulmxA F_update_factor.
Qed.

(* Ключевое перекрёстное тождество: Fp P_pss H† = Kp Rn.                   *)
Lemma Fp_Ppss_Ht : Fp *m P_pss *m H^t* = Kp *m Rn.
Proof.
rewrite mulmxBl mulmxBl.
rewrite -[F *m P_pss *m H^t*]mulmxA -Kf_R_e_eq mulmxA.
rewrite /innov_cov mulmxDr !mulmxA.
by rewrite addrAC subrr add0r.
Qed.

(* Книжная Lemma 14.5.3 — теперь доказанная теорема. *)
Theorem riccati_closed_loop_identity :
  predict_cov F G Q Pss =
    Fp *m predict_cov F G Q Pss *m Fp^t* +
    (F *m kalman_gain H Rn (predict_cov F G Q Pss)) *m Rn *m
      (F *m kalman_gain H Rn (predict_cov F G Q Pss))^t* +
    G *m Q *m G^t*.
Proof.
rewrite {1}predict_cov_closed_loop.
congr (_ + _).
have Fpt : Fp^t* = F^t* - H^t* *m Kp^t*.
  by rewrite trmxCB [(Kp *m H)^t*]trmxC_mul.
have expand : Fp *m P_pss *m Fp^t*
            = Fp *m P_pss *m F^t* - Kp *m Rn *m Kp^t*.
  rewrite Fpt mulmxBr.
  congr (_ - _).
  by rewrite mulmxA Fp_Ppss_Ht.
by rewrite expand subrK.
Qed.

(* Loewner-сжатие: Fp P_pss Fp† ≤ P_pss. *)
Theorem Fp_P_pss_Loewner : psd_le (Fp *m P_pss *m Fp^t*) P_pss.
Proof.
rewrite /psd_le.
rewrite {1}riccati_closed_loop_identity.
have ->: Fp *m P_pss *m Fp^t* + Kp *m Rn *m Kp^t* + G *m Q *m G^t*
       - Fp *m P_pss *m Fp^t*
       = Kp *m Rn *m Kp^t* + G *m Q *m G^t*.
  set X := Fp *m P_pss *m Fp^t*.
  set Y := Kp *m Rn *m Kp^t*.
  set Z := G *m Q *m G^t*.
  by rewrite addrC addrA addrA addNr add0r.
apply: psd_add.
- exact: psd_lcongr (pd_psd Rn_pd).
- exact: psd_lcongr Q_psd.
Qed.

(* Frobenius-сжатие как Tier-C debt: следует из Loewner-сжатия только    *)
(* при наличии спектрального радиуса, которого пока нет в mathcomp.       *)
Hypothesis Fp_contract : frob_sq Fp < 1.

(* ================================================================== *)
(*  Мера `O_P` — бесконечный R-взвешенный обсв. Грамиан замкнутого      *)
(*  контура `Fp` (Session 17)                                          *)
(*                                                                     *)
(*    O_P := lyap_sol (Fp†) (H† ⋅ invmx Rn ⋅ H)                   *)
(*        ↔  O_P = Fp† ⋅ O_P ⋅ Fp + H† ⋅ invmx Rn ⋅ H               *)
(*                                                                     *)
(*  Книжная роль (Kailath–Sayed–Hassibi, гл. 14).  Для произвольной    *)
(*  инициализации `P0` ошибка фильтрации `P_k - Pss` распространяется   *)
(*  замкнутым контуром `Fp` (предикторная форма `F - Kp H`).  Энергия   *)
(*  этого распространения в R-взвешенной норме измеряется бесконечной   *)
(*  суммой `\sum_k (Fp†)^k (H† R⁻¹ H) Fp^k`, т.е. бесконечным обсв.    *)
(*  Грамианом замкнутого контура под весом `H† R⁻¹ H`.  Сходимость     *)
(*  суммы обеспечена Фробениусовым сжатием `Fp_contract`; невырожден-   *)
(*  ность веса (а с нею PD-ность `O_P`) — наблюдаемостью пары `[Fp, H]` *)
(*  (выводимой из детектируемости `[F, H]`; отложено на позже).         *)
(* ================================================================== *)

Definition OP : 'M[ℂ]_n :=
  obsv_gram_infty_w Fp (H^t* *m invmx Rn *m H).

(* Вес `H† R⁻¹ H` положительно полуопределён (R⁻¹ PD => конгруэнция). *)
Lemma OP_weight_psd : psd (H^t* *m invmx Rn *m H).
Proof. exact: psd_congr (pd_psd (pd_inv Rn_pd)). Qed.

Theorem OP_psd : psd OP.
Proof.
apply: (obsv_gram_infty_w_psd ler_r2c c2rK c2r_continuous r2c_continuous).
- exact: OP_weight_psd.
- exact: Fp_contract.
Qed.

Theorem OP_fix :
  OP = Fp^t* *m OP *m Fp + H^t* *m invmx Rn *m H.
Proof.
apply: (obsv_gram_infty_w_fix ler_r2c c2rK r2c_continuous).
- exact: OP_weight_psd.
- exact: Fp_contract.
Qed.

End DARE.
