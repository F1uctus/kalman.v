(*
  Монотонность шагов фильтра Калмана в порядке Лёвнера.

  В этом файле:
  - `predict_cov_mono` - безусловная монотонность шага предсказания:
    `predict_cov` линеен в `P`, член `G Q G†` сокращается в разности, остаётся
    `F (P2 - P1) F†`.
  - `update_cov_mono` - монотонность шага обновления на всём конусе
    неотрицательно определённых матриц. Доказывается через тождество
    оптимальности `alt_update_cov_diff`: update_cov(P1) <=
    alt_update_cov(K2, P1) <= alt_update_cov(K2, P2) = update_cov(P2), где
    `K2 := kalman_gain(P2)`. Линейность `alt_update_cov` в `P` даёт среднее
    неравенство.
  - `riccati_step_mono` - комбинация двух монотонностей; монотонна на конусе
    неотрицательно определённых матриц.
  - `riccati_iter_mono_from_0` - последовательность `iter k riccati_step 0`
    неубывающая в порядке Лёвнера. База
    `iter 0 = 0 <= iter 1 = riccati_step 0` - это неотрицательная определённость
    `riccati_step 0`; шаг - `riccati_step_mono`.

  ([kailath2000], App. E, Lemma E.3.1)
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxdefinite mxloewner spectral kalman.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section RiccatiMonotone.

  Variable (ℂ : numClosedFieldType).

  Variables (m n p : nat).
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variables (Q : 'M[ℂ]_m) (R : 'M[ℂ]_p).
  Hypothesis Q_psd : psd Q.
  Hypothesis R_pd  : pd R.

  (* Монотонность шага предсказания (безусловная). *)
  Lemma predict_cov_mono (P1 P2 : 'M[ℂ]_n) :
    psd_le P1 P2 -> psd_le (predict_cov F G Q P1) (predict_cov F G Q P2).
  Proof.
    move=> hLe.
    rewrite /psd_le.
    have eq : predict_cov F G Q P2 - predict_cov F G Q P1 =
              F *m (P2 - P1) *m F^t*.
      rewrite /predict_cov opprD addrACA subrr addr0.
      by rewrite mulmxBr mulmxBl.
    rewrite eq.
    exact: psd_lcongr hLe.
  Qed.

  (*
    Монотонность шага обновления на всём конусе неотрицательно определённых
    матриц (через тождество оптимальности коэффициента усиления Калмана).
  *)
  Lemma update_cov_mono (P1 P2 : 'M[ℂ]_n) :
    psd P1 -> psd P2 -> psd_le P1 P2 ->
    psd_le (update_cov H R P1) (update_cov H R P2).
  (*
    Идея: для любого альтернативного усиления `K'` имеем
    ```
    alt_update_cov K' P2 - alt_update_cov K' P1
      = (E - K'H) (P2 - P1) (E - K'H)†
    ```
    неотрицательно определена, то есть `alt_update_cov K' (·)` монотонен в `P`.
    Положив `K2 := kalman_gain P2`, получаем
    `alt_update_cov K2 P2 = update_cov P2`
    (член `(K2 - K2) S2 (K2 - K2)†` исчезает), и
    `update_cov P1 <= alt_update_cov K2 P1`
    (член `(K2 - K1) S1 (K2 - K1)†` неотрицательно определён). Транзитивностью
    получаем `update_cov P1 <= update_cov P2`.
  *)
  Proof.
    move=> psd1 psd2 hLe.
    set K2 := kalman_gain H R P2.
    (* Шаг 1: update_cov P1 <= alt_update_cov K2 P1 *)
    have alt_P1_eq : alt_update_cov H R K2 P1 =
        update_cov H R P1
        + (K2 - kalman_gain H R P1) *m innov_cov H R P1
                                    *m (K2 - kalman_gain H R P1)^t*
      := alt_update_cov_diff H R_pd K2 psd1.
    have step1 : psd_le (update_cov H R P1) (alt_update_cov H R K2 P1).
      rewrite /psd_le alt_P1_eq addrAC subrr add0r.
      have S1_psd : psd (innov_cov H R P1)
        := pd_psd (innov_cov_pd H R_pd psd1).
      exact: psd_lcongr S1_psd.
    (* Шаг 2: alt_update_cov K2 P2 = update_cov P2 (член с K2 - K2 = 0) *)
    have alt_P2_eq : alt_update_cov H R K2 P2 = update_cov H R P2.
      rewrite (alt_update_cov_diff H R_pd K2 psd2) -/K2.
      rewrite subrr mul0mx mul0mx addr0.
      by [].
    (*
      Шаг 3: alt_update_cov K2 P1 <= alt_update_cov K2 P2 (линейно в P).
      Доказываем через `psd_le_congr` (конгруэнтность сохраняет порядок Лёвнера)
      и `psd_le_add2l` (сдвиг на константу).
    *)
    have step3 : psd_le (alt_update_cov H R K2 P1) (alt_update_cov H R K2 P2).
      rewrite /alt_update_cov.
      rewrite [(1%:M - K2 *m H) *m P1 *m _ + _]addrC.
      rewrite [(1%:M - K2 *m H) *m P2 *m _ + _]addrC.
      apply: psd_le_add2l.
      have hcongr := psd_le_congr ((1%:M - K2 *m H)^t*) hLe.
      by rewrite trmxCK in hcongr.
    (* Транзитивность *)
    have chain := psd_le_trans step1 step3.
    by rewrite alt_P2_eq in chain.
  Qed.

  (*
    Монотонность одного шага Риккати на конусе неотрицательно определённых
    матриц.

    ([kailath2000], App. E, Lemma E.3.1)
  *)
  Lemma riccati_step_mono (P1 P2 : 'M[ℂ]_n) :
    psd P1 -> psd P2 -> psd_le P1 P2 ->
    psd_le (riccati_step F G H Q R P1) (riccati_step F G H Q R P2).
  Proof.
    move=> psd1 psd2 hLe.
    rewrite /riccati_step.
    have hP1 : psd (predict_cov F G Q P1) := predict_cov_psd F G Q_psd psd1.
    have hP2 : psd (predict_cov F G Q P2) := predict_cov_psd F G Q_psd psd2.
    have hLe' : psd_le (predict_cov F G Q P1) (predict_cov F G Q P2)
      := predict_cov_mono hLe.
    exact: update_cov_mono hP1 hP2 hLe'.
  Qed.

  (*
    Затравочная последовательность от нуля: `iter k riccati_step 0` неубывающая
    в порядке Лёвнера.
  *)
  Lemma riccati_step_psd (P : 'M[ℂ]_n) :
    psd P -> psd (riccati_step F G H Q R P).
  (*
    - База `psd_le 0 (riccati_step 0)` - это неотрицательная определённость
      `riccati_step 0` (получается через форму Джозефа).
    - Шаг - `riccati_step_mono`, применённый к IH.
  *)
  Proof.
    move=> psdP.
    rewrite /riccati_step.
    have hPred : psd (predict_cov F G Q P) := predict_cov_psd F G Q_psd psdP.
    rewrite -(joseph_eq_update H R_pd hPred).
    apply: (update_cov_psd H R_pd hPred).
  Qed.

  (*
    Затравочная последовательность от нуля: `iter k riccati_step 0` неубывающая
    в порядке Лёвнера.

    ([kailath2000], App. E, Lemma E.3.1; ср. § 14.3, Remark 7)
  *)
  Lemma riccati_iter_mono_from_0 (k : nat) :
    psd_le (iter k (riccati_step F G H Q R) 0)
          (iter k.+1 (riccati_step F G H Q R) 0).
  Proof.
    have psd0n : psd (0 : 'M[ℂ]_n) := @psd0 ℂ n.
    elim: k => [|k IH].
    - (* psd_le 0 (riccati_step 0) *)
      rewrite /=.
      apply/psd_le0_psd.
      exact: (riccati_step_psd psd0n).
    - (* IH: psd_le (iter k ...) (iter k.+1 ...).
        Goal: psd_le (iter k.+1 ...) (iter k.+2 ...).
        Применяем `riccati_step_mono` к IH; используем
        `iter k.+1 f x = f (iter k f x)` для отождествления. *)
      have psdK : psd (iter k (riccati_step F G H Q R) 0)
        := riccati_iter_psd F G H Q_psd R_pd k psd0n.
      have psdSK : psd (iter k.+1 (riccati_step F G H Q R) 0)
        := riccati_iter_psd F G H Q_psd R_pd k.+1 psd0n.
      exact: (riccati_step_mono psdK psdSK IH).
  Qed.

  (* Следствие: неотрицательная определённость всех итераций. *)
  Lemma riccati_iter_from_0_psd (k : nat) :
    psd (iter k (riccati_step F G H Q R) 0).
  Proof.
    exact: (riccati_iter_psd F G H Q_psd R_pd k (@psd0 ℂ n)).
  Qed.

End RiccatiMonotone.
