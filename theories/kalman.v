(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From mathcomp.algebra Require Import sesquilinear spectral.
From infotheo.probability Require Import fdist.
From Kalman Require Import mxnotation mxherm mxdefinite mxloewner spectral expectation.
From Kalman Require Export riccati_def.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Num.Def.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section KalmanFilter.

  Variable (ℂ : numClosedFieldType).
  Variables (m n p : nat).
  (* Конечное вероятностное пространство шумов; см. expectation.v и noise.v. *)
  Variable (Ω : finType) (μ : fdist ℂ Ω).
  Variable F : 'M[ℂ]_n.      (* Матрица перехода состояний *)
  Variable G : 'M[ℂ]_(n, m). (* Матрица управляющего воздействия *)
  Variable H : 'M[ℂ]_(p, n). (* Матрица наблюдения *)
  Variable Q : 'M[ℂ]_m.      (* Ковариация шума управления *)
  Variable R : 'M[ℂ]_p.      (* Ковариация шума измерения *)

  (* Общие предположения о ковариациях шума *)
  Hypothesis Q_psd : psd Q.
  Hypothesis R_pd : pd R.

  Variable x0 : 'cV[ℂ]_n.

  Variable w : nat -> Ω -> 'cV[ℂ]_m. (* Шум управления *)
  Variable v : nat -> Ω -> 'cV[ℂ]_p. (* Шум измерения *)

  (*
    Шаг построения новой оценки состояния.

    $hat(x)_(k+1|k) = F hat(x)_(k|k) + G u_k$.

    - @kailath2000[§ 9.3 "Recursions for Predicted and Filtered State Estimators"].
  *)
  Definition predict_state (x_prev : 'cV[ℂ]_n) (u : 'cV[ℂ]_m) : 'cV[ℂ]_n :=
    F *m x_prev + G *m u.

  (*
    Ковариация предсказания.

    $P_(k+1|k) := F P_(k|k) F† + G Q G†$.

    - @kailath2000[§ 9.3 "Recursions for Predicted and Filtered State Estimators"].
  *)
  Local Notation predict_cov := (riccati_def.predict_cov conjC F G Q).

  (*
    Эрмитовость предсказанной ковариации.

    Если предыдущая ковариация $P$ эрмитова, то и $"predict_cov" P$ эрмитова.

    - @kailath2000[§ 9.3 "Recursions for Predicted and Filtered State Estimators"].
  *)
  Lemma predict_cov_sym (P : 'M[ℂ]_n) :
    P = P^t* -> predict_cov P = (predict_cov P)^t*.
  Proof.
    move=> Psym.
    have hP : (F *m P *m F^t*)^t* = F *m P *m F^t*.
      by rewrite trmxC_mul trmxC_mul !trmxCK -mulmxA -Psym.
    have hQ : (G *m Q *m G^t*)^t* = G *m Q *m G^t*.
      by rewrite trmxC_mul trmxC_mul !trmxCK -mulmxA -Q_psd.1.
    rewrite !predict_covE trmxC_add hP hQ.
    done.
  Qed.

  (*
    Сохранение неотрицательной определённости шагом предсказания.

    Если $P succ.eq 0$, то $"predict_cov" P succ.eq 0$.

    - @kailath2000[§ 9.3 "Recursions for Predicted and Filtered State Estimators"].
  *)
  Lemma predict_cov_psd (P : 'M[ℂ]_n) :
    psd P -> psd (predict_cov P).
  Proof.
    move=> psdP.
    have h1 := psd_lcongr F psdP.
    have h2 := psd_lcongr G Q_psd.
    have hsum : psd (F *m P *m F^t* + G *m Q *m G^t*) := psd_add h1 h2.
    rewrite predict_covE.
    exact: hsum.
  Qed.

  (*
    Инновационная ковариация.

    $R_(e,k) = H P_(k|k-1) H† + R$.

    - @kailath2000[§ 9.2, Theorem 9.2.1 "Innovations"].
  *)
  Local Notation innov_cov := (riccati_def.innov_cov conjC H R).

  (*
    Усиление Калмана.

    $K_k = P_(k|k-1) H† R_(e,k)^(-1)$. Это фильтрующее усиление
    $K = P H† R_e^(-1)$ (без множителя $F$), вводимое в шаге измерения; ср.
    предсказательное усиление $K_p = F P H† R_e^(-1)$ из теоремы 9.2.1.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Local Notation filter_gain := (riccati_def.filter_gain conjC H R).

  (*
    Обновление состояния.

    $hat(x)_(k|k) = hat(x)_(k|k-1) + K_k (y_k - H hat(x)_(k|k-1))$.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Definition update_state (P_pred : 'M[ℂ]_n)
      (x_pred : 'cV[ℂ]_n) (y : 'cV[ℂ]_p) : 'cV[ℂ]_n :=
    let K := filter_gain P_pred in
    x_pred + K *m (y - H *m x_pred).

  (*
    Обновление ковариации.

    $P_(k|k) = (E_n - K_k H) P_(k|k-1)$.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Local Notation update_cov := (riccati_def.update_cov conjC H R).

  (*
    Истинная траектория состояния.

    Случайный процесс $x_k$, заданный уравнением состояния
    $x_(k+1) = F x_k + G u_k + G w_(k+1)$ с начальным условием $x_0$.
  *)
  Definition x_true (u : nat -> 'cV[ℂ]_m) : nat -> Ω -> 'cV[ℂ]_n :=
    fix f k :=
      match k with
      | 0%N => fun _ => x0
      | k'.+1 => fun ω => F *m f k' ω + G *m u k' + G *m w k'.+1 ω
      end.

  (*
    Траектория апостериорных оценок состояния.

    На каждом шаге полушаг предсказания по динамике системы сменяется полушагом
    обновления по наблюдению $y_(k+1)$. Начальная оценка $hat(x)_(0|0) = 0$
    согласована с предположением о нулевом среднем начального состояния.
  *)
  Definition x_hat (u : nat -> 'cV[ℂ]_m) (y : nat -> Ω -> 'cV[ℂ]_p)
      (P_seq : nat -> 'M[ℂ]_n) : nat -> Ω -> 'cV[ℂ]_n :=
    fix f k :=
      match k with
      | 0%N => fun _ => 0  (* начальная оценка; предполагаем несмещённый старт *)
      | k'.+1 => fun ω =>
        let x_pred := predict_state (f k' ω) (u k') in
        let P_pred := predict_cov (P_seq k') in
        update_state P_pred x_pred (y k'.+1 ω)
      end.

  (*
    Ошибка оценивания.

    $tilde(x)_(k|k) = x_k - hat(x)_(k|k)$, разность истинного состояния и
    апостериорной оценки.
  *)
  Definition x_err u y Ps k : Ω -> 'cV[ℂ]_n :=
    fun ω => x_true u k ω - x_hat u y Ps k ω.

  (*
    Несмещённость.

    Математическое ожидание `Exp` определено в `expectation.v` формулой
    оператора `Ex` из infotheo над конечным распределением μ; линейность
    (Exp_add/Exp_scale/Exp_mulmx_l) и производные тождества там доказаны
    как леммы, а на вещественном поле оператор совпадает с `E из infotheo
    (лемма ExpE). Гипотезами остаются только содержательные вероятностные
    предположения о шумах: нулевое среднее на каждом шаге. Эти гипотезы
    выполнимы: в `noise.v` построена конкретная модель шумов
    (четырёхточечное распределение на равномерном пространстве траекторий
    исходов), для которой нулевые средние доказаны, а несмещённость для
    неё получается следствием `model_unbiased`.
  *)

  Local Notation 𝔼 := (Exp μ).

  Hypothesis Exp_w_zero : forall k, 𝔼 (w k) = 0.
  Hypothesis Exp_v_zero : forall k, 𝔼 (v k) = 0.

  (* Чисто абелева перегруппировка, используемая ниже. *)
  Lemma abelian_swap_cancel (M : zmodType) (a b c d e : M) :
    a + b + c - (d + b + e) = a - d + c - e.
  Proof.
    rewrite !opprD !addrA (addrAC _ _ (- b)) (addrAC _ c (- b)) addrK.
    by rewrite (addrAC _ c (- d)).
  Qed.

  (*
    Рекурсия для ошибки оценивания.

    Для измерения $y_j = H x_j + v_j$ ошибка удовлетворяет
    $tilde(x)_(k+1) = F tilde(x)_k + G w_(k+1) - K_k (H F tilde(x)_k + H G w_(k+1) + v_(k+1))$.

    - @kailath2000[§ 9.3 "Recursions for Predicted and Filtered State Estimators"].
  *)
  Lemma x_err_recursion u y Ps k ω :
    (forall j ω', y j ω' = H *m x_true u j ω' + v j ω') ->
    x_err u y Ps k.+1 ω =
      F *m x_err u y Ps k ω + G *m w k.+1 ω -
      filter_gain (predict_cov (Ps k)) *m
        (H *m F *m x_err u y Ps k ω + H *m G *m w k.+1 ω + v k.+1 ω).
  Proof.
    move=> Hzm.
    rewrite /x_err /= /update_state /predict_state.
    rewrite (Hzm k.+1 ω) /=.
    set Kk := filter_gain (predict_cov (Ps k)).
    set xt := x_true u k ω.
    set xh := x_hat u y Ps k ω.
    (*
      Внутреннее выражение:
      $ H "x_true"_(k+1) + v_(k+1) - H (F hat(x) + G u_k) = H F (x_t - hat(x)) + H G w_(k+1) + v_(k+1) $
    *)
    have inner :
      H *m (F *m xt + G *m u k + G *m w k.+1 ω) + v k.+1 ω -
        H *m (F *m xh + G *m u k) =
      H *m F *m (xt - xh) + H *m G *m w k.+1 ω + v k.+1 ω.
    { rewrite mulmxBr !mulmxDr !mulmxA addrAC opprD !addrA.
      rewrite (addrAC _ _ (- (H *m G *m u k))).
      rewrite (addrAC _ (H *m G *m w k.+1 ω)) addrK.
      by rewrite [X in X + _ = _]addrAC. }
    rewrite inner.
    (* Внешнее выражение *)
    by rewrite abelian_swap_cancel [in RHS]mulmxBr.
  Qed.

  (*
    Обращение в ноль математического ожидания инновации.

    Если $EE tilde(x)_k = 0$, то и
    $EE(H F tilde(x)_k + H G w_(k+1) + v_(k+1)) = 0$.

    - @kailath2000[§ 3.2.4 "Nonzero-Mean Values and Centering"].
  *)
  Lemma Exp_predict_innov_zero u y Ps k :
    𝔼 (x_err u y Ps k) = 0 ->
    𝔼 (fun ω => H *m F *m x_err u y Ps k ω
                + H *m G *m w k.+1 ω + v k.+1 ω) = 0.
  Proof.
    move=> H0.
    rewrite 2!Exp_add.
    rewrite (Exp_mulmx_l (H *m F)) H0 mulmx0 add0r.
    rewrite (Exp_mulmx_l (H *m G)) Exp_w_zero mulmx0.
    by rewrite !add0r (Exp_v_zero k.+1).
  Qed.

  (*
    Несмещённость оценки фильтра Калмана.

    При нулевом начальном среднем ошибки $EE tilde(x)_k = 0$ выполнено для всех
    $k$.

    - @kailath2000[§ 3.2.4 "Nonzero-Mean Values and Centering"].
  *)
  Theorem unbiased u y Ps :
    (forall j ω, y j ω = H *m x_true u j ω + v j ω) ->
    𝔼 (x_err u y Ps 0) = 0 ->
    forall k, 𝔼 (x_err u y Ps k) = 0.
  Proof.
    move=> Hzm E0; elim=> [//|k IH].
    have stepE : 𝔼 (x_err u y Ps k.+1) =
        𝔼 (fun ω => F *m x_err u y Ps k ω + G *m w k.+1 ω -
           filter_gain (predict_cov (Ps k)) *m
             (H *m F *m x_err u y Ps k ω + H *m G *m w k.+1 ω + v k.+1 ω)).
      by apply: eq_Exp => ω; exact: x_err_recursion.
    rewrite stepE Exp_sub Exp_add (Exp_mulmx_l F) IH mulmx0 add0r.
    rewrite (Exp_mulmx_l G) Exp_w_zero mulmx0 add0r.
    by rewrite (Exp_mulmx_l (filter_gain _)) (Exp_predict_innov_zero IH)
       mulmx0 oppr0.
  Qed.

  (*
    Положительная определённость инновационной ковариации.

    Если $P_(k|k-1) succ.eq 0$, то $"innov_cov" P_(k|k-1) succ 0$, откуда
    существует $R_(e,k)^(-1)$.

    - @kailath2000[§ 9.5 "An Important Special Assumption: R"].
  *)
  Lemma innov_cov_pd (P_pred : 'M[ℂ]_n) :
    psd P_pred -> pd (innov_cov P_pred).
  Proof.
    move=> psdP.
    have hpsd := psd_lcongr H psdP.
    split.
    - rewrite !innov_covE.
      rewrite trmxC_add.
      f_equal.
      * exact hpsd.1.
      * exact R_pd.1.
    - move=> z z0.
      have h1 : 0 <= \tr (z^t* *m (H *m P_pred *m H^t*) *m z) := hpsd.2 z.
      have h2 : 0 < \tr (z^t* *m R *m z) := R_pd.2 z z0.
      rewrite !innov_covE.
      rewrite mulmxDr.
      rewrite mulmxDl.
      rewrite mxtraceD.
      exact: ltr_wpDl h1 h2.
  Qed.

  (*
    Обратимость инновационной ковариации.

    При $P_(k|k-1) succ.eq 0$ матрица $R_(e,k)$ обратима, что делает корректным
    шаг обновления и усиление Калмана.

    - @kailath2000[§ 9.5.3 "Existence"].
  *)
  Corollary innov_cov_inv (P_pred : 'M[ℂ]_n) :
    psd P_pred -> innov_cov P_pred \in unitmx.
  Proof.
    move=> psdP.
    have hpd : pd (innov_cov P_pred) := innov_cov_pd psdP.
    exact: pd_unit hpd.
  Qed.

  (*
    Форма Джозефа.

    $P_(k|k) = (E_n - K_k H) P_(k|k-1) (E_n - K_k H)† + K_k R K_k†$.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Definition joseph_form (P_pred : 'M[ℂ]_n) : 'M[ℂ]_n :=
    let K := filter_gain P_pred in
    let EmKH := 1%:M - K *m H in
    EmKH *m P_pred *m EmKH^t* + K *m R *m K^t*.

  (*
    Эквивалентность формы Джозефа стандартной.

    При оптимальном усилении Калмана форма Джозефа совпадает со стандартным
    обновлением.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Lemma joseph_formE (P_pred : 'M[ℂ]_n) :
    psd P_pred ->
    joseph_form P_pred = update_cov P_pred.
  Proof.
    move=> psdP.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    set K := filter_gain P_pred.
    have KS : K *m innov_cov P_pred = P_pred *m H^t*.
      by rewrite /K filter_gainE -mulmxA mulVmx // mulmx1.
    have hE : K *m H *m P_pred *m H^t* + K *m R = P_pred *m H^t*.
      by move: KS; rewrite innov_covE mulmxDr !mulmxA.
    have KR : K *m R = (1%:M - K *m H) *m P_pred *m H^t*.
      by rewrite 2!mulmxBl !mul1mx -hE addrC addKr.
    rewrite /joseph_form !update_covE -/K.
    rewrite [K *m R]KR.
    rewrite -[X in _ + X]mulmxA.
    rewrite -mulmxDr.
    rewrite trmxCB trmxC1 trmxC_mul.
    by rewrite subrK mulmx1.
  Qed.

  (*
    Сохранение неотрицательной определённости шагом обновления.

    Если $P_(k|k-1) succ.eq 0$, то форма Джозефа неотрицательно определена.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Lemma update_cov_psd (P_pred : 'M[ℂ]_n) :
    psd P_pred -> psd (joseph_form P_pred).
  Proof.
    move=> psdP.
    rewrite /joseph_form.
    set K := filter_gain P_pred.
    set EmKH := 1%:M - K *m H.
    apply: psd_add.
    - exact: psd_lcongr EmKH psdP.
    - exact: psd_lcongr K (pd_psd R_pd).
  Qed.

  (*
    Эрмитовость апостериорной ковариации.

    Если $P_(k|k-1) succ.eq 0$, то форма Джозефа эрмитова.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Lemma update_cov_sym (P_pred : 'M[ℂ]_n) :
    psd P_pred -> joseph_form P_pred = (joseph_form P_pred)^t*.
  Proof.
    move=> psdP.
    exact: (update_cov_psd psdP).1.
  Qed.

  (*
    Монотонное убывание следа.

    $"Tr" P_(k|k) <= "Tr" P_(k|k-1)$.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Lemma update_cov_trace_le (P_pred : 'M[ℂ]_n) :
    psd P_pred ->
    \tr (update_cov P_pred) <= \tr P_pred.
  Proof.
    move=> psdP.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    set K := filter_gain P_pred.
    have KS : K *m innov_cov P_pred = P_pred *m H^t*.
      by rewrite /K filter_gainE -mulmxA mulVmx // mulmx1.
    have Psym : P_pred = P_pred^t* := psdP.1.
    have Ssym : innov_cov P_pred = (innov_cov P_pred)^t*
      := (innov_cov_pd psdP).1.
    have hHP : innov_cov P_pred *m K^t* = H *m P_pred.
      have := congr1 (fun M : 'M[ℂ]_(n, p) => M^t*) KS.
      by rewrite !trmxC_mul trmxCK -Ssym -Psym.
    have eq_KHP : K *m H *m P_pred = K *m innov_cov P_pred *m K^t*.
      by rewrite -[LHS]mulmxA -hHP mulmxA.
    rewrite !update_covE -/K mulmxBl mul1mx linearB /=.
    rewrite lerBlDr lerDl eq_KHP.
    apply: psd_tr_ge0.
    exact: psd_lcongr K (pd_psd (innov_cov_pd psdP)).
  Qed.

  (*
    Тождество информационной формы.

    При $P_(k|k-1) succ 0$ выполнено
    $"update_cov" P_(k|k-1) dot ((P_(k|k-1))^(-1) + H† R^(-1) H) = E_n$.

    - @kailath2000[§ 9.5, Theorem 9.5.1 "Standard and Information Forms"].
  *)
  Lemma update_cov_information_form (P_pred : 'M[ℂ]_n) :
    pd P_pred ->
    update_cov P_pred *m (invmx P_pred + H^t* *m invmx R *m H) = 1%:M.
  (*
    Подставляем $"update_cov" P = (E_n - K H) P$ и раскрываем произведение:
    слагаемое с $P^(-1)$ равно $E_n - K H$. Из $K R_e = P H†$ (определение
    усиления) и $R_e = H P H† + R$ следует $K R = (E_n - K H) P H†$, поэтому
    слагаемое с $H† R^(-1) H$ равно $K R R^(-1) H = K H$; сумма равна $E_n$.
  *)
  Proof.
    move=> Ppd.
    have psdP : psd P_pred := pd_psd Ppd.
    have Punit : P_pred \in unitmx := pd_unit Ppd.
    have Runit : R \in unitmx := pd_unit R_pd.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    set K := filter_gain P_pred.
    have KS : K *m innov_cov P_pred = P_pred *m H^t*.
      by rewrite /K filter_gainE -mulmxA mulVmx // mulmx1.
    have hE : K *m H *m P_pred *m H^t* + K *m R = P_pred *m H^t*.
      by move: KS; rewrite innov_covE mulmxDr !mulmxA.
    have KR : K *m R = (1%:M - K *m H) *m P_pred *m H^t*.
      by rewrite 2!mulmxBl !mul1mx -hE addrC addKr.
    rewrite !update_covE -/K mulmxDr.
    rewrite -[X in X + _]mulmxA mulmxV // mulmx1.
    rewrite mulmxA mulmxA -KR.
    rewrite -[K *m R *m invmx R]mulmxA mulmxV // mulmx1.
    by rewrite subrK.
  Qed.

  (*
    Обратимость апостериорной ковариации.

    При $P_(k|k-1) succ 0$ шаг обновления невырожден.

    - @kailath2000[§ 9.5.3 "Existence"].
  *)
  Corollary update_cov_unit (P_pred : 'M[ℂ]_n) :
    pd P_pred -> update_cov P_pred \in unitmx.
  Proof.
    move=> Ppd.
    by have [h _] := mulmx1_unit (update_cov_information_form Ppd).
  Qed.

  (*
    Явная информационная форма.

    $(P_(k|k))^(-1) = (P_(k|k-1))^(-1) + H† R^(-1) H$.

    - @kailath2000[§ 9.5, Theorem 9.5.1 "Standard and Information Forms"].
  *)
  Corollary update_cov_inverse (P_pred : 'M[ℂ]_n) :
    pd P_pred ->
    invmx (update_cov P_pred) = invmx P_pred + H^t* *m invmx R *m H.
  Proof.
    move=> Ppd.
    have Uunit : update_cov P_pred \in unitmx := update_cov_unit Ppd.
    have IF := update_cov_information_form Ppd.
    by rewrite -[LHS]mulmx1 -IF mulmxA mulVmx // mul1mx.
  Qed.

  (*
    Сохранение положительной определённости шагом обновления.

    При $P_(k|k-1) succ 0$ имеем $P_(k|k) succ 0$.

    - @kailath2000[§ 9.5.3 "Existence"].
  *)
  Corollary update_cov_pd (P_pred : 'M[ℂ]_n) :
    pd P_pred -> pd (update_cov P_pred).
  Proof.
    move=> Ppd.
    have Uunit : update_cov P_pred \in unitmx := update_cov_unit Ppd.
    have IF_inv : invmx (update_cov P_pred) =
                  invmx P_pred + H^t* *m invmx R *m H :=
      update_cov_inverse Ppd.
    have hP_inv_pd : pd (invmx P_pred) := pd_inv Ppd.
    have hRinv_psd : psd (invmx R) := pd_psd (pd_inv R_pd).
    have hHterm_psd := psd_congr H hRinv_psd.
    have hSum_pd : pd (invmx (update_cov P_pred)).
      by rewrite IF_inv; exact: pd_add hP_inv_pd hHterm_psd.
    have := pd_inv hSum_pd.
    by rewrite invmxK.
  Qed.

  (*
    Монотонность шага обновления в смысле порядка Лёвнера.

    Если $P_(k|k-1) succ.eq 0$, то $P_(k|k-1) - P_(k|k) succ.eq 0$, причём явная
    формула разности равна $(H P_(k|k-1))† R_(e,k)^(-1) (H P_(k|k-1))$.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"].
  *)
  Lemma update_cov_le (P_pred : 'M[ℂ]_n) :
    psd P_pred -> psd (P_pred - update_cov P_pred).
  Proof.
    move=> psdP.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    have hSpd : pd (innov_cov P_pred) := innov_cov_pd psdP.
    have hSinv_psd : psd (invmx (innov_cov P_pred)) := pd_psd (pd_inv hSpd).
    set K := filter_gain P_pred.
    have eq1 : P_pred - update_cov P_pred = K *m H *m P_pred.
      by rewrite !update_covE -/K mulmxBl mul1mx opprB addrC subrK.
    have eq2 : K *m H *m P_pred =
              (H *m P_pred)^t* *m invmx (innov_cov P_pred) *m (H *m P_pred).
      rewrite /K filter_gainE trmxC_mul -psdP.1.
      by rewrite !mulmxA.
    by rewrite eq1 eq2; exact: psd_congr (H *m P_pred) hSinv_psd.
  Qed.

  (*
    Альтернативный шаг обновления.

    Для $K' in CC^(n times p)$ положим
    $"alt_update_cov" (K', P) := (E_n - K' H) P (E_n - K' H)† + K' R K'†$.

    - @kailath2000[§ 9.2, Theorem 9.2.1 "Innovations"].
  *)
  Local Notation alt_update_cov := (riccati_def.alt_update_cov conjC H R).

  (*
    Тождество выделения полного квадрата.

    При $P succ.eq 0$ выполнено
    $"alt_update_cov"(K', P) = "update_cov" P + (K' - K) R_e (K' - K)†$, где
    $K$ обозначает оптимальное усиление, а $R_e$ инновационную ковариацию.

    - @kailath2000[§ 9.2, Theorem 9.2.1 "Innovations"].
  *)
  Lemma alt_update_cov_diff (P_pred : 'M[ℂ]_n) (K' : 'M[ℂ]_(n, p)) :
    psd P_pred ->
    alt_update_cov K' P_pred =
      update_cov P_pred
      + (K' - filter_gain P_pred) *m innov_cov P_pred
                                  *m (K' - filter_gain P_pred)^t*.
  Proof.
    move=> psdP.
    set K := filter_gain P_pred.
    set S := innov_cov P_pred.
    set dK := K' - K.
    have Sunit : S \in unitmx := innov_cov_inv psdP.
    have Psym : P_pred = P_pred^t* := psdP.1.
    have Ssym : S = S^t* := (pd_psd (innov_cov_pd psdP)).1.
    have KS : K *m S = P_pred *m H^t*.
      by rewrite /K filter_gainE -mulmxA mulVmx // mulmx1.
    have HPeq : S *m K^t* = H *m P_pred.
      have := congr1 (fun M : 'M[ℂ]_(n, p) => M^t*) KS.
      by rewrite !trmxC_mul trmxCK -Psym -Ssym.
    (*
      Раскрываем $"alt_update_cov" K' P$ в виде
      $P + K' S K'† - K' H P - P H† K'†$
    *)
    have alt_e : alt_update_cov K' P_pred =
      P_pred + K' *m innov_cov P_pred *m K'^t*
            - K' *m H *m P_pred
            - P_pred *m H^t* *m K'^t*.
      rewrite alt_update_covE !innov_covE.
      rewrite trmxCB trmxC1 trmxC_mul.
      rewrite mulmxBl mul1mx mulmxBl !mulmxBr !mulmx1 opprB.
      rewrite mulmxDr mulmxDl.
      rewrite ![_ *m (_ *m _)]mulmxA.
      rewrite -[_ - _ + (_ - _) + _]addrA addrACA.
      rewrite [- (P_pred *m H ^t* *m K' ^t*) + K' *m R *m K' ^t*]addrC.
      rewrite -[in RHS]addrA -[in RHS]addrA.
      rewrite -addrA addrACA.
      by [].
    (* Раскрываем `update_cov` *)
    have upd_e : update_cov P_pred = P_pred - K *m H *m P_pred.
      by rewrite !update_covE -/K mulmxBl mul1mx.
    (* Раскрываем $(dif K) S (dif K)†$ *)
    have dK_e : dK *m S *m dK^t* =
      K' *m S *m K'^t* - K' *m H *m P_pred
      - P_pred *m H^t* *m K'^t* + K *m H *m P_pred.
      rewrite /dK [(K' - K)^t*]trmxCB mulmxBr !mulmxBl opprB.
      have e1 : K' *m S *m K^t* = K' *m H *m P_pred.
        by rewrite -mulmxA HPeq mulmxA.
      have e2 : K *m S *m K'^t* = P_pred *m H^t* *m K'^t*.
        by rewrite KS.
      have e3 : K *m S *m K^t* = K *m H *m P_pred.
        by rewrite -mulmxA HPeq mulmxA.
      rewrite e1 e2 e3.
      rewrite -[(K' *m S *m K' ^t* - P_pred *m H ^t* *m K' ^t* + (K *m H *m P_pred - K' *m H *m P_pred))]addrA.
      rewrite -[(K' *m S *m K' ^t* - K' *m H *m P_pred - P_pred *m H ^t* *m K' ^t*) + K *m H *m P_pred]addrA.
      have -> : K' *m S *m K' ^t* - K' *m H *m P_pred + (- (P_pred *m H ^t* *m K' ^t*) + K *m H *m P_pred) =
                K' *m S *m K' ^t* + ((- (K' *m H *m P_pred)) + (- (P_pred *m H ^t* *m K' ^t*) + K *m H *m P_pred)).
        by rewrite -addrA.
      have ht :
        (- (K' *m H *m P_pred)) + (- (P_pred *m H ^t* *m K' ^t*) + K *m H *m P_pred) =
        (- (P_pred *m H ^t* *m K' ^t*) + (K *m H *m P_pred - K' *m H *m P_pred)).
        rewrite addrA.
        rewrite (addrAC (- (K' *m H *m P_pred)) (- (P_pred *m H ^t* *m K' ^t*)) (K *m H *m P_pred)).
        rewrite [(- (K' *m H *m P_pred)) + K *m H *m P_pred]addrC.
        by rewrite addrC.
      by rewrite ht.
    rewrite alt_e dK_e -/K -/S -/dK upd_e.
    (*
      Цель: $P + α - β - γ = (P - δ) + (α - β - γ + δ)$, где
      - $α = K' S K'†$
      - $β = K' H P$
      - $γ = P H† K'†$
      - $δ = K H P$.
    *)
    rewrite !addrA.
    rewrite [P_pred - K *m H *m P_pred + K' *m S *m K'^t*]addrAC.
    rewrite [P_pred + K' *m S *m K'^t* - K *m H *m P_pred - K' *m H *m P_pred]addrAC.
    rewrite [P_pred + K' *m S *m K'^t* - K' *m H *m P_pred - K *m H *m P_pred
            - P_pred *m H^t* *m K'^t*]addrAC.
    by rewrite subrK.
  Qed.

  (*
    Оптимальность усиления Калмана по следу.

    Среди всех усилений выбор Калмана минимизирует след апостериорной
    ковариации: $"Tr"("update_cov" P) <= "Tr"("alt_update_cov"(K', P))$ для
    любого $K'$.

    - @kailath2000[§ 9.2, Theorem 9.2.1 "The Innovations Recursions"].
  *)
  Theorem filter_gain_optimal (P_pred : 'M[ℂ]_n) (K' : 'M[ℂ]_(n, p)) :
    psd P_pred ->
    \tr (update_cov P_pred) <= \tr (alt_update_cov K' P_pred).
  Proof.
    move=> psdP.
    rewrite (alt_update_cov_diff K' psdP) linearD /=.
    rewrite -[X in X <= _]addr0 lerD2l.
    set dK := K' - filter_gain P_pred.
    apply: psd_tr_ge0.
    exact: psd_lcongr dK (pd_psd (innov_cov_pd psdP)).
  Qed.

  (*
    Стационарное условие.

    $K_k R_(e,k) = P_(k|k-1) H†$.

    - @kailath2000[§ 3.3.1 "Orthogonality Condition"].
  *)
  Theorem filter_gain_normal_eq (P_pred : 'M[ℂ]_n) :
    psd P_pred ->
    filter_gain P_pred *m innov_cov P_pred = P_pred *m H^t*.
  Proof.
    move=> psdP.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    by rewrite filter_gainE -mulmxA mulVmx // mulmx1.
  Qed.

  (*
    Блок наблюдаемости.

    Для $i in {0, dots, n-1}$ полагают $"obsv_block"(i) := H F^i$.

    - @kailath2000[App. C, § C.4 "Observability"].
  *)

  Definition obsv_block (i : nat) : 'M[ℂ]_(p, n) :=
    H *m (F ^+ i).

  (*
    Наблюдаемость пары $(H, F)$.

    Пара наблюдаема, если объединённое ядро всех блоков наблюдаемости
    тривиально.

    - @kailath2000[App. C, § C.4 "Observability"].
  *)
  Definition observable : Prop :=
    forall (x : 'cV[ℂ]_n), (forall i : 'I_n, obsv_block i *m x = 0) -> x = 0.

  (*
    Блок управляемости.

    Для $i in {0, dots, n-1}$ полагают $"ctrl_block"(i) := F^i G$.

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)

  Definition ctrl_block (i : nat) : 'M[ℂ]_(n, m) :=
    (F ^+ i) *m G.

  (*
    Управляемость пары $(F, G)$.

    Пара управляема, если строковое ядро всех блоков управляемости тривиально.

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)
  Definition controllable : Prop :=
    forall (y : 'rV[ℂ]_n), (forall i : 'I_n, y *m ctrl_block i = 0) -> y = 0.

  (*
    Вспомогательное: итерация Риккати сохраняет неотрицательную определённость.
  *)
  Lemma riccati_iter_psd (P0 : 'M[ℂ]_n) (k : nat) :
    psd P0 -> psd (iter k (fun P => update_cov (predict_cov P)) P0).
  Proof.
    move=> psdP; elim: k => [//|k IH] /=.
    have hPred : psd (predict_cov (iter k (fun P => update_cov (predict_cov P)) P0))
      := predict_cov_psd IH.
    by rewrite -(joseph_formE hPred); exact: update_cov_psd hPred.
  Qed.

  (*
    Сходимость / неподвижная точка Риккати.

    Сходимость траектории Риккати к стационарной точке $P_ss$ и сходимость
    матрицы усиления Калмана доказаны в `Section DARE`.

    Схема доказательства: детектируемость `[F,H]` даёт стабилизирующее усиление,
    а оно - устойчивость по Шуру матрицы замкнутого контура.

    См. `dare.dare_stabilizing_sol_frob`, `dare.filter_gain_frob_cvgn`,
    `dare.riccati_frob_cvgn`.

    - @kailath2000[§ 9.2, Theorem 9.2.1];
    - @kailath2000[§ 14.5].
  *)
  Local Notation riccati_step := (riccati_def.riccati_step conjC F G H Q R).

  Local Notation riccati_fixpoint := (riccati_def.riccati_fixpoint conjC F G H Q R).

  (*
    Теоремы, доказанные в `dare`:
    - Существование $P_ss$;
    - Положительная определённость $P_ss$;
    - Сходимость по норме Фробениуса траектории и коэффициента усиления;
    - Единственность.
    Здесь указана определимость `riccati_step` и `riccati_fixpoint`, на которые
    ссылается `Section DARE`. Завершающая теорема
    `dare.kalman_filter_frob_cvgn`: ковариационная часть реального цикла фильтра
    `kf_step` (ниже) совпадает с `riccati_step` (`dare.kf_cov_step`), поэтому
    ковариация и коэффициент усиления реального фильтра сходятся к стационарным
    над любыми посл-тями измерений.
  *)

  (*
    Состояние фильтра есть пара: оценка состояния и ковариация ошибки.

    - @kailath2000[§ 9.3 "Recursions for Predicted and Filtered State Estimators"].
  *)
  Record kf_state := KFState {
    kf_x : 'cV[ℂ]_n;
    kf_P : 'M[ℂ]_n;
  }.

  Definition kf_predict (st : kf_state) (u : 'cV[ℂ]_m) : kf_state :=
    KFState (predict_state (kf_x st) u) (predict_cov (kf_P st)).

  Definition kf_update (st : kf_state) (y : 'cV[ℂ]_p) : kf_state :=
    let P_pred := kf_P st in
    KFState (update_state P_pred (kf_x st) y) (update_cov P_pred).

  (*
    Полный цикл фильтра. Ковариация `kf_P (kf_step st u y)` не зависит от данных
    `u`/`y` и равна `riccati_step (kf_P st)` (см. `dare.kf_cov_step`); отсюда
    сходимость фильтра - `dare.kalman_filter_frob_cvgn`.

    - @kailath2000[§ 9.3 "Recursions for Predicted and Filtered State Estimators"].
  *)
  Definition kf_step (st : kf_state) (u : 'cV[ℂ]_m) (y : 'cV[ℂ]_p) :
    kf_state := kf_update (kf_predict st u) y.

  (*
    Инвариант неотрицательной определённости одного шага.

    Полный шаг сохраняет неотрицательную определённость ковариации.

    - @kailath2000[§ 9.3 "Recursions for Predicted and Filtered State Estimators"].
  *)
  Theorem kf_step_psd (st : kf_state) (u : 'cV[ℂ]_m) (y : 'cV[ℂ]_p) :
    psd (kf_P st) -> psd (kf_P (kf_step st u y)).
  Proof.
    move=> hP.
    rewrite /kf_step /kf_update /kf_predict /=.
    have hPred : psd (predict_cov (kf_P st)) := predict_cov_psd hP.
    rewrite -(joseph_formE hPred).
    exact: update_cov_psd hPred.
  Qed.

End KalmanFilter.

(*
  Сокращения для комплексного случая (`conj := conjC`): операторы из
  `riccati_def` при сопряжении `conjC` над `numClosedFieldType`. Через них
  формулировки и леммы переносятся в файлы-потребители без изменения мест
  применения (`predict_cov F G Q P`, `riccati_step F G H Q R P` и так далее).
  Файлы вычислимого уточнения работают с обобщёнными определениями напрямую
  (`riccati_def.predict_cov conj ...`), минуя эти сокращения.
*)
Notation predict_cov := (riccati_def.predict_cov conjC).
Notation innov_cov := (riccati_def.innov_cov conjC).
Notation filter_gain := (riccati_def.filter_gain conjC).
Notation update_cov := (riccati_def.update_cov conjC).
Notation alt_update_cov := (riccati_def.alt_update_cov conjC).
Notation riccati_step := (riccati_def.riccati_step conjC).
Notation riccati_fixpoint := (riccati_def.riccati_fixpoint conjC).
