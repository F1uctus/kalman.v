(*
  Единственность положительно определённой неподвижной точки апостериорного шага
  Риккати - единственность стабилизирующего решения ДАУР
  ([kailath2000], App. E, Lemma E.4.3), без внешних гипотез о стабилизирующем
  усилении.

  См. Lemma 14.4.1 (Local Identities) для разности двух решений:
  `M2 − M2 = Fp(M2) (M2 − M2) Fp(M2)†`, где `Fp(M) = F − F Kf(M) H` -
  предсказательный замкнутый контур. Каждый `Fp(Mi)` устойчив по Шуру
  (`lyap_inv_spec_rad`): положительно определённая предсказанная неподвижная
  точка с положительно определённым весом `Kp Rn Kp† + G Q G†`. Отсюда
  `lyap_two_sided_zero_schur` даёт `M2 − M2 = 0`.
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral archimedean.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite mxloewner mxfrob.
From Kalman Require Import kalman spec_rad detectability lyap_inv.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section RiccatiUnique.

  Variable (ℂ : numClosedFieldType).
  Hypothesis ℂ_archi : Num.archimedean_axiom ℂ.

  Variables (m p n' : nat).
  Local Notation n := (n'.+1).
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variables (Q : 'M[ℂ]_m) (Rn : 'M[ℂ]_p).
  Hypothesis Q_psd : psd Q.
  Hypothesis Rn_pd : pd Rn.

  (*
    ([kailath2000], App. E, Theorem E.5.1) стабилизируемость пары процессного
    шума `(F, G Q^½)` (через неотрицательно определённый вес `G Q G†`).
    Достаточна для устойчивости предсказательного контура `Fp` и единственности
    стабилизирующего (неотрицательно определённого) решения ДАУР.
  *)
  Hypothesis FG_stab : stabilizable F (G *m Q *m G^t*).

  Local Notation Kf M := (kalman_gain H Rn M).
  Local Notation Kp M := (F *m kalman_gain H Rn M).
  Local Notation Fp M := (F - F *m kalman_gain H Rn M *m H).
  Local Notation predM M := (predict_cov F G Q (update_cov H Rn M)).

  (*
    Тождество для коэффициента усиления: `Fp(M) M H† = Kp(M) Rn`
    (ср. dare.v `Fp_Ppss_Ht`).
  *)
  Lemma Fp_M_Ht (M : 'M[ℂ]_n) :
    psd M ->
    (F - F *m Kf M *m H) *m M *m H^t* = F *m Kf M *m Rn.
  Proof.
    move=> Mpsd.
    have gsp := gain_stationary_point H Rn_pd Mpsd.
    have e : Kf M *m H *m M *m H^t* + Kf M *m Rn = M *m H^t*.
      by move: gsp; rewrite /innov_cov mulmxDr !mulmxA.
    have key : (1%:M - Kf M *m H) *m M *m H^t* = Kf M *m Rn.
      rewrite !mulmxBl !mul1mx -e.
      by rewrite addrAC subrr add0r.
    have factor : (F - F *m Kf M *m H) *m M *m H^t*
                = F *m ((1%:M - Kf M *m H) *m M *m H^t*).
      by rewrite !mulmxBl !mul1mx mulmxBr !mulmxA.
    by rewrite factor key mulmxA.
  Qed.

  (* `F (E − Kf M H) = Fp M` (свёртка усиления). *)
  Lemma F_ImKfH (M : 'M[ℂ]_n) :
    F *m (1%:M - Kf M *m H) = F - F *m Kf M *m H.
  Proof.
    by rewrite mulmxBr mulmx1 mulmxA.
  Qed.

  (*
    Замкнуто-контурное тождество для предсказанной ковариации, для произвольной
    неотрицательно определённой предсказанной точки M
    (замкнуто-контурная форма Ляпунова шага Риккати; ср. Theorem 9.2.1).
    ([kailath2000], § 14.5)
  *)
  Lemma pred_closed_loop_id (M : 'M[ℂ]_n) :
    psd M ->
    predict_cov F G Q (update_cov H Rn M)
    = (F - F *m Kf M *m H) *m M *m (F - F *m Kf M *m H)^t*
      + F *m Kf M *m Rn *m (F *m Kf M)^t* + G *m Q *m G^t*.
  Proof.
    move=> Mpsd.
    rewrite /predict_cov -(joseph_eq_update H Rn_pd Mpsd) /joseph_form.
    rewrite mulmxDr mulmxDl; congr (_ + _ + _).
    - by rewrite -F_ImKfH trmxC_mul !mulmxA.
    - by rewrite trmxC_mul !mulmxA.
  Qed.

  (* Транспонированное усиление, тождество `H M A2† = Rn (Kp M)†`. *)
  Lemma Ht_M_Fp (M : 'M[ℂ]_n) :
    psd M ->
    H *m M *m (F - F *m Kf M *m H)^t* = Rn *m (F *m Kf M)^t*.
  Proof.
    move=> Mpsd.
    have lhs : H *m M *m (F - F *m Kf M *m H)^t*
            = ((F - F *m Kf M *m H) *m M *m H^t*)^t*.
      by rewrite !trmxC_mul trmxCK -Mpsd.1 !mulmxA.
    have rhs : Rn *m (F *m Kf M)^t* = ((F *m Kf M) *m Rn)^t*.
      by rewrite !trmxC_mul -Rn_pd.1.
    by rewrite lhs rhs (Fp_M_Ht Mpsd).
  Qed.

  (*
    Разностное тождество для двух неотрицательно определённых предсказанных
    неподвижных точек (локальное тождество для разности двух решений):
    ```
    M2 − M2 = Fp(M2) (M2 − M2) Fp(M2)†.
    ```
    ([kailath2000], § 14.4, Lemma 14.4.1)
  *)
  Lemma pred_diff_id (M1 M2 : 'M[ℂ]_n) :
    psd M1 -> psd M2 ->
    M1 = predict_cov F G Q (update_cov H Rn M1) ->
    M2 = predict_cov F G Q (update_cov H Rn M2) ->
    M1 - M2
    = (F - F *m Kf M1 *m H) *m (M1 - M2) *m (F - F *m Kf M2 *m H)^t*.
  Proof.
    move=> p1 p2 f1 f2.
    set A1 := F - F *m Kf M1 *m H.
    set A2 := F - F *m Kf M2 *m H.
    set P1 := F *m Kf M1.
    set P2 := F *m Kf M2.
    have c1 : A1 *m M1 *m H^t* = P1 *m Rn := Fp_M_Ht p1.
    have c2 : H *m M2 *m A2^t* = Rn *m P2^t* := Ht_M_Fp p2.
    have dA : A1 - A2 = P2 *m H - P1 *m H.
      by rewrite /A1 /A2 opprB addrC addrA subrK.
    have dA2 : A2 - A1 = P1 *m H - P2 *m H.
      by rewrite -(opprB A1 A2) dA opprB.
    have id1 : M1 = A1 *m M1 *m A1^t* + P1 *m Rn *m P1^t* + G *m Q *m G^t*.
      by rewrite {1}f1 pred_closed_loop_id.
    have id2 : M2 = A2 *m M2 *m A2^t* + P2 *m Rn *m P2^t* + G *m Q *m G^t*.
      by rewrite {1}f2 pred_closed_loop_id.
    (* R1: A1 M2 A1† − A1 M2 A2† = P1 Rn P2† − P1 Rn P1†. *)
    have R1 : A1 *m M1 *m A1^t* - A1 *m M1 *m A2^t*
            = P1 *m Rn *m P2^t* - P1 *m Rn *m P1^t*.
      rewrite -mulmxBr -trmxCB dA trmxCB !trmxC_mul mulmxBr !mulmxA !c1.
      by [].
    (* R2: A2 M2 A2† − A1 M2 A2† = P1 Rn P2† − P2 Rn P2†. *)
    have R2 : A2 *m M2 *m A2^t* - A1 *m M2 *m A2^t*
            = P1 *m Rn *m P2^t* - P2 *m Rn *m P2^t*.
      rewrite -mulmxBl -mulmxBl dA2 mulmxBl mulmxBl.
      have f2a : P1 *m H *m M2 *m A2^t* = P1 *m (H *m M2 *m A2^t*).
        by rewrite !mulmxA.
      have f2b : P2 *m H *m M2 *m A2^t* = P2 *m (H *m M2 *m A2^t*).
        by rewrite !mulmxA.
      by rewrite f2a f2b c2 !mulmxA.
    (* key1: A1 M2 A1† + P1 Rn P1† = A1 M2 A2† + P1 Rn P2†. *)
    have key1 : A1 *m M1 *m A1^t* + P1 *m Rn *m P1^t*
              = A1 *m M1 *m A2^t* + P1 *m Rn *m P2^t*.
      by apply/eqP; rewrite -subr_eq0 opprD addrACA R1 addrA subrK subrr.
    have key2 : A2 *m M2 *m A2^t* + P2 *m Rn *m P2^t*
              = A1 *m M2 *m A2^t* + P1 *m Rn *m P2^t*.
      by apply/eqP; rewrite -subr_eq0 opprD addrACA R2 addrA subrK subrr.
    have M1e : M1 = A1 *m M1 *m A2^t*
                  + (P1 *m Rn *m P2^t* + G *m Q *m G^t*).
      by rewrite {1}id1 key1 -addrA.
    have M2e : M2 = A1 *m M2 *m A2^t*
                  + (P1 *m Rn *m P2^t* + G *m Q *m G^t*).
      by rewrite {1}id2 key2 -addrA.
    clearbody A1 A2 P1 P2.
    rewrite {1}M1e {1}M2e mulmxBr mulmxBl.
    by rewrite opprD addrACA subrr addr0.
  Qed.

  (*
    Замкнутый контур неотрицательно определённой предсказанной неподвижной точки
    устойчив по Шуру.

    ([kailath2000], App. E, Lemma E.4.2)
  *)
  Lemma Fp_schur (M : 'M[ℂ]_n) :
    psd M ->
    M = predict_cov F G Q (update_cov H Rn M) ->
    spec_rad_lt1 (F - F *m Kf M *m H).
  (*
    Схема: баланс по Ляпунову `M = Fp M Fp† + W`
    (`W := Kp Rn Kp† + G Q G†`, лишь неотрицательно определён) + перенос
    стабилизируемости на коррекцию по выходу (`stabilizable_oi_reduce`) =>
    устойчивость по Шуру через `lyap_inv_spec_rad_stab`.
  *)
  Proof.
    move=> Mpsd Mfix.
    have Mid : M = (F - F *m Kf M *m H) *m M *m (F - F *m Kf M *m H)^t*
                  + (F *m Kf M *m Rn *m (F *m Kf M)^t* + G *m Q *m G^t*).
      by rewrite {1}Mfix (pred_closed_loop_id Mpsd) -addrA.
    have Wpsd : psd (F *m Kf M *m Rn *m (F *m Kf M)^t* + G *m Q *m G^t*).
      apply: psd_add; last exact: psd_lcongr G Q_psd.
      exact: psd_lcongr (F *m Kf M) (pd_psd Rn_pd).
    have Wstab : stabilizable (F - F *m Kf M *m H)
                  (F *m Kf M *m Rn *m (F *m Kf M)^t* + G *m Q *m G^t*).
      exact: (stabilizable_oi_reduce (Kp := F *m Kf M) (Hm := H)
                (psd_lcongr G Q_psd) Rn_pd FG_stab).
    exact: lyap_inv_spec_rad_stab Mpsd Wpsd Mid Wstab.
  Qed.

  (*
    Единственность неотрицательно определённой предсказанной неподвижной точки.
  *)
  Lemma pred_fix_unique (M1 M2 : 'M[ℂ]_n) :
    psd M1 -> psd M2 ->
    M1 = predict_cov F G Q (update_cov H Rn M1) ->
    M2 = predict_cov F G Q (update_cov H Rn M2) ->
    M1 = M2.
  Proof.
    move=> q1 q2 f1 f2.
    have s1 : spec_rad_lt1 (F - F *m Kf M1 *m H) := Fp_schur q1 f1.
    have s2 : spec_rad_lt1 (F - F *m Kf M2 *m H) := Fp_schur q2 f2.
    have D : M1 - M2
          = (F - F *m Kf M1 *m H) *m (M1 - M2) *m (F - F *m Kf M2 *m H)^t*
      := pred_diff_id q1 q2 f1 f2.
    have := lyap_two_sided_zero_schur ℂ_archi s1 s2 D.
    by move/eqP; rewrite subr_eq0 => /eqP.
  Qed.

  (*
    Единственность неотрицательно определённой неподвижной точки апостериорного
    шага Риккати.

    ([kailath2000], App. E, Lemma E.4.3; Theorem E.5.1)
  *)
  Theorem riccati_step_fix_unique (L1 L2 : 'M[ℂ]_n) :
    psd L1 -> psd L2 ->
    L1 = riccati_step F G H Q Rn L1 ->
    L2 = riccati_step F G H Q Rn L2 ->
    L1 = L2.
  Proof.
    move=> q1 q2 f1 f2.
    have L1u : L1 = update_cov H Rn (predict_cov F G Q L1)
      by rewrite {1}f1 /riccati_step.
    have L2u : L2 = update_cov H Rn (predict_cov F G Q L2)
      by rewrite {1}f2 /riccati_step.
    have M1psd : psd (predict_cov F G Q L1).
      rewrite /predict_cov; apply: psd_add; last exact: psd_lcongr G Q_psd.
      exact: psd_lcongr F q1.
    have M2psd : psd (predict_cov F G Q L2).
      rewrite /predict_cov; apply: psd_add; last exact: psd_lcongr G Q_psd.
      exact: psd_lcongr F q2.
    have M1fix : predict_cov F G Q L1
              = predict_cov F G Q (update_cov H Rn (predict_cov F G Q L1)).
      by rewrite -L1u.
    have M2fix : predict_cov F G Q L2
              = predict_cov F G Q (update_cov H Rn (predict_cov F G Q L2)).
      by rewrite -L2u.
    have HM : predict_cov F G Q L1 = predict_cov F G Q L2
      := pred_fix_unique M1psd M2psd M1fix M2fix.
    by rewrite L1u L2u HM.
  Qed.

End RiccatiUnique.
