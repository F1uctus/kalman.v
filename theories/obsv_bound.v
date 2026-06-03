(*
  Грамианы наблюдаемости и управляемости.

  В этом файле:
  - `obsv_gram k := ∑_(j<k) (F^j)† H† invR H F^j`
    (грамиан наблюдаемости с весом `invR`).
  - `ctrl_gram k := ∑_(j<k) F^j G Q G† (F^j)†`
    (грамиан управляемости по состоянию).

  Основные результаты:
  - `obsv_gram_psd`, `ctrl_gram_psd` - безусловная неотрицательная
    определённость.
  - `obsv_gram_pd_of_observable` - при наблюдаемости `obsv_gram n` положительно
    определён.
  - `ctrl_gram_pd_of_controllable` - при управляемости + `pd Q` `ctrl_gram n`
    положительно определён.
  - `riccati_iter_le_ctrl_gram` - верхняя оценка iter k riccati_step 0 <=
    ctrl_gram k (доказывается через `K=0`: применяя `update_cov_le` и
    `predict_cov_mono` индуктивно, плюс тождество сдвига `ctrl_gram_shift`:
    ctrl_gram (k+1) = G Q G† + F (ctrl_gram k) F† .

  Замечание. Верхняя оценка через информационную форму
  `iter k riccati_step 0 <= invmx (obsv_gram n)` при `k >= n`
  ([kailath2000], § 14.5; форма P_k⁻¹ >= obsv_gram k) здесь не доказана: она
  требует тождества Вудбери / явного выражения `invmx (predict_cov P)` через
  `invmx P` и `invmx Q`. Затравочная оценка при K=0 выше даёт ослабленную
  (зависящую от `F`) оценку, достаточную для построения предельного `Pss` при
  дополнительной гипотезе устойчивости.

  ([kailath2000], App. C, § C.3; App. C, § C.4)
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite mxloewner spectral mxfrob kalman riccati_mono.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section ObsvBound.

  Variable (ℂ : numClosedFieldType).

  Variables (m n p : nat).
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variables (Q : 'M[ℂ]_m) (R : 'M[ℂ]_p).
  Hypothesis Q_psd : psd Q.
  Hypothesis R_pd  : pd R.

  (*
    Грамиан наблюдаемости.

    ([kailath2000], App. C, § C.4)
  *)
  Definition obsv_gram (k : nat) : 'M[ℂ]_n :=
    \sum_(j < k) (F^+j)^t* *m H^t* *m invmx R *m H *m (F^+j).

  Lemma obsv_gram0 : obsv_gram 0 = 0.
  Proof.
    by rewrite /obsv_gram big_ord0.
  Qed.

  Lemma obsv_gram_recr k :
    obsv_gram k.+1 =
      obsv_gram k +
      (F^+k)^t* *m H^t* *m invmx R *m H *m (F^+k).
  Proof.
    by rewrite /obsv_gram big_ord_recr.
  Qed.

  Lemma obsv_gram_term_psd (j : nat) :
    psd ((F^+j)^t* *m H^t* *m invmx R *m H *m (F^+j)).
  Proof.
    have invR_psd : psd (invmx R) := pd_psd (pd_inv R_pd).
    have -> :
      (F^+j)^t* *m H^t* *m invmx R *m H *m (F^+j) =
      (H *m F^+j)^t* *m invmx R *m (H *m F^+j).
      by rewrite trmxC_mul -!mulmxA.
    exact: psd_congr invR_psd.
  Qed.

  Lemma obsv_gram_psd k : psd (obsv_gram k).
  Proof.
    elim: k => [|k IH].
      by rewrite obsv_gram0; exact: psd0.
    by rewrite obsv_gram_recr; exact: psd_add IH (obsv_gram_term_psd k).
  Qed.

  (* Квадратичная форма грамиана наблюдаемости в точке v *)
  Lemma obsv_gram_qform k (v : 'cV[ℂ]_n) :
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

  (*
    Основной результат: при наблюдаемости `obsv_gram n` положительно определён.

    ([kailath2000], App. C, § C.4)
  *)
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
    (* каждый член >= 0 *)
    have term_ge0 : forall j : 'I_n,
      0 <= \tr ((H *m F^+j *m v)^t* *m invmx R *m (H *m F^+j *m v)).
      move=> j; apply: psd_tr_ge0.
      exact: psd_congr psd_invR.
    (* по наблюдаемости: ∃ j : 'I_n, H ⋅ F^j ⋅ v != 0 *)
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

  (*
    Грамиан управляемости.

    ([kailath2000], App. C, § C.3)
  *)
  Definition ctrl_gram (k : nat) : 'M[ℂ]_n :=
    \sum_(j < k) F^+j *m G *m Q *m G^t* *m (F^+j)^t*.

  Lemma ctrl_gram0 : ctrl_gram 0 = 0.
  Proof.
    by rewrite /ctrl_gram big_ord0.
  Qed.

  Lemma ctrl_gram_recr k :
    ctrl_gram k.+1 =
      ctrl_gram k + F^+k *m G *m Q *m G^t* *m (F^+k)^t*.
  Proof.
    by rewrite /ctrl_gram big_ord_recr.
  Qed.

  Lemma ctrl_gram_term_psd (j : nat) :
    psd (F^+j *m G *m Q *m G^t* *m (F^+j)^t*).
  Proof.
    have -> :
      F^+j *m G *m Q *m G^t* *m (F^+j)^t* =
      (F^+j *m G) *m Q *m (F^+j *m G)^t*.
      by rewrite trmxC_mul !mulmxA.
    exact: psd_lcongr Q_psd.
  Qed.

  Lemma ctrl_gram_psd k :
    psd (ctrl_gram k).
  Proof.
    elim: k => [|k IH].
      by rewrite ctrl_gram0; exact: psd0.
    by rewrite ctrl_gram_recr; exact: psd_add IH (ctrl_gram_term_psd k).
  Qed.

  (* Квадратичная форма грамиана управляемости в точке `v`. *)
  Lemma ctrl_gram_qform k (v : 'cV[ℂ]_n) :
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

  (*
    Положительная определённость грамиана управляемости при управляемости [F, G]
    и положительной определённости `Q`.

    ([kailath2000], App. C, § C.3)
  *)
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
      exact: psd_congr Q_psd.
    (* по управляемости: ∃ j, G† (F^j)† v != 0 *)
    have [j0 Hj0] : exists j : 'I_n, G^t* *m (F^+j)^t* *m v != 0.
      case: (boolP [forall j : 'I_n, G^t* *m (F^+j)^t* *m v == 0])
          => [/forallP Hall|HnotAll].
      - exfalso.
        have vT_zero : v^t* = 0.
          apply: Hctrl => i.
          rewrite /ctrl_block.
          have /eqP eq := Hall i.
          have eqT := congr1 (fun M : 'M[ℂ]_(m, 1) => M^t*) eq.
          rewrite trmxC0 in eqT.
          rewrite !trmxC_mul !trmxCK in eqT.
          exact: eqT.
        apply: (negP vNZ); apply/eqP.
        have := congr1 (fun M : 'M[ℂ]_(1, n) => M^t*) vT_zero.
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

  (*
    Тождество сдвига для грамиана управляемости.
    `ctrl_gram (k+1) = G Q G† + F (ctrl_gram k) F†`.
  *)
  Lemma ctrl_gram_shift k :
    ctrl_gram k.+1 = G *m Q *m G^t* + F *m ctrl_gram k *m F^t*.
  (* Доказывается индукцией по k (избегая работы с `lift ord0 i`). *)
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

  (* Равномерная оценка следа грамиана управляемости. *)
  Lemma ctrl_gram_tr_bound (Fc : frob_sq F < 1) (k : nat) :
    \tr (ctrl_gram k) <= \tr (G *m Q *m G^t*) / (1 - frob_sq F).
  (*
    При сжатии по норме Фробениуса `frob_sq F < 1`:
    `tr(ctrl_gram k) <= tr(G Q Gconj) / (1 - frob_sq F)` равномерно по `k`.
    Доказывается индукцией: из тождества сдвига
    `ctrl_gram (k+1) = G Q Gconj + F (ctrl_gram k) Fconj` и линейности следа
    получаем рекуррентность
    ```
    t_(k+1) = tr T + tr(F (ctrl_gram k) Fconj)
           <= tr T + frob_sq F * t_k (tr_conj_frob_le)
    ```
    с инвариантом (неподвижной точкой) `B = tr T / (1 - frob_sq F)`, т.к.
    `tr T + frob_sq F * B = B`.
  *)
  Proof.
    have trT_ge0 : 0 <= \tr (G *m Q *m G^t*).
      by apply: psd_tr_ge0; apply: psd_lcongr; exact: Q_psd.
    set T := G *m Q *m G^t*.
    have d_gt0 : 0 < 1 - frob_sq F by rewrite subr_gt0.
    have d_neq0 : (1 - frob_sq F) != 0 by rewrite gt_eqF.
    have key : \tr T + frob_sq F * (\tr T / (1 - frob_sq F))
            = \tr T / (1 - frob_sq F).
      apply: (mulIf d_neq0).
      rewrite divfK // mulrDl -mulrA divfK // mulrBr mulr1.
      by rewrite [\tr T * frob_sq F]mulrC subrK.
    elim: k => [|k IH].
      rewrite ctrl_gram0 mxtrace0.
      by apply: divr_ge0; [exact: trT_ge0 | exact: ltW d_gt0].
    rewrite ctrl_gram_shift mxtraceD -/T.
    rewrite -[X in _ <= X]key lerD2l.
    apply: (@le_trans _ _ (frob_sq F * \tr (ctrl_gram k))).
      by apply: tr_conj_frob_le; exact: ctrl_gram_psd k.
    apply: ler_pM => //.
    - exact: frob_sq_ge0.
    - by apply: psd_tr_ge0; exact: ctrl_gram_psd k.
  Qed.

  (* Верхняя оценка итерации Риккати через `K=0`. *)
  Lemma riccati_iter_le_ctrl_gram (k : nat) :
    psd_le (iter k (riccati_step F G H Q R) 0) (ctrl_gram k).
  (*
    Идея: для оптимальной (калмановской) оценки `update_cov P_pred <= P_pred`
    (это `update_cov_le`). Следовательно, по тождеству сдвига:
    ```
    riccati_step P <= predict_cov P
                   <= predict_cov (ctrl_gram k) (IH)
                    = G Q G† + F (ctrl_gram k) F†
                    = ctrl_gram (k+1)
    ```.
  *)
  Proof.
    elim: k => [|k IH].
      rewrite /= ctrl_gram0.
      apply: psd_le_refl; exact: psd0.
    rewrite [iter k.+1 _ _]/=.
    set Pk := iter k _ _.
    have Pk_psd : psd Pk := riccati_iter_from_0_psd F G H Q_psd R_pd k.
    have Ppred_psd : psd (predict_cov F G Q Pk) := predict_cov_psd F G Q_psd Pk_psd.
    (* Шаг 1: riccati_step Pk <= predict_cov Pk *)
    have step1 : psd_le (riccati_step F G H Q R Pk) (predict_cov F G Q Pk).
      rewrite /psd_le /riccati_step.
      apply: (update_cov_le H R_pd Ppred_psd).
    (* Шаг 2: predict_cov Pk <= predict_cov (ctrl_gram k) *)
    have step2 : psd_le (predict_cov F G Q Pk) (predict_cov F G Q (ctrl_gram k)).
      apply: (predict_cov_mono F G Q IH).
    (* Шаг 3: predict_cov (ctrl_gram k) = ctrl_gram k.+1 *)
    have step3 : predict_cov F G Q (ctrl_gram k) = ctrl_gram k.+1.
      by rewrite /predict_cov ctrl_gram_shift addrC.
    rewrite -step3.
    exact: psd_le_trans step1 step2.
  Qed.

End ObsvBound.
