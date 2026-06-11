(*
  Единственность положительно определённой неподвижной точки апостериорного шага
  Риккати - единственность стабилизирующего решения ДАУР, без внешних гипотез о
  стабилизирующем усилении.
  - @kailath2000[App. E, Lemma E.4.3 "Unique Stabilizing Solution"].

  См. Lemma 14.4.1 "Local Identities" для разности двух решений:
  $M_1 - M_2 = "Fp"(M_1) (M_1 - M_2) "Fp"(M_2)†$, где
  $"Fp"(M) = F - F "Kf"(M) H$ - предсказательный замкнутый контур. Каждый
  $"Fp"(M_i)$ устойчив по Шуру (`lyap_inv_spec_rad`): положительно определённая
  предсказанная неподвижная точка с положительно определённым весом
  $K_p R K_p† + G Q G†$. Отсюда `lyap_two_sided_zero_schur` даёт
  $M_1 - M_2 = 0$.
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral archimedean.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite mxloewner mxfrob
  kalman spec_rad detectability lyap_inv.

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
  Variables (Q : 'M[ℂ]_m) (R : 'M[ℂ]_p).
  Hypothesis Q_psd : psd Q.
  Hypothesis R_pd : pd R.

  (*
    Стабилизируемость пары процессного шума $(F, G Q^(1/2))$
    (через неотрицательно определённый вес $G Q G†$). Достаточна для
    устойчивости предсказательного контура `Fp` и единственности
    стабилизирующего (неотрицательно определённого) решения ДАУР.

    - @kailath2000[App. E, Theorem E.5.1 "Algebraic Riccati Equation"].
  *)
  Hypothesis FG_stab : stabilizable F (G *m Q *m G^t*).

  Local Notation Kf M := (filter_gain H R M).
  Local Notation Kp M := (F *m filter_gain H R M).
  Local Notation Fp M := (F - F *m filter_gain H R M *m H).
  Local Notation predM M := (predict_cov F G Q (update_cov H R M)).

  (*
    Тождество для коэффициента усиления: $"Fp"(M) M H† = "Kp"(M) R$
    (ср. `dare.Fp_Ppss_Ht`).
  *)
  Lemma Fp_M_Ht (M : 'M[ℂ]_n) :
    psd M ->
    (F - F *m Kf M *m H) *m M *m H^t* = F *m Kf M *m R.
  Proof.
    move=> Mpsd.
    have gsp := filter_gain_normal_eq H R_pd Mpsd.
    have e : Kf M *m H *m M *m H^t* + Kf M *m R = M *m H^t*.
      by move: gsp; rewrite innov_covE mulmxDr !mulmxA.
    have key : (1%:M - Kf M *m H) *m M *m H^t* = Kf M *m R.
      rewrite !mulmxBl !mul1mx -e.
      by rewrite addrAC subrr add0r.
    have factor : (F - F *m Kf M *m H) *m M *m H^t*
                = F *m ((1%:M - Kf M *m H) *m M *m H^t*).
      by rewrite !mulmxBl !mul1mx mulmxBr !mulmxA.
    by rewrite factor key mulmxA.
  Qed.

  (* $F (E - "Kf" M H) = "Fp" M$ (свёртка усиления). *)
  Lemma F_EmKfH (M : 'M[ℂ]_n) :
    F *m (1%:M - Kf M *m H) = F - F *m Kf M *m H.
  Proof.
    by rewrite mulmxBr mulmx1 mulmxA.
  Qed.

  (*
    Тождество замкнутого контура для предсказанной ковариации, для произвольной
    неотрицательно определённой предсказанной точки M
    (форма Ляпунова замкнутого контура для шага Риккати):
    $P_(i+1) = "Fp" P_i "Fp"† + "Kp" R "Kp"† + G Q G†$.

    - @kailath2000[§ 9.3, Lemma 9.3.2 "Measurement Updates"]: апостериорное
      обновление (9.3.4); форма Джозефа, эквивалентная `update_cov`, первый шаг
      в доказательстве;
    - @kailath2000[§ 9.3, Lemma 9.3.3 "Time Updates"]: шаг предсказания
      (9.3.8 при S=0), т.е. `predict_cov`; в связке с 9.3.2 даёт закрытую форму;
    - @kailath2000[§ 9.2, Theorem 9.2.1 "The Innovations Recursions"]:
      стандартная рекурсия Риккати (9.2.33); алгебраически эквивалентно тому же
      шагу;
    - @kailath2000[Prob. 14.4 "Boundedness of P_i for Arbitrary P_0"]: ч.(a) -
      уравнение Ляпунова замкнутого контура $(F - K H) P (F - K H)† + dots$ для
      наблюдателя с произвольным стабилизирующим $K$; при оптимальном $"Kf"$
      совпадает с тождеством.
  *)
  Lemma pred_closed_loop_id (M : 'M[ℂ]_n) :
    psd M ->
    predict_cov F G Q (update_cov H R M)
    = (F - F *m Kf M *m H) *m M *m (F - F *m Kf M *m H)^t*
      + F *m Kf M *m R *m (F *m Kf M)^t* + G *m Q *m G^t*.
  Proof.
    move=> Mpsd.
    rewrite !predict_covE -(joseph_formE H R_pd Mpsd) /joseph_form.
    rewrite mulmxDr mulmxDl; congr (_ + _ + _).
    - by rewrite -F_EmKfH trmxC_mul !mulmxA.
    - by rewrite trmxC_mul !mulmxA.
  Qed.

  (* Транспонированное усиление, тождество $H M A_2† = R ("Kp" M)†$. *)
  Lemma Ht_M_Fp (M : 'M[ℂ]_n) :
    psd M ->
    H *m M *m (F - F *m Kf M *m H)^t* = R *m (F *m Kf M)^t*.
  Proof.
    move=> Mpsd.
    have lhs : H *m M *m (F - F *m Kf M *m H)^t*
            = ((F - F *m Kf M *m H) *m M *m H^t*)^t*.
      by rewrite !trmxC_mul trmxCK -Mpsd.1 !mulmxA.
    have rhs : R *m (F *m Kf M)^t* = ((F *m Kf M) *m R)^t*.
      by rewrite !trmxC_mul -R_pd.1.
    by rewrite lhs rhs (Fp_M_Ht Mpsd).
  Qed.

  (*
    Разностное тождество для двух неотрицательно определённых предсказанных
    неподвижных точек (локальное тождество для разности двух решений):
    $M_1 - M_2 = "Fp"(M_1) (M_1 - M_2) "Fp"(M_2)†$.
    - @kailath2000[§ 14.4, Lemma 14.4.1 "Local Identities"].
  *)
  Lemma pred_diff_id (M1 M2 : 'M[ℂ]_n) :
    psd M1 -> psd M2 ->
    M1 = predict_cov F G Q (update_cov H R M1) ->
    M2 = predict_cov F G Q (update_cov H R M2) ->
    M1 - M2
    = (F - F *m Kf M1 *m H) *m (M1 - M2) *m (F - F *m Kf M2 *m H)^t*.
  Proof.
    move=> p1 p2 f1 f2.
    set A1 := F - F *m Kf M1 *m H.
    set A2 := F - F *m Kf M2 *m H.
    set P1 := F *m Kf M1.
    set P2 := F *m Kf M2.
    have c1 : A1 *m M1 *m H^t* = P1 *m R := Fp_M_Ht p1.
    have c2 : H *m M2 *m A2^t* = R *m P2^t* := Ht_M_Fp p2.
    have dA : A1 - A2 = P2 *m H - P1 *m H.
      by rewrite /A1 /A2 opprB addrC addrA subrK.
    have dA2 : A2 - A1 = P1 *m H - P2 *m H.
      by rewrite -(opprB A1 A2) dA opprB.
    have id1 : M1 = A1 *m M1 *m A1^t* + P1 *m R *m P1^t* + G *m Q *m G^t*.
      by rewrite {1}f1 pred_closed_loop_id.
    have id2 : M2 = A2 *m M2 *m A2^t* + P2 *m R *m P2^t* + G *m Q *m G^t*.
      by rewrite {1}f2 pred_closed_loop_id.
    (* R1: A1 M2 A1† − A1 M2 A2† = P1 R P2† − P1 R P1†. *)
    have R1 : A1 *m M1 *m A1^t* - A1 *m M1 *m A2^t*
            = P1 *m R *m P2^t* - P1 *m R *m P1^t*.
      rewrite -mulmxBr -trmxCB dA trmxCB !trmxC_mul mulmxBr !mulmxA !c1.
      by [].
    (* R2: A2 M2 A2† − A1 M2 A2† = P1 R P2† − P2 R P2†. *)
    have R2 : A2 *m M2 *m A2^t* - A1 *m M2 *m A2^t*
            = P1 *m R *m P2^t* - P2 *m R *m P2^t*.
      rewrite -mulmxBl -mulmxBl dA2 mulmxBl mulmxBl.
      have f2a : P1 *m H *m M2 *m A2^t* = P1 *m (H *m M2 *m A2^t*).
        by rewrite !mulmxA.
      have f2b : P2 *m H *m M2 *m A2^t* = P2 *m (H *m M2 *m A2^t*).
        by rewrite !mulmxA.
      by rewrite f2a f2b c2 !mulmxA.
    (* key1: A1 M2 A1† + P1 R P1† = A1 M2 A2† + P1 R P2†. *)
    have key1 : A1 *m M1 *m A1^t* + P1 *m R *m P1^t*
              = A1 *m M1 *m A2^t* + P1 *m R *m P2^t*.
      by apply/eqP; rewrite -subr_eq0 opprD addrACA R1 addrA subrK subrr.
    have key2 : A2 *m M2 *m A2^t* + P2 *m R *m P2^t*
              = A1 *m M2 *m A2^t* + P1 *m R *m P2^t*.
      by apply/eqP; rewrite -subr_eq0 opprD addrACA R2 addrA subrK subrr.
    have M1e : M1 = A1 *m M1 *m A2^t*
                  + (P1 *m R *m P2^t* + G *m Q *m G^t*).
      by rewrite {1}id1 key1 -addrA.
    have M2e : M2 = A1 *m M2 *m A2^t*
                  + (P1 *m R *m P2^t* + G *m Q *m G^t*).
      by rewrite {1}id2 key2 -addrA.
    clearbody A1 A2 P1 P2.
    rewrite {1}M1e {1}M2e mulmxBr mulmxBl.
    by rewrite opprD addrACA subrr addr0.
  Qed.

  (*
    Замкнутый контур неотрицательно определённой предсказанной неподвижной точки
    устойчив по Шуру.

    - @kailath2000[App. E, Lemma E.4.2 "Stable F − K_{P,Z} H"].
  *)
  Lemma Fp_schur (M : 'M[ℂ]_n) :
    psd M ->
    M = predict_cov F G Q (update_cov H R M) ->
    spec_rad_lt1 (F - F *m Kf M *m H).
  (*
    Схема: баланс по Ляпунову $M = "Fp" M "Fp"† + W$
    ($W := "Kp" R "Kp"† + G Q G†$, лишь неотрицательно определён) + перенос
    стабилизируемости на коррекцию по выходу (`stabilizable_oi_reduce`) =>
    устойчивость по Шуру через `lyap_inv_spec_rad_stab`.
  *)
  Proof.
    move=> Mpsd Mfix.
    have Mid : M = (F - F *m Kf M *m H) *m M *m (F - F *m Kf M *m H)^t*
                  + (F *m Kf M *m R *m (F *m Kf M)^t* + G *m Q *m G^t*).
      by rewrite {1}Mfix (pred_closed_loop_id Mpsd) -addrA.
    have Wpsd : psd (F *m Kf M *m R *m (F *m Kf M)^t* + G *m Q *m G^t*).
      apply: psd_add; last exact: psd_lcongr G Q_psd.
      exact: psd_lcongr (F *m Kf M) (pd_psd R_pd).
    have Wstab : stabilizable (F - F *m Kf M *m H)
                  (F *m Kf M *m R *m (F *m Kf M)^t* + G *m Q *m G^t*).
      exact: (stabilizable_oi_reduce (Kp := F *m Kf M) (Hm := H)
                (psd_lcongr G Q_psd) R_pd FG_stab).
    exact: lyap_inv_spec_rad_stab Mpsd Wpsd Mid Wstab.
  Qed.

  (*
    Единственность неотрицательно определённой предсказанной неподвижной точки.
  *)
  Lemma pred_fix_unique (M1 M2 : 'M[ℂ]_n) :
    psd M1 -> psd M2 ->
    M1 = predict_cov F G Q (update_cov H R M1) ->
    M2 = predict_cov F G Q (update_cov H R M2) ->
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

    - @kailath2000[App. E, Lemma E.4.3 "Unique Stabilizing Solution"];
    - @kailath2000[App. E, Theorem E.5.1 "Algebraic Riccati Equation"].
  *)
  Theorem riccati_step_fix_unique (L1 L2 : 'M[ℂ]_n) :
    psd L1 -> psd L2 ->
    L1 = riccati_step F G H Q R L1 ->
    L2 = riccati_step F G H Q R L2 ->
    L1 = L2.
  Proof.
    move=> q1 q2 f1 f2.
    have L1u : L1 = update_cov H R (predict_cov F G Q L1)
      by rewrite {1}f1 riccati_stepE.
    have L2u : L2 = update_cov H R (predict_cov F G Q L2)
      by rewrite {1}f2 riccati_stepE.
    have M1psd : psd (predict_cov F G Q L1).
      rewrite !predict_covE; apply: psd_add; last exact: psd_lcongr G Q_psd.
      exact: psd_lcongr F q1.
    have M2psd : psd (predict_cov F G Q L2).
      rewrite !predict_covE; apply: psd_add; last exact: psd_lcongr G Q_psd.
      exact: psd_lcongr F q2.
    have M1fix : predict_cov F G Q L1
              = predict_cov F G Q (update_cov H R (predict_cov F G Q L1)).
      by rewrite -L1u.
    have M2fix : predict_cov F G Q L2
              = predict_cov F G Q (update_cov H R (predict_cov F G Q L2)).
      by rewrite -L2u.
    have HM : predict_cov F G Q L1 = predict_cov F G Q L2
      := pred_fix_unique M1psd M2psd M1fix M2fix.
    by rewrite L1u L2u HM.
  Qed.

End RiccatiUnique.
