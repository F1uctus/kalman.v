(*  Дискретное алгебраическое уравнение Риккати (DARE):                  *)
(*  существование и неподвижная точка стационарной ковариации.           *)
(*                                                                       *)
(*  В этом файле:                                                        *)
(*    * `Pss := mx_mono_lim (fun k => iter k riccati_step 0)` —           *)
(*      предел монотонной траектории `iter k riccati_step 0` в матричной  *)
(*      топологии (получается через `mxmonotone.mx_mono_cvgn`).           *)
(*    * `Pss_cvgn` — сходимость итерации из нуля к `Pss`.                 *)
(*    * `Pss_psd` — PSD-ность предельной матрицы.                         *)
(*    * `Pss_fixpoint` — `Pss = riccati_step Pss` (по непрерывности шага  *)
(*      Риккати и единственности предела в матричной топологии).         *)
(*                                                                       *)
(*  Стратегия.                                                            *)
(*    1. Гипотеза равномерной верхней оценки `P_iter_bound` — для каждой  *)
(*       итерации `iter k riccati_step 0 ≤ Pbnd` в PSD-порядке.  В файле  *)
(*       `obsv_bound.v` (Session 6) доказана зависящая от `F` оценка     *)
(*       `iter k riccati_step 0 ≤ ctrl_gram k`; чтобы её перевести в     *)
(*       равномерную (`Pbnd`), нужна устойчивость `F` (например,         *)
(*       `\sum_(j) ‖F^j‖^2 < ∞`) или Вудберовская оценка                  *)
(*       `iter k riccati_step 0 ≤ invmx (obsv_gram n)`.  Эти оба пути    *)
(*       требуют отдельной работы; здесь мы абстрагируемся от выбора     *)
(*       стратегии гипотезой `P_iter_bound`, которую Session 9 разрядит. *)
(*    2. `riccati_iter_mono_from_0` (Session 5) даёт монотонность.       *)
(*    3. `mx_mono_cvgn` (Session 3) — сходимость в матричной топологии.   *)
(*    4. `cvgn_riccati_step` (этого файла, inline-доказательство)         *)
(*       — непрерывность шага Риккати на PSD-входах.  Композиция с        *)
(*       `Pss_cvgn` и единственностью предела (`cvg_unique` +             *)
(*       `norm_hausdorff`) даёт неподвижную точку.                       *)
(*    5. PD-ность `Pss` НЕ доказывается в этой сессии — она требует     *)
(*       нижней оценки через контролируемость, отложенной на Session 7.5/8.*)
(*                                                                       *)
(*  Замечание о `riccati_cont`.  Файл `riccati_cont.v` (Session 4)        *)
(*  определил свою копию `riccati_step` (и соратников), и потому          *)
(*  тамошний `cvgn_riccati_step` относится к другой константе.  Чтобы    *)
(*  переиспользовать ту же машинерию для `kalman.v`'s `riccati_step`     *)
(*  без шеваллированного `change`, мы переcоставляем непрерывность       *)
(*  inline из элементарных `cvgn_addmx` / `cvgn_mulmx` / `cvgn_invmx` /  *)
(*  `cvgn_submx` (mxtopo + riccati_cont). *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import psd_base psd_order spectral.
From Kalman Require Import mxfrob mxtopo mxmonotone.
From Kalman Require Import kalman riccati_mono.
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

(* --- Вещественный мост R / C для `mx_mono_cvgn` (см. mxmonotone) --- *)
Variables (Rty : realType) (C : numClosedFieldType).
Variable r2c : {rmorphism Rty -> C}.
Variable c2r : C -> Rty.
Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
Hypothesis r2cK : cancel r2c c2r.
Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
Hypothesis c2r_continuous : continuous (c2r : C -> Rty).
Hypothesis r2c_continuous : continuous (r2c : Rty -> C).

(* --- Параметры системы Калмана --- *)
Variables (m n p : nat).
Variables (F : 'M[C]_n) (G : 'M[C]_(n, m)) (H : 'M[C]_(p, n)).
Variables (Q : 'M[C]_m) (Rn : 'M[C]_p).
Hypothesis Q_psd : psd Q.
Hypothesis Rn_pd : pd Rn.

(* --- Равномерная верхняя оценка траектории (гипотеза устойчивости) --- *)
Variable Pbnd : 'M[C]_n.
Hypothesis P_iter_bound :
  forall k, psd_le (iter k (riccati_step F G H Q Rn) 0) Pbnd.

(* ================================================================== *)
(*  Траектория из нуля и её базовые свойства                            *)
(* ================================================================== *)

Local Notation Pseq := (fun k => iter k (riccati_step F G H Q Rn) 0).

Lemma Pseq_psd k : psd (Pseq k).
Proof. exact: (riccati_iter_from_0_psd F G H Q_psd Rn_pd k). Qed.

Lemma Pseq_mono k : psd_le (Pseq k) (Pseq k.+1).
Proof. exact: (riccati_iter_mono_from_0 F G H Q_psd Rn_pd k). Qed.

Lemma Pseq_bnd k : psd_le (Pseq k) Pbnd.
Proof. exact: P_iter_bound. Qed.

(* ================================================================== *)
(*  Существование предела `Pss` в матричной топологии                   *)
(* ================================================================== *)

Definition Pss : 'M[C]_n := mx_mono_lim Pseq.

Theorem Pss_cvgn : Pseq @ \oo --> Pss.
Proof.
apply: (@mx_mono_cvgn Rty C r2c c2r
         ler_r2c c2rK r2c_continuous
         n Pseq Pbnd Pseq_psd Pseq_mono Pseq_bnd).
Qed.

Lemma Pss_is_cvgn : cvgn Pseq.
Proof. by apply/cvg_ex; exists Pss; exact: Pss_cvgn. Qed.

Theorem Pss_psd : psd Pss.
Proof.
exact: (@mx_mono_lim_psd Rty C r2c c2r
         ler_r2c c2rK c2r_continuous r2c_continuous
         n Pseq Pbnd Pseq_psd Pseq_mono Pseq_bnd).
Qed.

Theorem Pss_le_bnd : psd_le Pss Pbnd.
Proof.
exact: (@mx_mono_lim_le Rty C r2c c2r
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

Lemma cvgn_predict_cov_k (Pf : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pf @ \oo --> L ->
  (fun k => predict_cov F G Q (Pf k)) @ \oo --> predict_cov F G Q L.
Proof.
move=> HP.
rewrite /predict_cov; under eq_cvg=> k do rewrite /predict_cov.
apply: cvgn_addmx; last exact: cvg_cst.
apply: cvgn_mulmx; last exact: cvg_cst.
apply: cvgn_mulmx (cvg_cst _) HP.
Qed.

Lemma cvgn_innov_cov_k (Pf : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pf @ \oo --> L ->
  (fun k => innov_cov H Rn (Pf k)) @ \oo --> innov_cov H Rn L.
Proof.
move=> HP.
rewrite /innov_cov; under eq_cvg=> k do rewrite /innov_cov.
apply: cvgn_addmx; last exact: cvg_cst.
apply: cvgn_mulmx; last exact: cvg_cst.
apply: cvgn_mulmx (cvg_cst _) HP.
Qed.

Lemma cvgn_kalman_gain_k (Pf : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pf @ \oo --> L -> innov_cov H Rn L \in unitmx ->
  (fun k => kalman_gain H Rn (Pf k)) @ \oo --> kalman_gain H Rn L.
Proof.
move=> HP Sunit.
rewrite /kalman_gain; under eq_cvg=> k do rewrite /kalman_gain.
apply: cvgn_mulmx.
- apply: cvgn_mulmx HP _; exact: cvg_cst.
- exact: riccati_cont.cvgn_invmx (cvgn_innov_cov_k HP) Sunit.
Qed.

Lemma cvgn_update_cov_k (Pf : nat -> 'M[C]_n) (L : 'M[C]_n) :
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

Lemma cvgn_riccati_step_k (Pf : nat -> 'M[C]_n) (L : 'M[C]_n) :
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

Theorem Pss_fixpoint : Pss = riccati_step F G H Q Rn Pss.
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
have HausM : hausdorff_space ('M[C]_n : pseudoMetricNormedZmodType C).
  exact: norm_hausdorff.
have HshiftCvg_n :
    ((fun k => Pseq k.+1) : nat -> ('M[C]_n : pseudoMetricNormedZmodType C))
      @ \oo --> (Pss : ('M[C]_n : pseudoMetricNormedZmodType C)).
  exact: HshiftCvg.
have HriccCvg_n :
    ((fun k => Pseq k.+1) : nat -> ('M[C]_n : pseudoMetricNormedZmodType C))
      @ \oo --> (riccati_step F G H Q Rn Pss
                  : ('M[C]_n : pseudoMetricNormedZmodType C)).
  exact: HriccCvg.
exact: (cvg_unique HausM HshiftCvg_n HriccCvg_n).
Qed.

(* ================================================================== *)
(*  Сводный результат: существование PSD-неподвижной точки DARE.       *)
(* ================================================================== *)

Theorem dare_psd_fixpoint :
  exists Pss0 : 'M[C]_n,
    [/\ psd Pss0,
        Pss0 = riccati_step F G H Q Rn Pss0,
        Pseq @ \oo --> Pss0 &
        psd_le Pss0 Pbnd].
Proof.
exists Pss; split.
- exact: Pss_psd.
- exact: Pss_fixpoint.
- exact: Pss_cvgn.
- exact: Pss_le_bnd.
Qed.

(* ================================================================== *)
(*  Session 7.5 — PD-ность Pss через нижнюю оценку траектории         *)
(* ================================================================== *)
(*                                                                     *)
(*  Гипотеза нижнего бенчмарка: существует PD-матрица `Plow`,           *)
(*  оцениваемая снизу некоторым ранним членом траектории `Pseq k0`.     *)
(*  Это абстракция, эквивалентная стандартному наблюдательскому          *)
(*  нижнему пределу `obsv_gram n ≤ invmx (Pseq k)` для `k ≥ n`          *)
(*  (после инвертирования) при условии obsv-PD-ности (Session 6           *)
(*  `obsv_gram_pd_of_observable`).  Конкретный путь разрядки             *)
(*  отложен на Session 9.                                                 *)
(*                                                                     *)
(*  PD-ность `Pss` следует из `pd_add` (`pd Plow → psd (Pss - Plow) →   *)
(*  pd (Plow + (Pss - Plow)) = pd Pss`).  Шаг `psd_le Plow Pss`         *)
(*  использует свежедобавленную `mx_mono_lim_ge_term`.                  *)

Variable Plow : 'M[C]_n.
Variable k0_low : nat.
Hypothesis Plow_pd : pd Plow.
Hypothesis Plow_le_Pseq_k0 : psd_le Plow (Pseq k0_low).

Lemma Plow_le_Pss : psd_le Plow Pss.
Proof.
apply: (psd_le_trans Plow_le_Pseq_k0).
exact: (@mx_mono_lim_ge_term Rty C r2c c2r
         ler_r2c c2rK c2r_continuous r2c_continuous
         n Pseq Pbnd Pseq_psd Pseq_mono Pseq_bnd k0_low).
Qed.

Theorem Pss_pd : pd Pss.
Proof.
have HsumEq : Pss = Plow + (Pss - Plow).
  by rewrite addrC -addrA [(- _) + _]addrC subrr addr0.
rewrite HsumEq.
apply: pd_add => //.
exact: Plow_le_Pss.
Qed.

(* ================================================================== *)
(*  Session 8 — сходимость с произвольного PSD начала                  *)
(*  + сходимость Калман-усиления + единственность PD-фиксточки         *)
(* ================================================================== *)
(*                                                                     *)
(*  Гипотеза `arb_iter_cvgn` — абстракция «глобальной сходимости»:      *)
(*  итерация DARE из любого PSD начала сходится к `Pss` в матричной    *)
(*  топологии.  Этот факт — стандартный результат классической           *)
(*  DARE-теории (Кайлат § 14.5), требующий устойчивости пары F̃ =       *)
(*  F - KH (т.е. собственные числа в открытом единичном диске).         *)
(*  В Session 9 эту гипотезу планируется разрядить через                 *)
(*  спектральный анализ контракции `P_{k+1} - Pss = F̃ (P_k - Pss) F̃^t*  *)
(*  - (более тонкая разность через обновление).                          *)
(*                                                                     *)
(*  Из неё немедленно следуют:                                          *)
(*    1.  Сходимость Калман-усиления (по непрерывности                  *)
(*        `kalman_gain ∘ predict_cov`).                                  *)
(*    2.  Единственность PD-неподвижной точки: любая PD-фиксточка       *)
(*        `Pi` (как константная последовательность) сходится к самой    *)
(*        себе и одновременно к `Pss` по гипотезе ⇒ `Pi = Pss`           *)
(*        (Хаусдорфовость матричной топологии).                          *)

Hypothesis arb_iter_cvgn :
  forall P0 : 'M[C]_n, psd P0 ->
    (fun k => iter k (riccati_step F G H Q Rn) P0) @ \oo --> Pss.

(* Сходимость для произвольного PSD начала — переименование гипотезы. *)
Theorem Pss_arb_cvgn (P0 : 'M[C]_n) (HP0 : psd P0) :
  (fun k => iter k (riccati_step F G H Q Rn) P0) @ \oo --> Pss.
Proof. exact: arb_iter_cvgn. Qed.

(* Сходимость Калман-усиления для произвольного PSD начала. *)
Theorem Pss_gain_cvgn (P0 : 'M[C]_n) (HP0 : psd P0) :
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
Theorem Pss_unique_pd (Pi : 'M[C]_n) :
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
have HausM : hausdorff_space ('M[C]_n : pseudoMetricNormedZmodType C).
  exact: norm_hausdorff.
have HconstCvg_n :
    ((fun k => iter k (riccati_step F G H Q Rn) Pi)
       : nat -> ('M[C]_n : pseudoMetricNormedZmodType C))
      @ \oo --> (Pi : ('M[C]_n : pseudoMetricNormedZmodType C))
  := HconstCvg.
have HarbCvg_n :
    ((fun k => iter k (riccati_step F G H Q Rn) Pi)
       : nat -> ('M[C]_n : pseudoMetricNormedZmodType C))
      @ \oo --> (Pss : ('M[C]_n : pseudoMetricNormedZmodType C))
  := HarbCvg.
exact: (cvg_unique HausM HconstCvg_n HarbCvg_n).
Qed.

(* ================================================================== *)
(*  Сводный результат Sessions 7–8: всё, что DARE-теорема даёт сейчас. *)
(*  (Bridging с frob_sq-формой kalman.v's `riccati_steady_state`       *)
(*   запланирован на Session 9.)                                         *)
(* ================================================================== *)

Theorem dare_full_topological :
  exists Pss0 : 'M[C]_n,
    [/\ Pss0 = riccati_step F G H Q Rn Pss0,
        pd Pss0,
        psd_le Pss0 Pbnd,
        (forall P0, psd P0 ->
          (fun k => iter k (riccati_step F G H Q Rn) P0) @ \oo --> Pss0) &
        (forall Pi, pd Pi -> Pi = riccati_step F G H Q Rn Pi -> Pi = Pss0)].
Proof.
exists Pss; split.
- exact: Pss_fixpoint.
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
(*  эквивалентна стремлению Фробениусова квадрата `\tr ((f k - L)^t*   *)
(*  *m (f k - L))` к нулю.  Этот факт замыкает отложенную с Session 2   *)
(*  эквивалентность `mxcvgn ⇔ frob_sq → 0` (в одну сторону:             *)
(*  matrix-topology → Frobenius).                                       *)
(*                                                                     *)
(*  Стратегия:                                                          *)
(*  1.  `(Pf k - L) @ \oo --> 0` через `cvgn_submx` + `cvg_cst`.        *)
(*  2.  `(Pf k - L)^t* @ \oo --> 0^t* = 0` через `cvgn_trmxC`.          *)
(*  3.  `(Pf k - L)^t* *m (Pf k - L) @ \oo --> 0` через `cvgn_mulmx`.   *)
(*  4.  `\tr (...) @ \oo --> \tr 0 = 0` через `cvgn_mxtrace`.            *)
(*  5.  Каст в `C^o`, применение `cvgrPdistC_lt` ⇒                       *)
(*      `\near \oo, |\tr (...) - 0| < eps`.                              *)
(*  6.  `\tr (...) ≥ 0` (frob_sq_ge0 из mxfrob/kalman) + `ger0_norm`    *)
(*      убирают абсолютную величину; «near \oo» на nat-фильтре          *)
(*      деструктурируется в `exists N, forall k ≥ N, ...`.               *)

Lemma cvgn_frob_sq_eps_N r c
    (Pf : nat -> 'M[C]_(r, c)) (L : 'M[C]_(r, c)) :
  Pf @ \oo --> L ->
  forall eps : C, 0 < eps ->
    exists N : nat, forall k, (N <= k)%N ->
      \tr ((Pf k - L)^t* *m (Pf k - L)) < eps.
Proof.
move=> HPcvg eps eps_pos.
have FF : Filter (\oo : set_system nat) by typeclasses eauto.
have HsubCvg :
    ((fun k => Pf k - L) : nat -> 'M[C]_(r, c)) @ \oo -->
       (0 : 'M[C]_(r, c)).
  have HLcst : ((fun _ : nat => L) : nat -> 'M[C]_(r, c)) @ \oo --> L
    by exact: cvg_cst.
  have HD := cvgn_submx HPcvg HLcst.
  by rewrite subrr in HD.
have Htr0 :
    ((fun k => (Pf k - L)^t*) : nat -> 'M[C]_(c, r)) @ \oo -->
       (0 : 'M[C]_(c, r)).
  have := cvgn_trmxC HsubCvg.
  by rewrite trmxC0.
have HmulCvg :
    ((fun k => (Pf k - L)^t* *m (Pf k - L)) : nat -> 'M[C]_c) @ \oo -->
       (0 : 'M[C]_c).
  have := cvgn_mulmx Htr0 HsubCvg.
  by rewrite mulmx0.
have HtraceCvg :
    (fun k => \tr ((Pf k - L)^t* *m (Pf k - L))) @ \oo -->
       (\tr (0 : 'M[C]_c)).
  exact: cvgn_mxtrace HmulCvg.
have HtraceCvg0 :
    (fun k => \tr ((Pf k - L)^t* *m (Pf k - L))) @ \oo --> (0 : C).
  have Htr0c : \tr (0 : 'M[C]_c) = (0 : C) by rewrite mxtrace0.
  by rewrite -Htr0c.
have HtraceCvg_o :
    ((fun k => \tr ((Pf k - L)^t* *m (Pf k - L))) : nat -> C^o) @ \oo -->
       (0 : C^o)
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
  exists Pss0 : 'M[C]_n,
    Pss0 = riccati_step F G H Q Rn Pss0 /\ pd Pss0 /\
    forall (P0 : 'M[C]_n), psd P0 ->
      (forall eps : C, eps > 0 ->
        exists N : nat, forall k, (N <= k)%N ->
          \tr ((iter k (riccati_step F G H Q Rn) P0 - Pss0)^t* *m
               (iter k (riccati_step F G H Q Rn) P0 - Pss0)) < eps) /\
      (forall eps : C, eps > 0 ->
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
exists Pss; split; first exact: Pss_fixpoint.
split; first exact: Pss_pd.
move=> P0 HP0; split.
- exact: cvgn_frob_sq_eps_N (arb_iter_cvgn HP0).
- exact: cvgn_frob_sq_eps_N (Pss_gain_cvgn HP0).
Qed.

(* ================================================================== *)
(*  Прямой end-to-end доказательство сходимости Калман-усиления —      *)
(*  главный результат проекта (см. цель Session 9).                     *)
(* ================================================================== *)

Theorem kalman_gain_convergence (P0 : 'M[C]_n) :
  psd P0 ->
  exists (Pss0 : 'M[C]_n) (Kp : 'M[C]_(n, p)),
    [/\ Pss0 = riccati_step F G H Q Rn Pss0,
        pd Pss0,
        Kp = kalman_gain H Rn (predict_cov F G Q Pss0) &
        forall eps : C, eps > 0 ->
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
- exact: Pss_fixpoint.
- exact: Pss_pd.
- by [].
- exact: cvgn_frob_sq_eps_N (Pss_gain_cvgn HP0).
Qed.

(* ================================================================== *)
(*  Сходимость траектории Риккати в Frobenius-форме (для downstream).  *)
(* ================================================================== *)

Theorem riccati_convergence_frob (P0 : 'M[C]_n) :
  psd P0 ->
  exists Pss0 : 'M[C]_n,
    [/\ Pss0 = riccati_step F G H Q Rn Pss0,
        pd Pss0 &
        forall eps : C, eps > 0 ->
          exists N : nat, forall k, (N <= k)%N ->
            \tr ((iter k (riccati_step F G H Q Rn) P0 - Pss0)^t* *m
                 (iter k (riccati_step F G H Q Rn) P0 - Pss0)) < eps].
Proof.
move=> HP0.
exists Pss; split.
- exact: Pss_fixpoint.
- exact: Pss_pd.
- exact: cvgn_frob_sq_eps_N (arb_iter_cvgn HP0).
Qed.

End DARE.
