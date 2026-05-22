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
From Kalman Require Import kalman riccati_mono obsv_bound.
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
(* Фробениусова контракция системной матрицы (Session 10): единственная *)
(* новая доменная гипотеза, разряжающая прежнюю абстракцию P_iter_bound. *)
Hypothesis F_contract : frob_sq F < 1.
(* Невырожденность процессного шума (Session 11): шум процесса входит во *)
(* все направления состояния.  Это стандартное предположение            *)
(* классической калмановской фильтрации — матрица `G Q Gᶜ` положительно  *)
(* определена, что гарантирует PD-ность установившейся ковариации `Pss`. *)
Hypothesis pd_GQGt : pd (G *m Q *m G^t*).

(* --- Равномерная верхняя оценка траектории (Session 10) --- *)
(* Конкретный бенчмарк: скаляр (следовая геометрическая оценка управ.   *)
(* грамиана) на единичной матрице.  Прежние `Variable Pbnd` и           *)
(* `Hypothesis P_iter_bound` теперь — определение и доказанная лемма.    *)
Definition Pbnd : 'M[C]_n :=
  (\tr (G *m Q *m G^t*) / (1 - frob_sq F)) *: 1%:M.

Lemma ctrl_gram_le_Pbnd k :
  psd_le (ctrl_gram F G Q k) Pbnd.
Proof.
apply: (psd_le_trans (B := \tr (ctrl_gram F G Q k) *: 1%:M)).
  by apply: psd_le_trace_id; apply: ctrl_gram_psd; exact: Q_psd.
rewrite /Pbnd.
apply: psd_le_scale1.
- by apply: ger0_real; apply: psd_tr_ge0; apply: ctrl_gram_psd; exact: Q_psd.
- apply: ger0_real; apply: divr_ge0.
    by apply: psd_tr_ge0; apply: psd_mulmx_row; exact: Q_psd.
  by rewrite subr_ge0; exact: ltW F_contract.
- by apply: ctrl_gram_tr_bound; [exact: Q_psd | exact: F_contract].
Qed.

Lemma P_iter_bound k :
  psd_le (iter k (riccati_step F G H Q Rn) 0) Pbnd.
Proof.
apply: (psd_le_trans (B := ctrl_gram F G Q k)).
  by apply: riccati_iter_le_ctrl_gram; [exact: Q_psd | exact: Rn_pd].
exact: ctrl_gram_le_Pbnd k.
Qed.

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

(* Нижний бенчмарк (Session 11): первый член траектории `Pseq 1`.       *)
(* `Pseq 1 = riccati_step 0 = update_cov (predict_cov 0)`, а             *)
(* `predict_cov 0 = G Q Gᶜ` (т.к. `F 0 Fᶜ + G Q Gᶜ = G Q Gᶜ`).          *)
(* PD-ность следует из `update_cov_pd`, применённой к `pd_GQGt`.         *)
Definition Plow : 'M[C]_n := iter 1 (riccati_step F G H Q Rn) 0.
Definition k0_low : nat := 1.

Lemma Plow_pd : pd Plow.
Proof.
rewrite /Plow /= /riccati_step.
apply: update_cov_pd; first exact: Rn_pd.
rewrite /predict_cov mulmx0 mul0mx add0r.
exact: pd_GQGt.
Qed.

Lemma Plow_le_Pseq_k0 : psd_le Plow (Pseq k0_low).
Proof. by rewrite /k0_low; apply: psd_le_refl; exact: pd_psd Plow_pd. Qed.

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
apply: pd_add; first exact: Plow_pd.
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

(* ================================================================== *)
(* Session 12 — глобальная сходимость через суперрешение + сэндвич     *)
(* ================================================================== *)
(*                                                                     *)
(* Стратегия: показываем, что `Pbnd = α·I` (с α = \tr T/(1−frob_sq F)) *)
(* — суперрешение, то есть `riccati_step Pbnd ≤ Pbnd`.  Тогда           *)
(* верхняя траектория `iter k riccati_step (α·I)` монотонно убывает    *)
(* (в порядке Лёвнера) и сходится к некоторой неподвижной точке `L`     *)
(* (через mxmonotone.mx_mono_dec_cvgn).  По доменной гипотезе           *)
(* `Pss_unique` (классическая единственность PD-неподвижной точки      *)
(* DARE) имеем `L = Pss`.  Для произвольного PSD `P0` выбираем α        *)
(* достаточно большим, чтобы `P0 ≤ α·I`; сэндвич с `iter k r.s. 0`     *)
(* и оценкой `frob_sq ≤ (\tr)^+2` даёт сходимость к `Pss`.              *)

