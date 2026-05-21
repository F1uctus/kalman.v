(*  Дискретное уравнение Ляпунова: X = A *m X *m A^t* + Q.                *)
(*                                                                         *)
(*  Под Фробениусовой стабильностью `frob_sq A < 1` и PSD-источником `Q`   *)
(*  частичная сумма `lyap_partial A Q N := \sum_{k<N} A^k Q (Aᶜ)^k`        *)
(*  монотонно возрастает в порядке Лёвнера и равномерно ограничена         *)
(*  скаляром на единичной матрице (как в `ctrl_gram_tr_bound`).            *)
(*  Поэтому через `mx_mono_lim` (Session 11 / 12) определён предел         *)
(*  `lyap_sol_inf A Q` — PSD-неподвижная точка уравнения Ляпунова.         *)
(*                                                                         *)
(*  Единственность *эрмитовых* неподвижных точек разряжается чисто         *)
(*  алгебраически через `predict_diff_frob_bound`: для разности            *)
(*  D = X1 - X2 имеем D = A D A^t* ⇒ frob_sq D ≤ (frob_sq A)^+2 * frob_sq D *)
(*  с коэффициентом, строго меньшим единицы.                               *)
(*                                                                         *)
(*  Этот файл — инфраструктура для Session 14 (Грамианы наблюдаемости/     *)
(*  управляемости в пределе) и Session 17 (определение `OP`).              *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import psd_base psd_order spectral mxfrob mxtopo mxmonotone.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* Транспоз-сопряжение коммутирует со степенью квадратной матрицы:
   (M^+k)ᶜ = (Mᶜ)^+k.  Доказательство — индукцией. *)
