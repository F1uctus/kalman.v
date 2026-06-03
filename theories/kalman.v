Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From mathcomp.algebra Require Import sesquilinear spectral.
From Kalman Require Import mxnotation mxherm mxdefinite mxloewner spectral expectation.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section KalmanFilter.

  Variable (ℂ : numClosedFieldType).

  Variables (m n p : nat).

  Variable F : 'M[ℂ]_n.      (* Матрица перехода состояний *)
  Variable G : 'M[ℂ]_(n, m). (* Матрица управляющего воздействия *)
  Variable H : 'M[ℂ]_(p, n). (* Матрица наблюдения *)
  Variable Q : 'M[ℂ]_m.      (* Ковариация шума управления *)
  Variable R : 'M[ℂ]_p.      (* Ковариация шума измерения *)

  (* Общие предположения о ковариациях шума *)
  Hypothesis Q_psd : psd Q.
  Hypothesis R_pd : pd R.

  Variable x0 : 'cV[ℂ]_n.

  Variable w : nat -> 'cV[ℂ]_m. (* Шум управления *)
  Variable v : nat -> 'cV[ℂ]_p. (* Шум измерения *)

  (*
    Шаг предсказания (распространение оценки и ковариации).

    ([kailath2000], § 9.3, Lemma 9.3.3)
  *)
  Definition predict_state (x_prev : 'cV[ℂ]_n) (u : 'cV[ℂ]_m) : 'cV[ℂ]_n :=
    F *m x_prev + G *m u.

  Definition predict_cov (P_prev : 'M[ℂ]_n) : 'M[ℂ]_n :=
    F *m P_prev *m F^t* + G *m Q *m G^t*.

  (* Предсказанная ковариация симметрична. *)
  Lemma predict_cov_sym (P : 'M[ℂ]_n) :
    P = P^t* -> predict_cov P = (predict_cov P)^t*.
  Proof.
    move=> Psym.
    have hP : (F *m P *m F^t*)^t* = F *m P *m F^t*.
      by rewrite trmxC_mul trmxC_mul !trmxCK -mulmxA -Psym.
    have hQ : (G *m Q *m G^t*)^t* = G *m Q *m G^t*.
      by rewrite trmxC_mul trmxC_mul !trmxCK -mulmxA -Q_psd.1.
    rewrite /predict_cov trmxC_add hP hQ.
    done.
  Qed.

  (* Предсказанная ковариация сохраняет неотрицательную определённость. *)
  Lemma predict_cov_psd (P : 'M[ℂ]_n) :
    psd P -> psd (predict_cov P).
  Proof.
    move=> psdP.
    have h1 := psd_lcongr F psdP.
    have h2 := psd_lcongr G Q_psd.
    have hsum : psd (F *m P *m F^t* + G *m Q *m G^t*) := psd_add h1 h2.
    rewrite /predict_cov.
    exact: hsum.
  Qed.

  (* Инновационная ковариация. *)
  Definition innov_cov (P_pred : 'M[ℂ]_n) : 'M[ℂ]_p :=
    H *m P_pred *m H^t* + R.

  (*
    Коэффициент усиления Калмана.

    ([kailath2000], § 9.2, Theorem 9.2.1)
  *)
  Definition kalman_gain (P_pred : 'M[ℂ]_n) : 'M[ℂ]_(n, p) :=
    P_pred *m H^t* *m invmx (innov_cov P_pred).

  (* Обновление состояния. *)
  Definition update_state (P_pred : 'M[ℂ]_n)
      (x_pred : 'cV[ℂ]_n) (y : 'cV[ℂ]_p) : 'cV[ℂ]_n :=
    let K := kalman_gain P_pred in
    x_pred + K *m (y - H *m x_pred).

  (*
    Обновление ковариации (стандартная форма).

    ([kailath2000], § 9.3, Lemma 9.3.2)
  *)
  Definition update_cov (P_pred : 'M[ℂ]_n) : 'M[ℂ]_n :=
    let K := kalman_gain P_pred in
    (1%:M - K *m H) *m P_pred.

  (* Обновление истинного вектора состояния. *)
  Definition x_true (u : nat -> 'cV[ℂ]_m) : nat -> 'cV[ℂ]_n :=
    fix f k :=
      match k with
      | 0%N => x0
      | k'.+1 => F *m f k' + G *m u k' + G *m w k'.+1
      end.

  (* Обновление оценочного вектора состояния. *)
  Definition x_hat (u : nat -> 'cV[ℂ]_m) (y : nat -> 'cV[ℂ]_p)
      (P_seq : nat -> 'M[ℂ]_n) : nat -> 'cV[ℂ]_n :=
    fix f k :=
      match k with
      | 0%N => 0  (* начальная оценка; предполагаем несмещённый старт *)
      | k'.+1 =>
        let x_pred := predict_state (f k') (u k') in
        let P_pred := predict_cov (P_seq k') in
        update_state P_pred x_pred (y k'.+1)
      end.

  (* Ошибка оценивания. *)
  Definition err u y Ps k := x_true u k - x_hat u y Ps k.

  (*
    ============================================================================
    Несмещённость
    ============================================================================

    Абстрактный оператор математического ожидания. Алгебраические аксиомы и
    производные тождества (Exp_zero/Exp_opp/Exp_sub) вынесены в `expectation.v`;
    здесь сохранены гипотезы линейности и шум-специфичные `Exp_w_zero`,
    `Exp_v_zero`.
  *)

  Variable 𝔼 : forall {r c : nat}, 'M[ℂ]_(r, c) -> 'M[ℂ]_(r, c).

  Hypothesis Exp_add : forall r c (A B : 'M[ℂ]_(r, c)),
    𝔼 (A + B) = 𝔼 A + 𝔼 B.
  Hypothesis Exp_scale : forall r c (a : ℂ) (A : 'M[ℂ]_(r, c)),
    𝔼 (a *: A) = a *: 𝔼 A.
  Hypothesis Exp_mulmx_l : forall r c s (A : 'M[ℂ]_(r, c)) (B : 'M[ℂ]_(c, s)),
    𝔼 (A *m B) = A *m 𝔼 B.

  Hypothesis Exp_w_zero : forall k, 𝔼 (w k) = 0.
  Hypothesis Exp_v_zero : forall k, 𝔼 (v k) = 0.

  (* Удобные локальные имена для алгебраических тождеств из expectation.v *)
  Notation Exp_zero := (Exp_zero Exp_scale).
  Notation Exp_opp := (Exp_opp Exp_scale).
  Notation Exp_sub := (Exp_sub Exp_add Exp_scale).

  (* Чисто абелева перегруппировка, используемая ниже. *)
  Lemma abelian_swap_cancel (M : zmodType) (a b c d e : M) :
    a + b + c - (d + b + e) = a - d + c - e.
  Proof.
    rewrite !opprD !addrA.
    rewrite (addrAC _ _ (- b)) (addrAC _ c (- b)) addrK.
    by rewrite (addrAC _ c (- d)).
  Qed.

  (*
    Рекурсия для ошибки оценивания. Уравнение измерения предполагает, что
    наблюдение есть линейная комбинация истинного состояния и шума.
  *)
  Lemma err_recursion u y Ps k :
    (forall j, y j = H *m x_true u j + v j) ->
    err u y Ps k.+1 =
      F *m err u y Ps k + G *m w k.+1 -
      kalman_gain (predict_cov (Ps k)) *m
        (H *m F *m err u y Ps k + H *m G *m w k.+1 + v k.+1).
  Proof.
    move=> Hzm.
    rewrite /err /= /update_state /predict_state.
    rewrite (Hzm k.+1) /=.
    set Kk := kalman_gain (predict_cov (Ps k)).
    set xt := x_true u k.
    set xh := x_hat u y Ps k.
    (*
      Внутреннее выражение: H ⋅ x_true k+1 + v k+1 - H ⋅ (F⋅xh + G⋅u k) = H ⋅ F
      ⋅ (xt - xh) + H ⋅ G ⋅ w k+1 + v k+1
    *)
    have inner :
      H *m (F *m xt + G *m u k + G *m w k.+1) + v k.+1 -
        H *m (F *m xh + G *m u k) =
      H *m F *m (xt - xh) + H *m G *m w k.+1 + v k.+1.
    { rewrite mulmxBr !mulmxDr !mulmxA addrAC opprD !addrA.
      rewrite (addrAC _ _ (- (H *m G *m u k))).
      rewrite (addrAC _ (H *m G *m w k.+1)) addrK.
      by rewrite [X in X + _ = _]addrAC. }
    rewrite inner.
    (* Внешнее выражение *)
    by rewrite abelian_swap_cancel [in RHS]mulmxBr.
  Qed.

  Lemma Exp_predict_innov_zero u y Ps k :
    𝔼 (err u y Ps k) = 0 ->
    𝔼 (H *m F *m err u y Ps k + H *m G *m w k.+1 + v k.+1) = 0.
  Proof.
    move=> H0.
    rewrite 2!Exp_add.
    rewrite (Exp_mulmx_l (H *m F)) H0 mulmx0 add0r.
    rewrite (Exp_mulmx_l (H *m G)) Exp_w_zero mulmx0.
    by rewrite !add0r (Exp_v_zero k.+1).
  Qed.

  (*
    Несмещённость: E[ошибка] = 0 на каждом шаге.

    ([kailath2000], § 9.2)
  *)
  Theorem unbiased u y Ps :
    (forall j, y j = H *m x_true u j + v j) ->
    𝔼 (err u y Ps 0) = 0 ->
    forall k, 𝔼 (err u y Ps k) = 0.
  Proof.
    move=> Hzm E0; elim=> [//|k IH].
    rewrite (err_recursion _ _ Hzm) Exp_sub Exp_add (Exp_mulmx_l F) IH mulmx0 add0r.
    rewrite (Exp_mulmx_l G) Exp_w_zero mulmx0 add0r.
    rewrite (Exp_mulmx_l (kalman_gain _)) (Exp_predict_innov_zero IH).
    by rewrite mulmx0 oppr0.
  Qed.

  (*
    ============================================================================
    Sec. 1.4. The Innovations Process
    ============================================================================

    Положительная определённость инновационной ковариации
    (=> существование S⁻¹).

    ([kailath2000], § 9.5, Lemma 9.5.1)
  *)
  Lemma innov_cov_pd (P_pred : 'M[ℂ]_n) :
    psd P_pred -> pd (innov_cov P_pred).
  Proof.
    move=> psdP.
    have hpsd := psd_lcongr H psdP.
    split.
    - rewrite /innov_cov.
      rewrite trmxC_add.
      f_equal.
      * exact hpsd.1.
      * exact R_pd.1.
    - move=> z z0.
      have h1 : 0 <= \tr (z^t* *m (H *m P_pred *m H^t*) *m z) := hpsd.2 z.
      have h2 : 0 < \tr (z^t* *m R *m z) := R_pd.2 z z0.
      rewrite /innov_cov.
      rewrite mulmxDr.
      rewrite mulmxDl.
      rewrite mxtraceD.
      exact: ltr_wpDl h1 h2.
  Qed.

  Lemma innov_cov_inv (P_pred : 'M[ℂ]_n) :
    psd P_pred -> innov_cov P_pred \in unitmx.
  Proof.
    move=> psdP.
    have hpd : pd (innov_cov P_pred) := innov_cov_pd psdP.
    exact: pd_invertible hpd.
  Qed.

  (*
    Форма Джозефа (алгебраически эквивалентна, удобна для доказательств).

    ([kailath2000], § 9.3, Lemma 9.3.2)
  *)
  Definition joseph_form (P_pred : 'M[ℂ]_n) : 'M[ℂ]_n :=
    let K := kalman_gain P_pred in
    let ImKH := 1%:M - K *m H in
    ImKH *m P_pred *m ImKH^t* + K *m R *m K^t*.

  (* Форма Джозефа совпадает со стандартным обновлением при усилении Калмана *)
  Lemma joseph_eq_update (P_pred : 'M[ℂ]_n) :
    psd P_pred ->
    joseph_form P_pred = update_cov P_pred.
  Proof.
    move=> psdP.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    set K := kalman_gain P_pred.
    have KS : K *m innov_cov P_pred = P_pred *m H^t*.
      by rewrite /K /kalman_gain -mulmxA mulVmx // mulmx1.
    have hE : K *m H *m P_pred *m H^t* + K *m R = P_pred *m H^t*.
      by move: KS; rewrite /innov_cov mulmxDr !mulmxA.
    have KR : K *m R = (1%:M - K *m H) *m P_pred *m H^t*.
      by rewrite 2!mulmxBl !mul1mx -hE addrC addKr.
    rewrite /joseph_form /update_cov -/K.
    rewrite [K *m R]KR.
    rewrite -[X in _ + X]mulmxA.
    rewrite -mulmxDr.
    rewrite trmxCB trmxC1 trmxC_mul.
    by rewrite subrK mulmx1.
  Qed.

  (* Сохранение неотрицательной определённости через обновление *)
  Lemma update_cov_psd (P_pred : 'M[ℂ]_n) :
    psd P_pred -> psd (joseph_form P_pred).
  Proof.
    move=> psdP.
    rewrite /joseph_form.
    set K := kalman_gain P_pred.
    set ImKH := 1%:M - K *m H.
    apply: psd_add.
    - exact: psd_lcongr ImKH psdP.
    - exact: psd_lcongr K (pd_psd R_pd).
  Qed.

  (* Симметричность обновлённой ковариации *)
  Lemma update_cov_sym (P_pred : 'M[ℂ]_n) :
    psd P_pred -> joseph_form P_pred = (joseph_form P_pred)^t*.
  Proof.
    move=> psdP.
    exact: (update_cov_psd psdP).1.
  Qed.

  (* Монотонность ковариации: след не возрастает *)
  Lemma update_cov_trace_le (P_pred : 'M[ℂ]_n) :
    psd P_pred ->
    \tr (update_cov P_pred) <= \tr P_pred.
  Proof.
    move=> psdP.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    set K := kalman_gain P_pred.
    have KS : K *m innov_cov P_pred = P_pred *m H^t*.
      by rewrite /K /kalman_gain -mulmxA mulVmx // mulmx1.
    have Psym : P_pred = P_pred^t* := psdP.1.
    have Ssym : innov_cov P_pred = (innov_cov P_pred)^t*
      := (innov_cov_pd psdP).1.
    have hHP : innov_cov P_pred *m K^t* = H *m P_pred.
      have := congr1 (fun M : 'M[ℂ]_(n, p) => M^t*) KS.
      by rewrite !trmxC_mul trmxCK -Ssym -Psym.
    have eq_KHP : K *m H *m P_pred = K *m innov_cov P_pred *m K^t*.
      by rewrite -[LHS]mulmxA -hHP mulmxA.
    rewrite /update_cov -/K mulmxBl mul1mx linearB /=.
    rewrite lerBlDr lerDl eq_KHP.
    apply: psd_tr_ge0.
    exact: psd_lcongr K (pd_psd (innov_cov_pd psdP)).
  Qed.

  (*
    Информационная форма обновления. При положительно определённой предсказанной
    ковариации справедливо тождество Вудбери: (update_cov P)^(-1) = P^(-1) + H†
    R^(-1) H. Доказательство чисто алгебраическое: используется уже выведенная
    связь K * R = (E - K * H) * P * H† и обратимости P, R, S. Это даёт основу
    для строгой убывающей версии Риккати-итерации без обращения к спектральной
    теореме.

    ([kailath2000], § 9.5, Theorem 9.5.1)
  *)
  Lemma update_cov_information_form (P_pred : 'M[ℂ]_n) :
    pd P_pred ->
    update_cov P_pred *m (invmx P_pred + H^t* *m invmx R *m H) = 1%:M.
  Proof.
    move=> Ppd.
    have psdP : psd P_pred := pd_psd Ppd.
    have Punit : P_pred \in unitmx := pd_invertible Ppd.
    have Runit : R \in unitmx := pd_invertible R_pd.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    set K := kalman_gain P_pred.
    have KS : K *m innov_cov P_pred = P_pred *m H^t*.
      by rewrite /K /kalman_gain -mulmxA mulVmx // mulmx1.
    have hE : K *m H *m P_pred *m H^t* + K *m R = P_pred *m H^t*.
      by move: KS; rewrite /innov_cov mulmxDr !mulmxA.
    have KR : K *m R = (1%:M - K *m H) *m P_pred *m H^t*.
      by rewrite 2!mulmxBl !mul1mx -hE addrC addKr.
    rewrite /update_cov -/K mulmxDr.
    rewrite -[X in X + _]mulmxA mulmxV // mulmx1.
    rewrite mulmxA mulmxA -KR.
    rewrite -[K *m R *m invmx R]mulmxA mulmxV // mulmx1.
    by rewrite subrK.
  Qed.

  (* Следствие: при pd P_pred шаг обновления обратим. *)
  Corollary update_cov_unit (P_pred : 'M[ℂ]_n) :
    pd P_pred -> update_cov P_pred \in unitmx.
  Proof.
    move=> Ppd.
    by have [h _] := mulmx1_unit (update_cov_information_form Ppd).
  Qed.

  (*
    Явная формула обратной матрицы апостериорной ковариации
    (информационная форма Калмана).

    ([kailath2000], § 9.5, Theorem 9.5.1)
  *)
  Lemma update_cov_inverse (P_pred : 'M[ℂ]_n) :
    pd P_pred ->
    invmx (update_cov P_pred) = invmx P_pred + H^t* *m invmx R *m H.
  Proof.
    move=> Ppd.
    have Uunit : update_cov P_pred \in unitmx := update_cov_unit Ppd.
    have IF := update_cov_information_form Ppd.
    by rewrite -[LHS]mulmx1 -IF mulmxA mulVmx // mul1mx.
  Qed.

  (*
    Из информационной формы: шаг обновления сохраняет положительную
    определённость. invmx(update_cov P) = invmx P + H† R^(-1) H - pd сумма pd и
    psd; обратная к pd-матрице тоже pd (см. pd_inv).

    ([kailath2000], § 9.5, Lemma 9.5.1)
  *)
  Lemma update_cov_pd (P_pred : 'M[ℂ]_n) :
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
    Порядок Лёвнера: апостериорная ковариация мажорируется априорной. Это
    содержательная (структурная) монотонность шага обновления, из которой
    следует уже доказанная trace-монотонность. Алгебраически: P - update_cov P =
    K H P = (HP)† S^(-1) (HP).
  *)
  Lemma update_cov_le (P_pred : 'M[ℂ]_n) :
    psd P_pred -> psd (P_pred - update_cov P_pred).
  Proof.
    move=> psdP.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    have hSpd : pd (innov_cov P_pred) := innov_cov_pd psdP.
    have hSinv_psd : psd (invmx (innov_cov P_pred)) := pd_psd (pd_inv hSpd).
    set K := kalman_gain P_pred.
    have eq1 : P_pred - update_cov P_pred = K *m H *m P_pred.
      by rewrite /update_cov -/K mulmxBl mul1mx opprB addrC subrK.
    have eq2 : K *m H *m P_pred =
              (H *m P_pred)^t* *m invmx (innov_cov P_pred) *m (H *m P_pred).
      rewrite /K /kalman_gain trmxC_mul -psdP.1.
      by rewrite !mulmxA.
    by rewrite eq1 eq2; exact: psd_congr (H *m P_pred) hSinv_psd.
  Qed.

  (*
    ============================================================================
    Оптимальность коэффициента усиления Калмана
    ============================================================================

    Для любого альтернативного усиления K' след апостериорной ковариации не
    меньше, чем при усилении Калмана.
  *)
  Definition alt_update_cov (K' : 'M[ℂ]_(n, p)) (P_pred : 'M[ℂ]_n) : 'M[ℂ]_n :=
    let ImKH := 1%:M - K' *m H in
    ImKH *m P_pred *m ImKH^t* + K' *m R *m K'^t*.

  (*
    Тождество выделения полного квадрата:
    `alt_update_cov K' = update_cov + (K' - K) S (K' - K)†`, где
    - `K` - коэффициент усиления Калмана;
    - `S` - инновационная ковариация (`innov_cov P_pred`).
  *)
  Lemma alt_update_cov_diff (P_pred : 'M[ℂ]_n) (K' : 'M[ℂ]_(n, p)) :
    psd P_pred ->
    alt_update_cov K' P_pred =
      update_cov P_pred
      + (K' - kalman_gain P_pred) *m innov_cov P_pred
                                  *m (K' - kalman_gain P_pred)^t*.
  Proof.
    move=> psdP.
    set K := kalman_gain P_pred.
    set S := innov_cov P_pred.
    set dK := K' - K.
    have Sunit : S \in unitmx := innov_cov_inv psdP.
    have Psym : P_pred = P_pred^t* := psdP.1.
    have Ssym : S = S^t* := (pd_psd (innov_cov_pd psdP)).1.
    have KS : K *m S = P_pred *m H^t*.
      by rewrite /K /kalman_gain -mulmxA mulVmx // mulmx1.
    have HPeq : S *m K^t* = H *m P_pred.
      have := congr1 (fun M : 'M[ℂ]_(n, p) => M^t*) KS.
      by rewrite !trmxC_mul trmxCK -Psym -Ssym.
    (*
      Шаг 1: раскрываем alt_update_cov K' P в виде P + K' S K'† - K' H P - P H†
      K'†
    *)
    have alt_e : alt_update_cov K' P_pred =
      P_pred + K' *m innov_cov P_pred *m K'^t*
            - K' *m H *m P_pred
            - P_pred *m H^t* *m K'^t*.
      rewrite /alt_update_cov /innov_cov.
      rewrite trmxCB trmxC1 trmxC_mul.
      rewrite mulmxBl mul1mx mulmxBl !mulmxBr !mulmx1 opprB.
      rewrite mulmxDr mulmxDl.
      rewrite ![_ *m (_ *m _)]mulmxA.
      rewrite -[_ - _ + (_ - _) + _]addrA addrACA.
      rewrite [- (P_pred *m H ^t* *m K' ^t*) + K' *m R *m K' ^t*]addrC.
      rewrite -[in RHS]addrA -[in RHS]addrA.
      rewrite -addrA addrACA.
      by [].
    (* Шаг 2: раскрываем update_cov *)
    have upd_e : update_cov P_pred = P_pred - K *m H *m P_pred.
      by rewrite /update_cov -/K mulmxBl mul1mx.
    (* Шаг 3: раскрываем dK ⋅ S ⋅ dK† *)
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
      Цель: P + α - β - γ = (P - δ) + (α - β - γ + δ), где α = K'SK'†, β = K'HP,
      γ = PH† K'†, δ = KHP.
    *)
    rewrite !addrA.
    rewrite [P_pred - K *m H *m P_pred + K' *m S *m K'^t*]addrAC.
    rewrite [P_pred + K' *m S *m K'^t* - K *m H *m P_pred - K' *m H *m P_pred]addrAC.
    rewrite [P_pred + K' *m S *m K'^t* - K' *m H *m P_pred - K *m H *m P_pred
            - P_pred *m H^t* *m K'^t*]addrAC.
    by rewrite subrK.
  Qed.

  (*
    Оптимальность коэффициента усиления Калмана: минимум следа апостериорной
    ковариации среди всех усилений.

    ([kailath2000], § 9.2, Theorem 9.2.1)
  *)
  Theorem kalman_gain_optimal (P_pred : 'M[ℂ]_n) (K' : 'M[ℂ]_(n, p)) :
    psd P_pred ->
    \tr (update_cov P_pred) <= \tr (alt_update_cov K' P_pred).
  Proof.
    move=> psdP.
    rewrite (alt_update_cov_diff K' psdP) linearD /=.
    rewrite -[X in X <= _]addr0 lerD2l.
    set dK := K' - kalman_gain P_pred.
    apply: psd_tr_ge0.
    exact: psd_lcongr dK (pd_psd (innov_cov_pd psdP)).
  Qed.

  (* Характеристика через производную: dTr(P+)/dK = 0 при усилении Калмана *)
  Theorem gain_stationary_point (P_pred : 'M[ℂ]_n) :
    psd P_pred ->
    kalman_gain P_pred *m innov_cov P_pred = P_pred *m H^t*.
  Proof.
    move=> psdP.
    have Sunit : innov_cov P_pred \in unitmx := innov_cov_inv psdP.
    by rewrite /kalman_gain -mulmxA mulVmx // mulmx1.
  Qed.

  (*
    ============================================================================
    Наблюдаемость и управляемость
    ============================================================================

    Наблюдаемость: пара (H, F) наблюдаема, когда составная матрица
    [H; HF; HF^2; ...; HF^(n-1)] имеет полный столбцовый ранг. Вместо явного
    построения блочной матрицы формулируем условие на ранг через ядро
    отображения.

    ([kailath2000], App. C, § C.4)
  *)

  Definition obsv_block (i : nat) : 'M[ℂ]_(p, n) :=
    H *m (F ^+ i).

  Definition observable : Prop :=
    forall (x : 'cV[ℂ]_n), (forall i : 'I_n, obsv_block i *m x = 0) -> x = 0.

  (*
    Управляемость: пара (F, G) управляема, когда составная матрица
    [G, F G, F^2 G, ..., F^(n-1) G] имеет полный строковый ранг.

    ([kailath2000], App. C, § C.3)
  *)

  Definition ctrl_block (i : nat) : 'M[ℂ]_(n, m) :=
    (F ^+ i) *m G.

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
    by rewrite -(joseph_eq_update hPred); exact: update_cov_psd hPred.
  Qed.

  (*
    ============================================================================
    Сходимость / неподвижная точка Риккати
    ============================================================================

    Дискретное алгебраическое уравнение Риккати (ДАУР, DARE).

    Сходимость траектории Риккати к стационарной точке `Pss` и сходимость
    матрицы усиления Калмана доказаны в `dare.v` ([kailath2000], § 14.5). Схема
    доказательства: обнаруживаемость `[F,H]` даёт стабилизирующее усиление, а
    оно - устойчивость по Шуру матрицы замкнутого контура.

    См. `riccati_steady_state_proven`, `kalman_gain_convergence`,
    `riccati_convergence_frob` в `dare.v`.

    ([kailath2000], § 9.2, Theorem 9.2.1; § 14.5)
  *)
  Definition riccati_step (P : 'M[ℂ]_n) : 'M[ℂ]_n :=
    update_cov (predict_cov P).

  Definition is_riccati_fix (Pss : 'M[ℂ]_n) : Prop :=
    Pss = riccati_step Pss.

  (*
    Теоремы:
    - Существование `Pss`;
    - Положительная определённость `Pss`;
    - Сходимость по норме Фробениуса траектории и коэффициента усиления;
    - Единственность.
    доказаны в `dare.v`. Здесь указана определимость `riccati_step` и
    `is_riccati_fix`, на которые ссылается dare.v. Завершающая теорема -
    `dare.kalman_filter_convergence`: ковариационная часть реального цикла
    фильтра `kf_step` (ниже) совпадает с `riccati_step` (`dare.kf_cov_step`),
    поэтому ковариация и коэффициент усиления реального фильтра сходятся к
    стационарным над любыми потоками входов/измерений.
  *)

  (* Один шаг фильтра. *)
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
    сходимость фильтра - `dare.kalman_filter_convergence`.
  *)
  Definition kf_step (st : kf_state) (u : 'cV[ℂ]_m) (y : 'cV[ℂ]_p) :
      kf_state :=
    kf_update (kf_predict st u) y.

  (*
    Инвариантность неотрицательной определённости относительно полного цикла
    предсказание–обновление.
  *)
  Lemma kf_step_psd (st : kf_state) (u : 'cV[ℂ]_m) (y : 'cV[ℂ]_p) :
    psd (kf_P st) -> psd (kf_P (kf_step st u y)).
  Proof.
    move=> hP.
    rewrite /kf_step /kf_update /kf_predict /=.
    have hPred : psd (predict_cov (kf_P st)) := predict_cov_psd hP.
    rewrite -(joseph_eq_update hPred).
    exact: update_cov_psd hPred.
  Qed.

End KalmanFilter.