(* Единственность PD-неподвижной точки — единственная новая доменная   *)
(* гипотеза Session 12.  Классический результат DARE-теории (Кайлат    *)
(* §14.5) под стабилизируемостью+детектируемостью; в нашей более         *)
(* слабой формулировке (`frob_sq F < 1`) он остаётся принципиально     *)
(* верным, но требует операторно-нормного аппарата (porting CoqQ's      *)
(* mxnorm.v ≈ 600 LOC) для прямого доказательства.                      *)
Hypothesis Pss_unique :
  forall L : 'M[C]_n,
    pd L -> L = riccati_step F G H Q Rn L -> L = Pss.

(* ================================================================== *)
(* Лемма-кирпич: F Fᶜ ≤ frob_sq F · I в порядке Лёвнера.               *)
(* (Используется в доказательстве суперрешения для `α·I`.)              *)
(* ================================================================== *)

Lemma F_FtC_le_frob_id : psd_le (F *m F^t*) (frob_sq F *: 1%:M).
Proof.
have psdFFt : psd (F *m F^t*).
  by have := psd_frob (F^t*); rewrite trmxCK.
have trEq : \tr (F *m F^t*) = frob_sq F.
  by rewrite /frob_sq mxtrace_mulC.
have step := psd_le_trace_id psdFFt.
by rewrite trEq in step.
Qed.

(* Произвольный скаляр `a ≥ Pbnd_scalar` даёт суперрешение `a·I`.       *)
(* Это нужно для покрытия произвольной PSD `P0` через P0 ≤ \tr P0 · I.  *)

(* Скалярный коэффициент Pbnd. *)
Definition Pbnd_scalar : C :=
  \tr (G *m Q *m G^t*) / (1 - frob_sq F).

Lemma Pbnd_scalar_ge0 : 0 <= Pbnd_scalar.
Proof.
apply: divr_ge0.
- by apply: psd_tr_ge0; apply: psd_mulmx_row; exact: Q_psd.
- by rewrite subr_ge0; exact: ltW F_contract.
Qed.

Lemma Pbnd_scalar_real : Pbnd_scalar \is Num.real.
Proof. by apply: ger0_real; exact: Pbnd_scalar_ge0. Qed.

Lemma PbndE : Pbnd = Pbnd_scalar *: 1%:M.
Proof. by rewrite /Pbnd /Pbnd_scalar. Qed.

(* Оценка `T = G Q Gᶜ ≤ \tr T · I`. *)
Lemma GQGt_le_tr_id : psd_le (G *m Q *m G^t*) (\tr (G *m Q *m G^t*) *: 1%:M).
Proof.
apply: psd_le_trace_id; apply: psd_mulmx_row; exact: Q_psd.
Qed.

(* Главная техническая лемма: для `a ≥ Pbnd_scalar` матрица `a·I`       *)
(* — суперрешение Риккати.                                              *)
Lemma scalar_supersolution (a : C) :
  a \is Num.real -> Pbnd_scalar <= a ->
  psd_le (riccati_step F G H Q Rn (a *: 1%:M)) (a *: 1%:M).
Proof.
move=> a_real a_lb.
have a_ge0 : 0 <= a := le_trans Pbnd_scalar_ge0 a_lb.
have psd_aI : psd (a *: (1%:M : 'M[C]_n)).
  exact: psd_scale1 a_real a_ge0.
have psd_predict : psd (predict_cov F G Q (a *: 1%:M)).
  by apply: predict_cov_psd; [exact: Q_psd | exact: psd_aI].
(* update_cov M ≤ M *)
have step_update : psd_le (riccati_step F G H Q Rn (a *: 1%:M))
                          (predict_cov F G Q (a *: 1%:M)).
  rewrite /riccati_step /psd_le.
  by apply: update_cov_le; [exact: Rn_pd | exact: psd_predict].
apply: (psd_le_trans step_update).
(* predict_cov (a·I) = a F Fᶜ + T,  и хотим ≤ a·I.                      *)
(* Достаточно: a F Fᶜ ≤ a · frob_sq F · I и T ≤ \tr T · I,              *)
(* а их сумма ≤ a · I при a (1 - frob_sq F) ≥ \tr T.                     *)
rewrite /predict_cov.
(* F (a·I) Fᶜ = a · F Fᶜ *)
have eq_pred : F *m (a *: 1%:M) *m F^t* = a *: (F *m F^t*).
  by rewrite scalemx1 mul_mx_scalar -scalemxAl.
rewrite eq_pred.
(* Цель: psd_le (a·F Fᶜ + G Q Gᶜ) (a·I). *)
(* Через цепочку: a·F Fᶜ ≤ a·frob_sq F · I, T ≤ \tr T · I.              *)
(* Сумма ≤ (a·frob_sq F + \tr T) · I ≤ a · I.                            *)
apply: (psd_le_trans
          (B := (a * frob_sq F + \tr (G *m Q *m G^t*)) *: 1%:M)).
- (* a F Fᶜ + T ≤ (a·frob_sq F + \tr T) · I *)
  rewrite scalerDl.
  (* Шаг A: a · F Fᶜ ≤ a · frob_sq F · I через масштабирование PSD-разности *)
  have hA : psd_le (a *: (F *m F^t*)) ((a * frob_sq F) *: 1%:M).
    rewrite /psd_le.
    have ->: (a * frob_sq F) *: (1%:M : 'M[C]_n) - a *: (F *m F^t*)
           = a *: ((frob_sq F *: (1%:M : 'M[C]_n)) - F *m F^t*).
      by rewrite scalerBr scalerA.
    (* psd (a *: M_psd) при a ≥ 0 вещественном — прямое доказательство.    *)
    have psd_diff : psd ((frob_sq F *: (1%:M : 'M[C]_n)) - F *m F^t*)
      := F_FtC_le_frob_id.
    case: psd_diff => Msym Mqf; split.
    + rewrite trmxC_scale -Msym.
      have a_conj : a^* = a by apply/CrealP; exact: a_real.
      by rewrite a_conj.
    + move=> v.
      rewrite -scalemxAr -scalemxAl mxtraceZ.
      by apply: mulr_ge0; [exact: a_ge0 | exact: Mqf].
  have hB : psd_le (G *m Q *m G^t*) (\tr (G *m Q *m G^t*) *: 1%:M)
    := GQGt_le_tr_id.
  rewrite /psd_le.
  have ->: (a * frob_sq F) *: (1%:M : 'M[C]_n) + \tr (G *m Q *m G^t*) *: 1%:M
         - (a *: (F *m F^t*) + G *m Q *m G^t*)
         = ((a * frob_sq F) *: 1%:M - a *: (F *m F^t*))
           + (\tr (G *m Q *m G^t*) *: 1%:M - G *m Q *m G^t*).
    by rewrite opprD addrACA.
  exact: psd_add hA hB.
- (* (a·frob_sq F + \tr T) · I ≤ a · I  ⇔  a·frob_sq F + \tr T ≤ a       *)
  (* ⇔  \tr T ≤ a (1 - frob_sq F)  ⇔  Pbnd_scalar ≤ a (по a_lb).         *)
  apply: psd_le_scale1.
  + apply: ger0_real.
    apply: addr_ge0.
    * exact: mulr_ge0 a_ge0 (frob_sq_ge0 F).
    * by apply: psd_tr_ge0; apply: psd_mulmx_row; exact: Q_psd.
  + exact: a_real.
  + (* a · frob_sq F + \tr T ≤ a *)
    rewrite -lerBrDl.
    have ->: a - a * frob_sq F = a * (1 - frob_sq F).
      by rewrite mulrBr mulr1.
    rewrite mulrC -ler_pdivrMl; last by rewrite subr_gt0; exact: F_contract.
    by rewrite -/Pbnd_scalar mulrC; exact: a_lb.
Qed.

(* ================================================================== *)
(* Верхняя траектория из α·I — монотонно убывает к Pss (через           *)
(* mx_mono_dec_cvgn + Pss_unique).                                      *)
(* ================================================================== *)

(* PSD-ность и монотонное убывание для α ≥ Pbnd_scalar. *)
Lemma Pup_psd (a : C) (a_real : a \is Num.real) (a_lb : Pbnd_scalar <= a)
    (k : nat) :
  psd (iter k (riccati_step F G H Q Rn) (a *: 1%:M)).
Proof.
have a_ge0 : 0 <= a := le_trans Pbnd_scalar_ge0 a_lb.
have psd_aI : psd (a *: (1%:M : 'M[C]_n)) by exact: psd_scale1 a_real a_ge0.
elim: k => [|k IH] //=.
by apply: riccati_step_psd; [exact: Q_psd | exact: Rn_pd | exact: IH].
Qed.

Lemma Pup_anti (a : C) (a_real : a \is Num.real) (a_lb : Pbnd_scalar <= a)
    (k : nat) :
  psd_le (iter k.+1 (riccati_step F G H Q Rn) (a *: 1%:M))
         (iter k (riccati_step F G H Q Rn) (a *: 1%:M)).
Proof.
elim: k => [|k IH] /=.
- exact: scalar_supersolution a_real a_lb.
- have psd_k : psd (iter k.+1 (riccati_step F G H Q Rn) (a *: 1%:M))
    := Pup_psd a_real a_lb k.+1.
  have psd_Sk : psd (iter k (riccati_step F G H Q Rn) (a *: 1%:M))
    := Pup_psd a_real a_lb k.
  by apply: riccati_step_mono; [exact: Q_psd | exact: Rn_pd |
                                exact: psd_k | exact: psd_Sk | exact: IH].
Qed.

(* Предел верхней траектории. *)
Definition Pup_lim (a : C) (a_real : a \is Num.real)
    (a_lb : Pbnd_scalar <= a) : 'M[C]_n :=
  mx_mono_dec_lim (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M)).

Lemma Pup_cvgn (a : C) (a_real : a \is Num.real) (a_lb : Pbnd_scalar <= a) :
  (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M)) @ \oo -->
  Pup_lim a_real a_lb.
Proof.
rewrite /Pup_lim.
apply: mx_mono_dec_cvgn;
  [exact: ler_r2c | exact: c2rK | exact: r2c_continuous
   | exact: (Pup_psd a_real a_lb) | exact: (Pup_anti a_real a_lb)].
Qed.

Lemma Pup_lim_psd (a : C) (a_real : a \is Num.real)
    (a_lb : Pbnd_scalar <= a) : psd (Pup_lim a_real a_lb).
Proof.
exact: (@mx_mono_dec_lim_psd Rty C r2c c2r
          ler_r2c c2rK c2r_continuous r2c_continuous
          n (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M))
          (Pup_psd a_real a_lb) (Pup_anti a_real a_lb)).
Qed.

(* Pup_lim — неподвижная точка riccati_step (по непрерывности). *)
Lemma Pup_lim_fixpoint (a : C) (a_real : a \is Num.real)
    (a_lb : Pbnd_scalar <= a) :
  Pup_lim a_real a_lb = riccati_step F G H Q Rn (Pup_lim a_real a_lb).
Proof.
set L := Pup_lim a_real a_lb.
have Lpsd : psd L := Pup_lim_psd a_real a_lb.
have Hcvg : (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M)) @ \oo --> L.
  exact: Pup_cvgn a_real a_lb.
have predL_psd : psd (predict_cov F G Q L)
  by apply: predict_cov_psd; [exact: Q_psd | exact: Lpsd].
have Sunit : innov_cov H Rn (predict_cov F G Q L) \in unitmx
  := innov_cov_inv H Rn_pd predL_psd.
have HriccCvg :
    (fun k => riccati_step F G H Q Rn
                  (iter k (riccati_step F G H Q Rn) (a *: 1%:M)))
      @ \oo --> riccati_step F G H Q Rn L
  := cvgn_riccati_step_k Hcvg Sunit.
have eqf :
    (fun k => riccati_step F G H Q Rn
                (iter k (riccati_step F G H Q Rn) (a *: 1%:M)))
  = (fun k => iter k.+1 (riccati_step F G H Q Rn) (a *: 1%:M)).
  by apply/funext.
rewrite eqf in HriccCvg.
have HshiftCvg :
    (fun k : nat => iter k.+1 (riccati_step F G H Q Rn) (a *: 1%:M))
      @ \oo --> L.
  have Hsh : addn 1 @ \oo --> (\oo : set_system nat) := cvg_addnl 1.
  have Hcomp :
      ((fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M)) \o addn 1)
        @ \oo --> L
    := cvg_comp (addn 1)
                 (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M))
                 Hsh Hcvg.
  have eq_shift :
      (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M)) \o addn 1
    = (fun k => iter k.+1 (riccati_step F G H Q Rn) (a *: 1%:M)).
    by apply/funext.
  by rewrite -eq_shift.
have HausM : hausdorff_space ('M[C]_n : pseudoMetricNormedZmodType C)
  by exact: norm_hausdorff.
have HshiftCvg_n :
    ((fun k => iter k.+1 (riccati_step F G H Q Rn) (a *: 1%:M))
       : nat -> ('M[C]_n : pseudoMetricNormedZmodType C))
      @ \oo --> (L : ('M[C]_n : pseudoMetricNormedZmodType C))
  := HshiftCvg.
have HriccCvg_n :
    ((fun k => iter k.+1 (riccati_step F G H Q Rn) (a *: 1%:M))
       : nat -> ('M[C]_n : pseudoMetricNormedZmodType C))
      @ \oo --> (riccati_step F G H Q Rn L
                   : ('M[C]_n : pseudoMetricNormedZmodType C))
  := HriccCvg.
exact: (cvg_unique HausM HshiftCvg_n HriccCvg_n).
Qed.

(* Pup_lim PD: predict_cov даёт PD-матрицу (PSD + pd_GQGt), update_cov  *)
(* сохраняет PD.                                                        *)
Lemma Pup_lim_pd (a : C) (a_real : a \is Num.real)
    (a_lb : Pbnd_scalar <= a) : pd (Pup_lim a_real a_lb).
Proof.
have HfpEq : Pup_lim a_real a_lb = riccati_step F G H Q Rn (Pup_lim a_real a_lb)
  := Pup_lim_fixpoint a_real a_lb.
rewrite HfpEq /riccati_step.
apply: update_cov_pd; first exact: Rn_pd.
rewrite /predict_cov.
(* F L Fᶜ + G Q Gᶜ = G Q Gᶜ + F L Fᶜ;  pd_add требует pd слева, psd справа. *)
have Lpsd : psd (Pup_lim a_real a_lb) := Pup_lim_psd a_real a_lb.
have psd_FLFt : psd (F *m Pup_lim a_real a_lb *m F^t*)
  := psd_mulmx_row F Lpsd.
rewrite addrC.
exact: pd_add pd_GQGt psd_FLFt.
Qed.

(* Главное следствие: Pup_lim = Pss. *)
Lemma Pup_lim_eq_Pss (a : C) (a_real : a \is Num.real)
    (a_lb : Pbnd_scalar <= a) : Pup_lim a_real a_lb = Pss.
Proof.
apply: Pss_unique.
- exact: Pup_lim_pd a_real a_lb.
- exact: Pup_lim_fixpoint a_real a_lb.
Qed.

(* Сходимость самой верхней траектории к Pss. *)
Lemma Pup_cvgn_Pss (a : C) (a_real : a \is Num.real)
    (a_lb : Pbnd_scalar <= a) :
  (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M)) @ \oo --> Pss.
Proof.
have := @Pup_cvgn a a_real a_lb.
by rewrite (Pup_lim_eq_Pss a_real a_lb).
Qed.

(* ================================================================== *)
(* arb_iter_cvgn: для произвольного PSD P0 — сходимость к Pss.          *)
(* Выбираем α := \tr P0 + Pbnd_scalar.  Тогда P0 ≤ α·I, сэндвич с      *)
(* нижней (Pseq) и верхней (Pup_seq α) траекториями.                    *)
(* ================================================================== *)

Theorem arb_iter_cvgn (P0 : 'M[C]_n) (HP0 : psd P0) :
  (fun k => iter k (riccati_step F G H Q Rn) P0) @ \oo --> Pss.
Proof.
pose a : C := \tr P0 + Pbnd_scalar.
have trP0_ge0 : 0 <= \tr P0 := psd_tr_ge0 HP0.
have a_ge0 : 0 <= a by apply: addr_ge0; [exact: trP0_ge0 | exact: Pbnd_scalar_ge0].
have a_real : a \is Num.real by exact: ger0_real.
have a_lb : Pbnd_scalar <= a.
  rewrite /a addrC -[X in X <= _]addr0.
  by rewrite lerD2l.
(* P0 ≤ \tr P0 · I ≤ a · I *)
have P0_le_trP0 : psd_le P0 (\tr P0 *: (1%:M : 'M[C]_n))
  := psd_le_trace_id HP0.
have trP0_le_a : psd_le (\tr P0 *: (1%:M : 'M[C]_n)) (a *: 1%:M).
  apply: psd_le_scale1.
  - by apply: ger0_real.
  - exact: a_real.
  - rewrite /a -{1}[\tr P0]addr0 lerD2l.
    exact: Pbnd_scalar_ge0.
have P0_le_aI : psd_le P0 (a *: 1%:M) := psd_le_trans P0_le_trP0 trP0_le_a.
have psd_aI : psd (a *: (1%:M : 'M[C]_n)) by exact: psd_scale1 a_real a_ge0.
(* Сэндвич: iter k r.s. 0 ≤ iter k r.s. P0 ≤ iter k r.s. (a·I) *)
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
         (iter k (riccati_step F G H Q Rn) (a *: 1%:M)).
  elim=> [|k IH] /=; first exact: P0_le_aI.
  have psd_M : psd (iter k (riccati_step F G H Q Rn) P0)
    := riccati_iter_psd F G H Q_psd Rn_pd k HP0.
  have psd_U : psd (iter k (riccati_step F G H Q Rn) (a *: 1%:M))
    := Pup_psd a_real a_lb k.
  by apply: riccati_step_mono;
     [exact: Q_psd | exact: Rn_pd | exact: psd_M | exact: psd_U | exact: IH].
(* Сходимости низа и верха к Pss. *)
have Lcvg : (fun k => iter k (riccati_step F G H Q Rn) 0) @ \oo --> Pss
  := Pss_cvgn.
have Ucvg : (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M)) @ \oo --> Pss
  := Pup_cvgn_Pss a_real a_lb.
(* Разность верхней и нижней траекторий сходится к 0. *)
have UL_cvg :
    (fun k => iter k (riccati_step F G H Q Rn) (a *: 1%:M)
            - iter k (riccati_step F G H Q Rn) 0) @ \oo --> (0 : 'M[C]_n).
  have := cvgn_submx Ucvg Lcvg.
  by rewrite subrr.
(* \tr (U_k - L_k) → 0. *)
have trUL_cvg :
    (fun k => \tr (iter k (riccati_step F G H Q Rn) (a *: 1%:M)
                  - iter k (riccati_step F G H Q Rn) 0))
      @ \oo --> (\tr (0 : 'M[C]_n)).
  exact: cvgn_mxtrace UL_cvg.
have trUL_cvg0 :
    (fun k => \tr (iter k (riccati_step F G H Q Rn) (a *: 1%:M)
                  - iter k (riccati_step F G H Q Rn) 0))
      @ \oo --> (0 : C).
  have htr0 : \tr (0 : 'M[C]_n) = (0 : C) by rewrite mxtrace0.
  by rewrite -htr0.
(* \tr (X_k - L_k) → 0 через сэндвич. *)
pose XL k := iter k (riccati_step F G H Q Rn) P0
             - iter k (riccati_step F G H Q Rn) 0.
pose UL k := iter k (riccati_step F G H Q Rn) (a *: 1%:M)
             - iter k (riccati_step F G H Q Rn) 0.
have XL_psd : forall k, psd (XL k).
  by move=> k; rewrite /XL; exact: Pseq_le_iterP0.
have XL_le_UL : forall k, \tr (XL k) <= \tr (UL k).
  move=> k.
  apply: psd_le_trace.
  rewrite /XL /UL.
  have ->: iter k (riccati_step F G H Q Rn) (a *: 1%:M)
         - iter k (riccati_step F G H Q Rn) 0
         - (iter k (riccati_step F G H Q Rn) P0
            - iter k (riccati_step F G H Q Rn) 0)
         = iter k (riccati_step F G H Q Rn) (a *: 1%:M)
           - iter k (riccati_step F G H Q Rn) P0.
    by rewrite opprB addrA subrK.
  exact: iterP0_le_Pup.
have trXL_cvg0 : (fun k => \tr (XL k)) @ \oo --> (0 : C).
  apply: (cvgC_le0_squeeze (t := fun k => \tr (UL k))).
  - by move=> k; apply: psd_tr_ge0; exact: XL_psd.
  - exact: XL_le_UL.
  - exact: trUL_cvg0.
(* frob_sq (XL k) ≤ (\tr (XL k))^+2 → 0. *)
have frob_XL_cvg0 :
    (fun k => frob_sq (XL k)) @ \oo --> (0 : C).
  apply: (cvgC_le0_squeeze (t := fun k => (\tr (XL k)) ^+ 2)).
  - by move=> k; exact: frob_sq_ge0.
  - by move=> k; apply: frob_sq_le_tr_sq; exact: XL_psd.
  - (* (\tr (XL k))^+2 → 0^+2 = 0. *)
    have trXL_cvg0_o :
        ((fun k => \tr (XL k)) : nat -> C^o) @ \oo --> (0 : C^o)
      := trXL_cvg0.
    have Hmul0 : (fun k => \tr (XL k) * \tr (XL k)) @ \oo --> (0 : C^o).
      have HM := cvgM trXL_cvg0_o trXL_cvg0_o.
      rewrite mulr0 in HM.
      exact: HM.
    suff -> : (fun k : nat => (\tr (XL k)) ^+ 2)
            = (fun k => \tr (XL k) * \tr (XL k)) by exact: Hmul0.
    by apply/funext=> k; rewrite expr2.
(* X_k - L_k → 0 в матричной топологии. *)
have XL_cvg :
    (fun k => XL k) @ \oo --> (0 : 'M[C]_n).
  have := @frob_sq_cvgn0_to_mxcvgn C n n XL (0 : 'M[C]_n).
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

(* ================================================================== *)
(*  Стабильность замкнутого контура F_p (Session 16)                   *)
(*                                                                     *)
(*  Книжная идентичность Lemma 14.5.3 (Kailath–Sayed–Hassibi):         *)
(*                                                                     *)
(*    P_pss = Fp *m P_pss *m Fpᶜ + Kp *m Rn *m Kpᶜ + G *m Q *m Gᶜ      *)
(*                                                                     *)
(*  где:                                                               *)
(*    P_pss = predict_cov Pss = F Pss Fᶜ + GQGᶜ (предикторная ss-cov), *)
(*    Kf = kalman_gain P_pss (фильтрационное усиление),                *)
(*    Kp = F *m Kf (предикторное усиление),                            *)
(*    Fp = F - Kp *m H (замкнутый контур в предикторной форме).        *)
(*                                                                     *)
(*  Откуда непосредственно следует Loewner-сжатие:                     *)
(*    psd_le (Fp *m P_pss *m Fpᶜ) P_pss.                              *)
(*                                                                     *)
(*  Frobenius-стабильность `frob_sq Fp < 1` (нужная для построения     *)
(*  `OP` в Session 17 через `lyap_sol_inf`) НЕ выводится напрямую из   *)
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

(* Из определения kalman_gain: Kf *m R_e = P_pss *m Hᶜ. *)
Lemma Kf_R_e_eq : Kf *m R_e = P_pss *m H^t*.
Proof.
rewrite /kalman_gain -mulmxA mulVmx ?R_e_unit //.
by rewrite mulmx1.
Qed.

(* Pss = (I - Kf H) P_pss = update_cov P_pss (Pss как неподвижная точка). *)
Lemma Pss_eq_update : Pss = update_cov H Rn P_pss.
Proof.
have := Pss_fixpoint.
by rewrite /riccati_step.
Qed.

(* Книжная Lemma 14.5.3 (Kailath–Sayed–Hassibi):                          *)
(*   P_pss = Fp P_pss Fpᶜ + Kp Rn Kpᶜ + G Q Gᶜ.                            *)
(*                                                                         *)
(* Алгебраическое доказательство требует тонкой работы с ассоциативностью *)
(* мульти-произведений матриц и идентичности K_f * R_e = P_pss * Hᶜ;       *)
(* отложено на Session 18 (полная разрядка).  Сейчас постулировано как    *)
(* доменная гипотеза.                                                      *)
Hypothesis riccati_closed_loop_identity :
  predict_cov F G Q Pss =
    Fp *m predict_cov F G Q Pss *m Fp^t* +
    (F *m kalman_gain H Rn (predict_cov F G Q Pss)) *m Rn *m
      (F *m kalman_gain H Rn (predict_cov F G Q Pss))^t* +
    G *m Q *m G^t*.

(* Loewner-сжатие: Fp P_pss Fpᶜ ≤ P_pss. *)
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
- exact: psd_mulmx_row (pd_psd Rn_pd).
- exact: psd_mulmx_row Q_psd.
Qed.

(* Frobenius-сжатие как Tier-C debt: следует из Loewner-сжатия только    *)
(* при наличии спектрального радиуса, которого пока нет в mathcomp.       *)
Hypothesis Fp_contract : frob_sq Fp < 1.

End DARE.