Lemma trmxCX (C : numClosedFieldType) m (M : 'M[C]_m) k :
  (M^+k)^t* = (M^t*)^+k.
Proof.
elim: k => [|k IH]; first by rewrite !expr0 trmxC1.
by rewrite exprS trmxC_mul IH exprSr.
Qed.

(* ================================================================== *)
(*  Частичные суммы Ляпунова                                           *)
(* ================================================================== *)

Section LyapPartial.
Variable (C : numClosedFieldType).
Variable (n : nat).
Variables (A Q : 'M[C]_n).
Hypothesis Q_psd : psd Q.

Definition lyap_partial (N : nat) : 'M[C]_n :=
  \sum_(k < N) A^+k *m Q *m (A^t*)^+k.

Lemma lyap_partial0 : lyap_partial 0 = 0.
Proof. by rewrite /lyap_partial big_ord0. Qed.

Lemma lyap_partial_recr N :
  lyap_partial N.+1 =
    lyap_partial N + A^+N *m Q *m (A^t*)^+N.
Proof. by rewrite /lyap_partial big_ord_recr. Qed.

Lemma lyap_partial_term_psd (k : nat) :
  psd (A^+k *m Q *m (A^t*)^+k).
Proof.
have -> :
  A^+k *m Q *m (A^t*)^+k = A^+k *m Q *m (A^+k)^t*.
  by rewrite trmxCX.
exact: psd_mulmx_row Q_psd.
Qed.

Lemma lyap_partial_psd N : psd (lyap_partial N).
Proof.
elim: N => [|N IH]; first by rewrite lyap_partial0; exact: psd0.
by rewrite lyap_partial_recr; exact: psd_add IH (lyap_partial_term_psd N).
Qed.

(* Монотонность по N: разность двух соседних членов PSD. *)
Lemma lyap_partial_mono N : psd_le (lyap_partial N) (lyap_partial N.+1).
Proof.
rewrite /psd_le lyap_partial_recr.
have ->: lyap_partial N + A^+N *m Q *m (A^t*)^+N - lyap_partial N
       = A^+N *m Q *m (A^t*)^+N.
  by rewrite [_ + _ - _]addrAC subrr add0r.
exact: lyap_partial_term_psd.
Qed.

(* Тождество сдвига: lyap_partial N+1 = Q + A * lyap_partial N * A^t*.
   Доказывается индукцией по N (избегая работы с `lift ord0 i`). *)
Lemma lyap_partial_shift N :
  lyap_partial N.+1 = Q + A *m lyap_partial N *m A^t*.
Proof.
elim: N => [|N IH].
  rewrite lyap_partial_recr lyap_partial0 add0r.
  rewrite expr0 mul1mx expr0 mulmx1.
  by rewrite mulmx0 mul0mx addr0.
rewrite lyap_partial_recr {1}IH.
rewrite lyap_partial_recr.
rewrite mulmxDr mulmxDl -addrA.
congr (_ + _); congr (_ + _).
by rewrite exprS exprSr !mulmxA.
Qed.

(* ================================================================== *)
(*  Геометрическая следовая оценка                                     *)
(* ================================================================== *)

(* Под Фробениусовой стабильностью `frob_sq A < 1` след частичной       *)
(* суммы равномерно ограничен `\tr Q / (1 - frob_sq A)`.                *)
Lemma lyap_partial_tr_bound (Ac : frob_sq A < 1) (N : nat) :
  \tr (lyap_partial N) <= \tr Q / (1 - frob_sq A).
Proof.
have trQ_ge0 : 0 <= \tr Q by exact: psd_tr_ge0.
have d_gt0 : 0 < 1 - frob_sq A by rewrite subr_gt0.
have d_neq0 : (1 - frob_sq A) != 0 by rewrite gt_eqF.
have key : \tr Q + frob_sq A * (\tr Q / (1 - frob_sq A))
         = \tr Q / (1 - frob_sq A).
  apply: (mulIf d_neq0).
  rewrite divfK // mulrDl -mulrA divfK // mulrBr mulr1.
  by rewrite [\tr Q * frob_sq A]mulrC subrK.
elim: N => [|N IH].
  rewrite lyap_partial0 mxtrace0.
  by apply: divr_ge0; [exact: trQ_ge0 | exact: ltW d_gt0].
rewrite lyap_partial_shift mxtraceD.
rewrite -[X in _ <= X]key lerD2l.
apply: (@le_trans _ _ (frob_sq A * \tr (lyap_partial N))).
  by apply: tr_conj_frob_le; exact: lyap_partial_psd.
apply: ler_pM => //.
- exact: frob_sq_ge0.
- by apply: psd_tr_ge0; exact: lyap_partial_psd.
Qed.

(* Равномерная PSD-мажоранта на единичной матрице. *)
Definition lyap_bnd : 'M[C]_n :=
  (\tr Q / (1 - frob_sq A)) *: 1%:M.

Lemma lyap_partial_le_bnd (Ac : frob_sq A < 1) N :
  psd_le (lyap_partial N) lyap_bnd.
Proof.
apply: (psd_le_trans (B := \tr (lyap_partial N) *: 1%:M)).
  exact: psd_le_trace_id (lyap_partial_psd N).
rewrite /lyap_bnd.
have trQ_ge0 : 0 <= \tr Q by exact: psd_tr_ge0.
have d_gt0 : 0 < 1 - frob_sq A by rewrite subr_gt0.
apply: psd_le_scale1.
- by apply: ger0_real; apply: psd_tr_ge0; exact: lyap_partial_psd.
- by apply: ger0_real; apply: divr_ge0; [exact: trQ_ge0 | exact: ltW d_gt0].
- exact: lyap_partial_tr_bound.
Qed.

End LyapPartial.

(* ================================================================== *)
(*  Единственность эрмитовых неподвижных точек                          *)
(*  (чисто алгебраическая, без R↔C моста)                              *)
(* ================================================================== *)

Section LyapUnique.
Variable (C : numClosedFieldType).
Variable (n : nat).
Variables (A Q : 'M[C]_n).
Hypothesis A_contract : frob_sq A < 1.

(* Контракционный коэффициент c := (frob_sq A)^+2 строго меньше 1.
   Доказательство: 0 ≤ frob_sq A < 1 ⇒ (frob_sq A)^+2 ≤ frob_sq A < 1. *)
Lemma frob_sq_A_sq_lt1 : (frob_sq A) ^+ 2 < 1.
Proof.
have fa_ge0 : 0 <= frob_sq A := frob_sq_ge0 A.
have fa_le1 : frob_sq A <= 1 := ltW A_contract.
have step : (frob_sq A) ^+ 2 <= frob_sq A.
  rewrite expr2 -[X in _ <= X]mul1r.
  by apply: ler_pM=> //; apply: mulr_ge0.
exact: le_lt_trans step A_contract.
Qed.

(* Эрмитов корень разности неподвижных точек удовлетворяет D = A D A^t*. *)
Lemma lyap_fixed_diff_eq (X1 X2 : 'M[C]_n) :
  X1 = A *m X1 *m A^t* + Q ->
  X2 = A *m X2 *m A^t* + Q ->
  X1 - X2 = A *m (X1 - X2) *m A^t*.
Proof.
move=> eq1 eq2.
rewrite mulmxBr mulmxBl.
have e1 : X1 - Q = A *m X1 *m A^t* by rewrite {1}eq1 addrK.
have e2 : X2 - Q = A *m X2 *m A^t* by rewrite {1}eq2 addrK.
by rewrite -e1 -e2 opprB addrA subrK.
Qed.

(* Единственность эрмитовой неподвижной точки. *)
Theorem lyap_sol_unique (X1 X2 : 'M[C]_n) :
  X1 \is hermsymmx -> X2 \is hermsymmx ->
  X1 = A *m X1 *m A^t* + Q ->
  X2 = A *m X2 *m A^t* + Q ->
  X1 = X2.
Proof.
move=> H1 H2 eq1 eq2.
set D := X1 - X2.
have D_eq : D = A *m D *m A^t* := lyap_fixed_diff_eq eq1 eq2.
have D_herm : D \is hermsymmx.
  apply/is_hermitianmxP; rewrite expr0 scale1r.
  rewrite trmxCB.
  rewrite -(hermsym_eq H1) -(hermsym_eq H2).
  by [].
(* frob_sq D ≤ c * frob_sq D, c < 1 ⇒ frob_sq D = 0. *)
have key : frob_sq D <= (frob_sq A) ^+ 2 * frob_sq D.
  rewrite {1}D_eq.
  exact: predict_diff_frob_bound D_herm.
have c_lt1 : (frob_sq A) ^+ 2 < 1 := frob_sq_A_sq_lt1.
have fd_ge0 : 0 <= frob_sq D := frob_sq_ge0 D.
have fd_eq0 : frob_sq D = 0.
  apply: le_anti; apply/andP; split; last exact: fd_ge0.
  (* frob_sq D - c * frob_sq D ≤ 0 ⇒ (1 - c) * frob_sq D ≤ 0 ⇒ frob_sq D ≤ 0. *)
  have step : frob_sq D - (frob_sq A) ^+ 2 * frob_sq D <= 0.
    by rewrite subr_le0.
  have factor : frob_sq D - (frob_sq A) ^+ 2 * frob_sq D
              = (1 - (frob_sq A) ^+ 2) * frob_sq D.
    by rewrite mulrBl mul1r.
  rewrite factor in step.
  have d_gt0 : 0 < 1 - (frob_sq A) ^+ 2 by rewrite subr_gt0.
  by rewrite -(ler_pM2l d_gt0) mulr0; exact: step.
have D_zero : D = 0 by exact: frob_sq_eq0 fd_eq0.
by apply/eqP; rewrite -subr_eq0 -/D D_zero.
Qed.

End LyapUnique.

(* ================================================================== *)
(*  Существование PSD-решения через R↔C мост                           *)
(* ================================================================== *)

Section LyapInf.
Variables (Rty : realType) (C : numClosedFieldType).
Variable r2c : {rmorphism Rty -> C}.
Variable c2r : C -> Rty.
Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
Hypothesis r2cK : cancel r2c c2r.
Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
Hypothesis c2r_continuous : continuous (c2r : C -> Rty).
Hypothesis r2c_continuous : continuous (r2c : Rty -> C).

Variable (n : nat).
Variables (A Q : 'M[C]_n).
Hypothesis Q_psd : psd Q.
Hypothesis A_contract : frob_sq A < 1.

Local Notation P := (lyap_partial A Q).

(* Предел частичной суммы. *)
Definition lyap_sol_inf : 'M[C]_n := mx_mono_lim P.

Lemma P_psd k : psd (P k).
Proof. apply: lyap_partial_psd; exact: Q_psd. Qed.
Lemma P_mono k : psd_le (P k) (P k.+1).
Proof. exact: lyap_partial_mono. Qed.
Lemma P_bnd k : psd_le (P k) (lyap_bnd A Q).
Proof. apply: lyap_partial_le_bnd; [exact: Q_psd | exact: A_contract]. Qed.

Theorem lyap_sol_inf_cvgn : P @ \oo --> lyap_sol_inf.
Proof.
apply: (@mx_mono_cvgn Rty C r2c c2r
         ler_r2c c2rK r2c_continuous
         n P (lyap_bnd A Q) P_psd P_mono P_bnd).
Qed.

Lemma lyap_sol_inf_is_cvgn : cvgn P.
Proof. by apply/cvg_ex; exists lyap_sol_inf; exact: lyap_sol_inf_cvgn. Qed.

Theorem lyap_sol_inf_psd : psd lyap_sol_inf.
Proof.
exact: (@mx_mono_lim_psd Rty C r2c c2r
         ler_r2c c2rK c2r_continuous r2c_continuous
         n P (lyap_bnd A Q) P_psd P_mono P_bnd).
Qed.

Lemma lyap_sol_inf_hermsym : lyap_sol_inf \is hermsymmx.
Proof. exact: psd_hermsym lyap_sol_inf_psd. Qed.

Theorem lyap_sol_inf_le_bnd : psd_le lyap_sol_inf (lyap_bnd A Q).
Proof.
exact: (@mx_mono_lim_le Rty C r2c c2r
         ler_r2c c2rK c2r_continuous r2c_continuous
         n P (lyap_bnd A Q) P_psd P_mono P_bnd).
Qed.

(* ================================================================== *)
(*  Неподвижная точка: lyap_sol_inf = A * lyap_sol_inf * A^t* + Q       *)
(* ================================================================== *)

(* Сдвиг сходящейся последовательности (k → k.+1) тоже сходится к
   lyap_sol_inf — стандартный приём (cvg_addnl + cvg_comp). *)
Lemma lyap_partial_shift_cvgn :
  (fun k => P k.+1) @ \oo --> lyap_sol_inf.
Proof.
have HP : P @ \oo --> lyap_sol_inf := lyap_sol_inf_cvgn.
have Hsh : addn 1 @ \oo --> (\oo : set_system nat) := cvg_addnl 1.
have Hcomp : (P \o addn 1) @ \oo --> lyap_sol_inf
  := cvg_comp (addn 1) P Hsh HP.
have Heq : P \o (addn 1) = (fun k => P k.+1).
  by apply/funext=> k; rewrite /= add1n.
by rewrite -Heq.
Qed.

(* Непрерывность правой части шага Ляпунова. *)
Lemma cvgn_lyap_step (Pf : nat -> 'M[C]_n) (L : 'M[C]_n) :
  Pf @ \oo --> L ->
  (fun k => Q + A *m Pf k *m A^t*) @ \oo --> Q + A *m L *m A^t*.
Proof.
move=> HPf.
apply: cvgn_addmx; first exact: cvg_cst.
apply: cvgn_mulmx; last exact: cvg_cst.
exact: cvgn_mulmx (cvg_cst _) HPf.
Qed.

Theorem lyap_sol_inf_fixpoint :
  lyap_sol_inf = A *m lyap_sol_inf *m A^t* + Q.
Proof.
have Hshift : (fun k => P k.+1) @ \oo --> lyap_sol_inf
  := lyap_partial_shift_cvgn.
have eqf : (fun k => P k.+1) = (fun k => Q + A *m P k *m A^t*).
  by apply/funext=> k; exact: lyap_partial_shift.
rewrite eqf in Hshift.
have Hrhs : (fun k => Q + A *m P k *m A^t*) @ \oo -->
            Q + A *m lyap_sol_inf *m A^t*
  := cvgn_lyap_step lyap_sol_inf_cvgn.
have HausM : hausdorff_space ('M[C]_n : pseudoMetricNormedZmodType C).
  exact: norm_hausdorff.
have Hshift_n :
    (fun k => Q + A *m P k *m A^t*)
      @ \oo --> (lyap_sol_inf : ('M[C]_n : pseudoMetricNormedZmodType C))
  by exact: Hshift.
have Hrhs_n :
    (fun k => Q + A *m P k *m A^t*)
      @ \oo --> ((Q + A *m lyap_sol_inf *m A^t*)
                  : ('M[C]_n : pseudoMetricNormedZmodType C))
  by exact: Hrhs.
have eqLim : lyap_sol_inf = Q + A *m lyap_sol_inf *m A^t*
  := cvg_unique HausM Hshift_n Hrhs_n.
by rewrite [LHS]eqLim addrC.
Qed.

(* Уникальность среди эрмитовых решений (как частный случай LyapUnique). *)
Theorem lyap_sol_inf_unique (X : 'M[C]_n) :
  X \is hermsymmx ->
  X = A *m X *m A^t* + Q ->
  X = lyap_sol_inf.
Proof.
move=> Hherm Heq.
apply: (lyap_sol_unique A_contract Hherm lyap_sol_inf_hermsym Heq).
exact: lyap_sol_inf_fixpoint.
Qed.

End LyapInf.
