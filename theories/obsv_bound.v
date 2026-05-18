(*  Грамианы наблюдаемости и управляемости.                                *)
(*                                                                          *)
(*  В этом файле:                                                           *)
(*    * `obsv_gram k := \sum_{j<k} (F^j)^t* H^t* invR H F^j`                 *)
(*      (information-weighted observability Gramian).                       *)
(*    * `ctrl_gram k := \sum_{j<k} F^j G Q G^t* (F^j)^t*`                    *)
(*      (state-controllability Gramian).                                    *)
(*                                                                          *)
(*  Основные результаты:                                                    *)
(*    * `obsv_gram_psd`, `ctrl_gram_psd` — безусловная PSD-ность.           *)
(*    * `obsv_gram_pd_of_observable` — при наблюдаемости `obsv_gram n` PD.  *)
(*    * `ctrl_gram_pd_of_controllable` — при управляемости + `pd Q`         *)
(*      `ctrl_gram n` PD.                                                   *)
(*    * `riccati_iter_le_ctrl_gram` — верхняя оценка                        *)
(*        iter k riccati_step 0  ≤  ctrl_gram k                             *)
(*      (доказывается через стратегию K=0: применяя `update_cov_le`         *)
(*      и `predict_cov_mono` индуктивно, плюс тождество сдвига              *)
(*      `ctrl_gram_shift`:                                                  *)
(*        ctrl_gram (k+1) = G Q G^t* + F (ctrl_gram k) F^t* .               *)
(*                                                                          *)
(*  Замечание. Стандартная "равномерная" верхняя оценка                     *)
(*    iter k riccati_step 0  ≤  invmx (obsv_gram n)   при k ≥ n             *)
(*  (Kailath §14.5, через информационную форму P_k^{-1} ≥ obsv_gram k)      *)
(*  здесь НЕ доказана: она требует тождества Вудбери / явного               *)
(*  выражения `invmx (predict_cov P)` через `invmx P` и `invmx Q`,          *)
(*  что выходит за рамки этой сессии.  Бутстрэп K=0-оценки выше              *)
(*  даёт ослабленный (зависящий от `F`) бенчмарк, достаточный                *)
(*  для построения предельного `Pss` при дополнительной                      *)
(*  гипотезе устойчивости (Session 7).                                       *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import psd_base psd_order spectral kalman riccati_mono.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section ObsvBound.
Variable (C : numClosedFieldType).
Variables (m n p : nat).
Variables (F : 'M[C]_n) (G : 'M[C]_(n, m)) (H : 'M[C]_(p, n)).
Variables (Q : 'M[C]_m) (R : 'M[C]_p).
Hypothesis Q_psd : psd Q.
Hypothesis R_pd  : pd R.

(* ================================================================== *)
(*  Грамиан наблюдаемости                                              *)
(* ================================================================== *)

Definition obsv_gram (k : nat) : 'M[C]_n :=
  \sum_(j < k) (F^+j)^t* *m H^t* *m invmx R *m H *m (F^+j).

Lemma obsv_gram0 : obsv_gram 0 = 0.
Proof. by rewrite /obsv_gram big_ord0. Qed.

Lemma obsv_gram_recr k :
  obsv_gram k.+1 =
    obsv_gram k +
    (F^+k)^t* *m H^t* *m invmx R *m H *m (F^+k).
Proof. by rewrite /obsv_gram big_ord_recr. Qed.

Lemma obsv_gram_term_psd (j : nat) :
  psd ((F^+j)^t* *m H^t* *m invmx R *m H *m (F^+j)).
Proof.
have invR_psd : psd (invmx R) := pd_psd (pd_inv R_pd).
have -> :
  (F^+j)^t* *m H^t* *m invmx R *m H *m (F^+j) =
  (H *m F^+j)^t* *m invmx R *m (H *m F^+j).
  by rewrite trmxC_mul -!mulmxA.
exact: psd_congruence invR_psd.
Qed.

Lemma obsv_gram_psd k : psd (obsv_gram k).
Proof.
elim: k => [|k IH].
  by rewrite obsv_gram0; exact: psd0.
by rewrite obsv_gram_recr; exact: psd_add IH (obsv_gram_term_psd k).
Qed.

(* Квадратичная форма обсв. грамиана в точке v *)
Lemma obsv_gram_qform k (v : 'cV[C]_n) :
  \tr (v^t* *m obsv_gram k *m v) =
  \sum_(j < k) \tr ((H *m F^+j *m v)^t* *m invmx R *m (H *m F^+j *m v)).
Proof.
elim: k => [|k IH].
  by rewrite obsv_gram0 mulmx0 mul0mx mxtrace0 big_ord0.
rewrite obsv_gram_recr big_ord_recr /=.
rewrite mulmxDr mulmxDl mxtraceD IH.
congr (_ + _).
by rewrite !trmxC_mul -!mulmxA.
Qed.

(* Основной результат: при наблюдаемости `obsv_gram n` PD. *)
Lemma obsv_gram_pd_of_observable :
  observable F H -> pd (obsv_gram n).
Proof.
move=> Hobs.
have herm := (obsv_gram_psd n).1.
have invR_pd : pd (invmx R) := pd_inv R_pd.
have psd_invR : psd (invmx R) := pd_psd invR_pd.
split=> //.
move=> v vNZ.
rewrite obsv_gram_qform.
(* каждый член ≥ 0 *)
have term_ge0 : forall j : 'I_n,
  0 <= \tr ((H *m F^+j *m v)^t* *m invmx R *m (H *m F^+j *m v)).
  move=> j; apply: psd_tr_ge0.
  exact: psd_congruence psd_invR.
(* по наблюдаемости: ∃ j : 'I_n, H *m F^+j *m v != 0 *)
have [j0 Hj0] : exists j : 'I_n, H *m F^+j *m v != 0.
  case: (boolP [forall j : 'I_n, H *m F^+j *m v == 0]) => [/forallP Hall|HnotAll].
  - exfalso; apply: (negP vNZ); apply/eqP; apply: Hobs => i.
    by rewrite /obsv_block; apply/eqP; exact: Hall i.
  - rewrite negb_forall in HnotAll.
    move/existsP: HnotAll => [j0 Hj0].
    by exists j0.
(* j0-й член строго положителен *)
have term_gt0 :
  0 < \tr ((H *m F^+j0 *m v)^t* *m invmx R *m (H *m F^+j0 *m v)).
  by case: invR_pd => _ hp; apply: hp; exact: Hj0.
rewrite (bigD1 j0) //=.
apply: ltr_wpDr; last exact: term_gt0.
by apply: sumr_ge0 => i _; exact: term_ge0.
Qed.

(* ================================================================== *)
(*  Грамиан управляемости                                              *)
(* ================================================================== *)

Definition ctrl_gram (k : nat) : 'M[C]_n :=
  \sum_(j < k) F^+j *m G *m Q *m G^t* *m (F^+j)^t*.

Lemma ctrl_gram0 : ctrl_gram 0 = 0.
Proof. by rewrite /ctrl_gram big_ord0. Qed.

Lemma ctrl_gram_recr k :
  ctrl_gram k.+1 =
    ctrl_gram k + F^+k *m G *m Q *m G^t* *m (F^+k)^t*.
Proof. by rewrite /ctrl_gram big_ord_recr. Qed.

Lemma ctrl_gram_term_psd (j : nat) :
  psd (F^+j *m G *m Q *m G^t* *m (F^+j)^t*).
Proof.
have -> :
  F^+j *m G *m Q *m G^t* *m (F^+j)^t* =
  (F^+j *m G) *m Q *m (F^+j *m G)^t*.
  by rewrite trmxC_mul !mulmxA.
exact: psd_mulmx_row Q_psd.
Qed.

Lemma ctrl_gram_psd k : psd (ctrl_gram k).
Proof.
elim: k => [|k IH].
  by rewrite ctrl_gram0; exact: psd0.
by rewrite ctrl_gram_recr; exact: psd_add IH (ctrl_gram_term_psd k).
Qed.

(* Квадратичная форма управ. грамиана в точке v *)
Lemma ctrl_gram_qform k (v : 'cV[C]_n) :
  \tr (v^t* *m ctrl_gram k *m v) =
  \sum_(j < k) \tr ((G^t* *m (F^+j)^t* *m v)^t* *m Q *m
                    (G^t* *m (F^+j)^t* *m v)).
Proof.
elim: k => [|k IH].
  by rewrite ctrl_gram0 mulmx0 mul0mx mxtrace0 big_ord0.
rewrite ctrl_gram_recr big_ord_recr /=.
rewrite mulmxDr mulmxDl mxtraceD IH.
congr (_ + _).
by rewrite !trmxC_mul !trmxCK -!mulmxA.
Qed.

(* PD-ность при управляемости + pd Q *)
Lemma ctrl_gram_pd_of_controllable :
  controllable F G -> pd Q -> pd (ctrl_gram n).
Proof.
move=> Hctrl Q_pd.
have herm := (ctrl_gram_psd n).1.
split=> //.
move=> v vNZ.
rewrite ctrl_gram_qform.
have term_ge0 : forall j : 'I_n,
  0 <= \tr ((G^t* *m (F^+j)^t* *m v)^t* *m Q *m (G^t* *m (F^+j)^t* *m v)).
  move=> j; apply: psd_tr_ge0.
  exact: psd_congruence Q_psd.
(* по управляемости: ∃ j, G^t* (F^j)^t* v != 0 *)
have [j0 Hj0] : exists j : 'I_n, G^t* *m (F^+j)^t* *m v != 0.
  case: (boolP [forall j : 'I_n, G^t* *m (F^+j)^t* *m v == 0])
       => [/forallP Hall|HnotAll].
  - exfalso.
    have vT_zero : v^t* = 0.
      apply: Hctrl => i.
      rewrite /ctrl_block.
      have /eqP eq := Hall i.
      have eqT := congr1 (fun M : 'M[C]_(m, 1) => M^t*) eq.
      rewrite trmxC0 in eqT.
      rewrite !trmxC_mul !trmxCK in eqT.
      exact: eqT.
    apply: (negP vNZ); apply/eqP.
    have := congr1 (fun M : 'M[C]_(1, n) => M^t*) vT_zero.
    by rewrite trmxC0 trmxCK.
  - rewrite negb_forall in HnotAll.
    move/existsP: HnotAll => [j0 Hj0].
    by exists j0.
have term_gt0 :
  0 < \tr ((G^t* *m (F^+j0)^t* *m v)^t* *m Q *m (G^t* *m (F^+j0)^t* *m v)).
  by case: Q_pd => _ hp; apply: hp; exact: Hj0.
rewrite (bigD1 j0) //=.
apply: ltr_wpDr; last exact: term_gt0.
by apply: sumr_ge0 => i _; exact: term_ge0.
Qed.

(* ================================================================== *)
(*  Тождество сдвига для управ. грамиана.                              *)
(*                                                                     *)
(*  ctrl_gram (k+1) = G Q G^t* + F (ctrl_gram k) F^t*                  *)
(*                                                                     *)
(*  Доказывается индукцией по k (избегая работы с `lift ord0 i`).      *)
(* ================================================================== *)

Lemma ctrl_gram_shift k :
  ctrl_gram k.+1 = G *m Q *m G^t* + F *m ctrl_gram k *m F^t*.
Proof.
elim: k => [|k IH].
  rewrite ctrl_gram_recr ctrl_gram0 add0r.
  rewrite expr0 mul1mx trmxC1 mulmx1.
  by rewrite mulmx0 mul0mx addr0.
rewrite ctrl_gram_recr {1}IH.
rewrite ctrl_gram_recr.
rewrite mulmxDr mulmxDl.
rewrite -addrA.
congr (_ + _).
congr (_ + _).
rewrite exprS trmxC_mul.
by rewrite !mulmxA.
Qed.

(* ================================================================== *)
(*  Верхняя оценка итерации Риккати через стратегию K=0.               *)
(*                                                                     *)
(*  Идея.  Для оптимальной (Калмановской) оценки                       *)
(*      update_cov P_pred  ≤  P_pred                                   *)
(*  (это `update_cov_le`).  Следовательно                              *)
(*      riccati_step P  ≤  predict_cov P                               *)
(*                      ≤  predict_cov (ctrl_gram k)         (IH)      *)
(*                      =  G Q G^t* + F (ctrl_gram k) F^t*             *)
(*                      =  ctrl_gram (k+1)        (тождество сдвига).  *)
(* ================================================================== *)

Lemma riccati_iter_le_ctrl_gram (k : nat) :
  psd_le (iter k (riccati_step F G H Q R) 0) (ctrl_gram k).
Proof.
elim: k => [|k IH].
  rewrite /= ctrl_gram0.
  apply: psd_le_refl; exact: psd0.
rewrite [iter k.+1 _ _]/=.
set Pk := iter k _ _.
have Pk_psd : psd Pk := riccati_iter_from_0_psd F G H Q_psd R_pd k.
have Ppred_psd : psd (predict_cov F G Q Pk) := predict_cov_psd F G Q_psd Pk_psd.
(* step1: riccati_step Pk ≤ predict_cov Pk *)
have step1 : psd_le (riccati_step F G H Q R Pk) (predict_cov F G Q Pk).
  rewrite /psd_le /riccati_step.
  apply: (update_cov_le H R_pd Ppred_psd).
(* step2: predict_cov Pk ≤ predict_cov (ctrl_gram k) *)
have step2 : psd_le (predict_cov F G Q Pk) (predict_cov F G Q (ctrl_gram k)).
  apply: (predict_cov_mono F G Q IH).
(* step3: predict_cov (ctrl_gram k) = ctrl_gram k.+1 *)
have step3 : predict_cov F G Q (ctrl_gram k) = ctrl_gram k.+1.
  by rewrite /predict_cov ctrl_gram_shift addrC.
rewrite -step3.
exact: psd_le_trans step1 step2.
Qed.

End ObsvBound.
