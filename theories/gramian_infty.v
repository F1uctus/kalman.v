(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Бесконечные грамианы наблюдаемости и управляемости.

  При сжатии по норме Фробениуса $"frob_sq" F < 1$ определены бесконечные
  грамианы как пределы решений соответствующих уравнений Ляпунова:

  $"obsv_gram_infty" F H := "lyap_sol" (F†) (H† H) <=> X = F† X F + H† H$

  $"ctrl_gram_infty" F G Q := "lyap_sol" F (G Q G†) <=> X = F X F† + G Q G†$

  Положительная определённость бесконечных грамианов выводится из положительной
  определённости их конечных предшественников
  (`obsv_gram_pd_of_observable`, `ctrl_gram_pd_of_controllable` из `obsv_bound.v`)
  и нижней оценки через `mx_mono_lim_ge_term`
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import mxnotation mxdefinite mxloewner spectral mxfrob
  mxherm mxtopo mxmonotone lyapunov kalman obsv_bound.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* Бесконечные грамианы *)
Section GramianInf.

  (* Каноническое вложение ℝ ↪ ℂ. *)
  Variables (ℝ : realType) (ℂ : numClosedFieldType).
  Variable r2c : {rmorphism ℝ -> ℂ}.
  Variable c2r : ℂ -> ℝ.
  Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
  Hypothesis r2cK : cancel r2c c2r.
  Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
  Hypothesis c2r_continuous : continuous (c2r : ℂ -> ℝ).
  Hypothesis r2c_continuous : continuous (r2c : ℝ -> ℂ).

  Variables (m n p : nat).

  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variable (Q : 'M[ℂ]_m).
  Hypothesis Q_psd : psd Q.
  Hypothesis F_contract : frob_sq F < 1.

  (* $"frob_sq" F† = "frob_sq" F < 1$. *)
  Lemma F_trmxC_contract : frob_sq (F^t*) < 1.
  Proof.
    by rewrite frob_sq_trmxC.
  Qed.

  Lemma GQGt_psd : psd (G *m Q *m G^t*).
  Proof.
    exact: psd_lcongr Q_psd.
  Qed.

  Lemma HtH_psd : psd (H^t* *m H).
  Proof.
    have := psd_frob H.
    by rewrite /frob_sq.
  Qed.

  (*
    Бесконечный грамиан управляемости.

    Решение уравнения Ляпунова $W_c = F W_c F† + G Q G†$, построенное как предел
    частичных сумм (`lyap_sol`).

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)
  Definition ctrl_gram_infty : 'M[ℂ]_n :=
    lyap_sol F (G *m Q *m G^t*).

  Theorem ctrl_gram_infty_psd :
    psd ctrl_gram_infty.
  Proof.
    exact: (lyap_sol_psd ler_r2c c2rK c2r_continuous r2c_continuous
            GQGt_psd F_contract).
  Qed.

  (*
    Бесконечный грамиан удовлетворяет уравнению Ляпунова.

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)
  Theorem ctrl_gram_infty_fix :
    ctrl_gram_infty = F *m ctrl_gram_infty *m F^t* + G *m Q *m G^t*.
  Proof.
    rewrite /ctrl_gram_infty.
    exact: (lyap_sol_fix ler_r2c c2rK r2c_continuous
            GQGt_psd F_contract).
  Qed.

  (*
    Конечный грамиан управляемости как частичная сумма Ляпунова.

    Обе записи задают одну и ту же сумму $sum_(j < k) F^j G Q G† (F†)^j$;
    равенство сводится к перестановке скобок в каждом слагаемом.
  *)
  Lemma ctrl_gram_eq_partial k :
    ctrl_gram F G Q k = lyap_partial F (G *m Q *m G^t*) k.
  Proof.
    rewrite /ctrl_gram /riccati_def.ctrl_gram /lyap_partial.
    apply: eq_bigr=> j _.
    by rewrite trmxCX !mulmxA.
  Qed.

  (* Конечный грамиан не превосходит бесконечный в порядке Лёвнера. *)
  Lemma ctrl_gram_le_infty k :
    psd_le (ctrl_gram F G Q k) ctrl_gram_infty.
  Proof.
    rewrite ctrl_gram_eq_partial /ctrl_gram_infty /lyap_sol.
    apply: (mx_mono_lim_ge_term ler_r2c c2rK c2r_continuous r2c_continuous).
    - by move=> k0; apply: lyap_partial_psd; exact: GQGt_psd.
    - by move=> k0; apply: lyap_partial_mono; exact: GQGt_psd.
    - move=> k0; apply: lyap_partial_le_bnd; [exact: GQGt_psd | exact: F_contract].
  Qed.

  (*
    Положительная определённость бесконечного грамиана управляемости.

    - @kailath2000[App. C, § C.3].
  *)
  Theorem ctrl_gram_infty_pd_of_controllable :
    controllable F G -> pd Q -> pd ctrl_gram_infty.
  Proof.
    move=> Hctrl Q_pd.
    apply: (psd_le_pd (A := ctrl_gram F G Q n)).
    - exact: ctrl_gram_le_infty.
    - exact: ctrl_gram_pd_of_controllable Q_psd Hctrl Q_pd.
  Qed.

  (*
    Грамиан наблюдаемости в пределе - решение уравнения Ляпунова
    $W_o = F† W_o F + H† H$.

    - @kailath2000[App. C, § C.4].
  *)
  Definition obsv_gram_infty : 'M[ℂ]_n :=
    lyap_sol (F^t*) (H^t* *m H).

  Theorem obsv_gram_infty_psd : psd obsv_gram_infty.
  Proof.
    exact: (lyap_sol_psd ler_r2c c2rK c2r_continuous r2c_continuous
            HtH_psd F_trmxC_contract).
  Qed.

  Theorem obsv_gram_infty_fix :
    obsv_gram_infty = F^t* *m obsv_gram_infty *m F + H^t* *m H.
  Proof.
    rewrite /obsv_gram_infty.
    rewrite {1}(lyap_sol_fix ler_r2c c2rK r2c_continuous
                HtH_psd F_trmxC_contract).
    by rewrite trmxCK.
  Qed.

  (*
    Связь конечного `obsv_gram F H E` (без веса $R^(-1)$) с `lyap_partial`.
    Используем существующий `obsv_gram` с единичной матрицей $E = R$.
  *)
  Lemma obsv_gram_id_eq_partial k :
    obsv_gram F H 1%:M k = lyap_partial (F^t*) (H^t* *m H) k.
  Proof.
    rewrite /obsv_gram /riccati_def.obsv_gram /lyap_partial.
    apply: eq_bigr=> j _.
    rewrite invmx1 mulmx1 trmxCX.
    have ->: ((F^t*)^t*)^+j = F^+j by rewrite trmxCK.
    by rewrite mulmxA.
  Qed.

  (* Конечный Грамиан наблюдаемости (с $R = E$) <= бесконечный. *)
  Lemma obsv_gram_id_le_infty k :
    psd_le (obsv_gram F H 1%:M k) obsv_gram_infty.
  Proof.
    rewrite obsv_gram_id_eq_partial /obsv_gram_infty /lyap_sol.
    apply: (mx_mono_lim_ge_term ler_r2c c2rK c2r_continuous r2c_continuous).
    - by move=> k0; apply: lyap_partial_psd; exact: HtH_psd.
    - by move=> k0; apply: lyap_partial_mono; exact: HtH_psd.
    - move=> k0; apply: lyap_partial_le_bnd; [exact: HtH_psd | exact: F_trmxC_contract].
  Qed.

  (*
    Положительная определённость бесконечного грамиана наблюдаемости.

    - @kailath2000[App. C, § C.4].
  *)
  Theorem obsv_gram_infty_pd_of_observable :
    observable F H -> pd obsv_gram_infty.
  Proof.
    move=> Hobs.
    apply: (psd_le_pd (A := obsv_gram F H 1%:M n)).
    - exact: obsv_gram_id_le_infty.
    - exact: obsv_gram_pd_of_observable (pd1 ℂ p) Hobs.
  Qed.

End GramianInf.

(*
  Грамиан наблюдаемости с произвольным неотрицательно определённым весом $W$:

  $"obsv_gram_infty_w" F W := "lyap_sol" (F†) W <=> X = F† X F + W$

  Обобщение `obsv_gram_infty`
  (который = $"obsv_gram_infty_w" F (H† H)$ по определению): вес $W$ отвязан от
  формы $M† M$. Нужен для меры `O_P`, вес которой $W := H† ("invmx" R) H$ не
  имеет вида $M† M$.
*)
Section GramianInfWeighted.

  (* Каноническое вложение $ℝ ↪ ℂ$. *)
  Variables (ℝ : realType) (ℂ : numClosedFieldType).
  Variable r2c : {rmorphism ℝ -> ℂ}.
  Variable c2r : ℂ -> ℝ.
  Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
  Hypothesis r2cK : cancel r2c c2r.
  Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
  Hypothesis c2r_continuous : continuous (c2r : ℂ -> ℝ).
  Hypothesis r2c_continuous : continuous (r2c : ℝ -> ℂ).

  Variable (n : nat).
  Variables (F W : 'M[ℂ]_n).
  Hypothesis W_psd : psd W.
  Hypothesis F_contract : frob_sq F < 1.

  Definition obsv_gram_infty_w : 'M[ℂ]_n := lyap_sol (F^t*) W.

  (* $"frob_sq" F† = "frob_sq" F < 1$. *)
  Lemma F_trmxC_contract_w : frob_sq (F^t*) < 1.
  Proof. by rewrite frob_sq_trmxC. Qed.

  Theorem obsv_gram_infty_w_psd : psd obsv_gram_infty_w.
  Proof.
    exact: (lyap_sol_psd ler_r2c c2rK c2r_continuous r2c_continuous
            W_psd F_trmxC_contract_w).
  Qed.

  Theorem obsv_gram_infty_w_fix :
    obsv_gram_infty_w = F^t* *m obsv_gram_infty_w *m F + W.
  Proof.
    rewrite /obsv_gram_infty_w.
    rewrite {1}(lyap_sol_fix ler_r2c c2rK r2c_continuous
                W_psd F_trmxC_contract_w).
    by rewrite trmxCK.
  Qed.

End GramianInfWeighted.

(*
  Положительная определённость грамиана управляемости замкнутого контура, из
  управляемости исходной пары.
*)
Section ClosedLoopCtrlGramPd.


  Variable (ℂ : numClosedFieldType).

  Variable (N p : nat).

  Variables (A : 'M[ℂ]_N) (Kp : 'M[ℂ]_(N, p)) (Hm : 'M[ℂ]_(p, N)).
  Variables (Z : 'M[ℂ]_N) (R : 'M[ℂ]_p).

  Hypothesis Zpsd : psd Z.
  Hypothesis R_pd : pd R.

  Local Notation Fp := (A - Kp *m Hm).
  Local Notation W := (Kp *m R *m Kp^t* + Z).

  (*
    Критерий положительной определённости для неподвижной точки Ляпунова
    замкнутого контура коррекции по выходу $F_p = A - K_p H$ с весом
    $W = K_p R K_p† + Z$, выводимый из полной управляемости исходной пары
    $(A, Z)$
    (а не замкнутого контура - коррекция по выходу управляемость не сохраняет).

    - @kailath2000[App. D, Lemma D.1.2 v "Properties of the Lyapunov Equation"]:
      управляемость пары $(F, Q^(1/2))$ влечёт положительную определённость
      решения;
    - @kailath2000[App. E, Theorem E.6.2 "Positive Definite Solution"]Ж тот же
      вывод на уровне ДАУР.
  *)
  Lemma controllable_oi_gram_pd (P : 'M[ℂ]_N) :
    psd P ->
    P = Fp *m P *m Fp^t* + W ->
    controllable A Z ->
    pd P.
  (*
    Схема: тождество Ляпунова даёт конечную частичную сумму
    $"lyap_partial" F_p W N prec.eq P$ (`lyap_partial_fix_le`); на ядре $P$
    форма частичной суммы обращается в ноль, откуда $W (F_p†)^j v = 0$ для всех
    $j < N$. Так как $W u = 0 => K_p† u = 0$ ($R$ положительно определена) и
    $Z u = 0$ ($Z$ неотрицательно определена), а $K_p† u = 0 => F_p† u = A† u$,
    по индукции $(F_p†)^j v = (A†)^j v$, значит $Z (A†)^j v = 0$;
    транспонирование даёт ядро управляемости $(A, Z)$, откуда $v = 0$ - т.е. $P$
    положительно определена.
  *)
  Proof.
    move=> Ppsd Pfix Hctrl.
    have Wpsd : psd W.
      apply: psd_add; last exact: Zpsd.
      exact: psd_lcongr Kp (pd_psd R_pd).
    (*
      Извлечение $K_p† u = 0$ и $Z u = 0$ из $W u = 0$
      (разложение неотрицательно определённого веса).
    *)
    have splitWu : forall u : 'cV[ℂ]_N, W *m u = 0 ->
        Kp^t* *m u = 0 /\ Z *m u = 0.
      move=> u Wu0.
      have qf0' : \tr (u^t* *m W *m u) = 0 by rewrite -mulmxA Wu0 mulmx0 mxtrace0.
      have hKR : 0 <= \tr (u^t* *m (Kp *m R *m Kp^t*) *m u)
        by case: (psd_lcongr Kp (pd_psd R_pd)) => _ /(_ u).
      have hZ : 0 <= \tr (u^t* *m Z *m u) by case: Zpsd => _ /(_ u).
      have split0 : \tr (u^t* *m (Kp *m R *m Kp^t*) *m u) = 0
                /\ \tr (u^t* *m Z *m u) = 0.
        move: qf0'; rewrite mulmxDr mulmxDl mxtraceD => /eqP.
        by rewrite paddr_eq0 // => /andP[/eqP ? /eqP ?].
      split; last exact: psd_qf0_mul0 Zpsd (proj2 split0).
      set uu := Kp^t* *m u.
      have qfu : \tr (uu^t* *m R *m uu) = 0.
        by rewrite -(proj1 split0) /uu trmxC_mul trmxCK !mulmxA.
      exact: pd_qf0_col0 R_pd qfu.
    split; first exact: (proj1 Ppsd).
    move=> v vNZ.
    rewrite lt0r; apply/andP; split; last by case: Ppsd => _ /(_ v).
    apply/negP=> /eqP qf0.
    (*
      Конечная Лёвнер-оценка: lyap_partial Fp W N <= P, форма при v обращается в
      ноль.
    *)
    have Lle : psd_le (lyap_partial Fp W N) P
      := lyap_partial_fix_le Ppsd Pfix N.
    have Lpsd : psd (lyap_partial Fp W N) := lyap_partial_psd Fp Wpsd N.
    have Lqf0 : \tr (v^t* *m lyap_partial Fp W N *m v) = 0.
      have [_ hge] : psd (P - lyap_partial Fp W N) := Lle.
      apply/eqP; rewrite eq_le; apply/andP; split; last by case: Lpsd => _ /(_ v).
      have h := hge v.
      by rewrite mulmxBr mulmxBl raddfB /= qf0 sub0r oppr_ge0 in h.
    rewrite lyap_partial_qform in Lqf0.
    (* Обращение в ноль $W$-формы на сопряжённых итерациях $(F_p†)^j v$. *)
    have ge0 : forall i : 'I_N,
        0 <= \tr (((Fp^t*)^+i *m v)^t* *m W *m ((Fp^t*)^+i *m v)).
      by move=> i; case: Wpsd => _ /(_ ((Fp^t*)^+i *m v)).
    have termW0 : forall j : 'I_N,
        \tr (((Fp^t*)^+j *m v)^t* *m W *m ((Fp^t*)^+j *m v)) = 0.
      move=> j; apply/eqP; rewrite eq_le; apply/andP; split; last exact: ge0 j.
      rewrite -Lqf0 (bigD1 j) //= lerDl.
      by apply: sumr_ge0 => i _; exact: ge0 i.
    have Wu0 : forall j, (j < N)%N -> W *m ((Fp^t*)^+j *m v) = 0.
      by move=> j hj; exact: psd_qf0_mul0 Wpsd (termW0 (Ordinal hj)).
    (* (Fp†)^j v = (A†)^j v (распространение Kp† (A†)^j v = 0). *)
    have keyEq : forall j, (j <= N)%N -> (Fp^t*)^+j *m v = (A^t*)^+j *m v.
      elim => [|j IH] hj; first by rewrite !expr0.
      have IHj : (Fp^t*)^+j *m v = (A^t*)^+j *m v := IH (ltnW hj).
      have WFj : W *m ((A^t*)^+j *m v) = 0 by rewrite -IHj; exact: Wu0 j hj.
      have KpAj : Kp^t* *m ((A^t*)^+j *m v) = 0 := proj1 (splitWu _ WFj).
      rewrite exprS -mulmxA IHj.
      have FpT : Fp^t* = A^t* - Hm^t* *m Kp^t* by rewrite trmxCB trmxC_mul.
      rewrite FpT mulmxBl -mulmxA KpAj mulmx0 subr0.
      by rewrite exprS -mulmxA.
    have WAj : forall i : 'I_N, W *m ((A^t*)^+i *m v) = 0.
      move=> i; rewrite -(keyEq i (ltnW (ltn_ord i))).
      exact: Wu0 i (ltn_ord i).
    (*
      Перенос на исходную пару $(A, Z)$: транспонирование даёт ядро
      управляемости.
    *)
    have vT0 : v^t* = 0.
      apply: Hctrl => i.
      have e : Z *m ((A^t*)^+i *m v) = 0 := proj2 (splitWu _ (WAj i)).
      have et : (Z *m ((A^t*)^+i *m v))^t* = 0 by rewrite e trmxC0.
      rewrite trmxC_mul trmxC_mul trmxCX trmxCK -(proj1 Zpsd) -mulmxA in et.
      by rewrite /ctrl_block et.
    have v0 : v = 0 by rewrite -(trmxCK v) vT0 trmxC0.
    by rewrite v0 eqxx in vNZ.
  Qed.

End ClosedLoopCtrlGramPd.
