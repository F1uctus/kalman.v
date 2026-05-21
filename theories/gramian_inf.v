(*  Бесконечные Грамианы наблюдаемости и управляемости.                  *)
(*                                                                         *)
(*  Под Фробениусовой стабильностью `frob_sq F < 1` определены             *)
(*  бесконечные Грамианы как пределы решений соответствующих уравнений     *)
(*  Ляпунова:                                                              *)
(*                                                                         *)
(*    obsv_gram_inf F H := lyap_sol_inf (Fᶜ) (Hᶜ *m H)                     *)
(*      ↔ X = Fᶜ *m X *m F + Hᶜ *m H                                       *)
(*                                                                         *)
(*    ctrl_gram_inf F G Q := lyap_sol_inf F (G *m Q *m Gᶜ)                  *)
(*      ↔ X = F *m X *m Fᶜ + G *m Q *m Gᶜ                                  *)
(*                                                                         *)
(*  PD-ность бесконечных Грамианов выводится из PD-ности их конечных       *)
(*  предшественников (`obsv_gram_pd_of_observable`,                        *)
(*  `ctrl_gram_pd_of_controllable` из `obsv_bound.v`) и нижней оценки      *)
(*  через `mx_mono_lim_ge_term` (Session 12).                              *)
(*                                                                         *)
(*  Этот файл — инфраструктура для Sessions 16–17 (стабильность            *)
(*  замкнутого контура `Fp`, определение `O_P` через бесконечный обсв.     *)
(*  Грамиан).                                                              *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import psd_base psd_order spectral mxfrob.
From Kalman Require Import mxtopo mxmonotone lyapunov.
From Kalman Require Import kalman obsv_bound.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* ================================================================== *)
(*  Вспомогательное: pd из psd_le при PD младшем элементе              *)
(* ================================================================== *)

Section PsdLePd.
Variable (C : numClosedFieldType).

(* Если A ≤ B в порядке Лёвнера и A — PD, то B — PD.                    *)
Lemma psd_le_pd n (A B : 'M[C]_n) : psd_le A B -> pd A -> pd B.
Proof.
move=> hAB hA.
have hBA : A + (B - A) = B by rewrite addrC subrK.
by rewrite -hBA; apply: pd_add hA hAB.
Qed.

End PsdLePd.

(* ================================================================== *)
(*  Бесконечные Грамианы                                                *)
(* ================================================================== *)

Section GramianInf.

(* R↔C мост — те же гипотезы, что в `dare.v` / `lyapunov.v`. *)
Variables (Rty : realType) (C : numClosedFieldType).
Variable r2c : {rmorphism Rty -> C}.
Variable c2r : C -> Rty.
Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
Hypothesis r2cK : cancel r2c c2r.
Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
Hypothesis c2r_continuous : continuous (c2r : C -> Rty).
Hypothesis r2c_continuous : continuous (r2c : Rty -> C).

Variables (m n p : nat).
Variables (F : 'M[C]_n) (G : 'M[C]_(n, m)) (H : 'M[C]_(p, n)).
Variable (Q : 'M[C]_m).
Hypothesis Q_psd : psd Q.
Hypothesis F_contract : frob_sq F < 1.

(* `frob_sq Fᶜ = frob_sq F < 1`. *)
Lemma F_trmxC_contract : frob_sq (F^t*) < 1.
Proof. by rewrite frob_sq_trmxC. Qed.

Lemma GQGt_psd : psd (G *m Q *m G^t*).
Proof. exact: psd_mulmx_row Q_psd. Qed.

Lemma HtH_psd : psd (H^t* *m H).
Proof.
have := psd_frob H.
by rewrite /frob_sq.
Qed.
(* psd_frob дает psd (H^t* *m H) напрямую (определение psd_frob: psd (M^t* *m M)). *)

(* ================================================================== *)
(*  Управляемый Грамиан в пределе                                       *)
(* ================================================================== *)

Definition ctrl_gram_inf : 'M[C]_n :=
  lyap_sol_inf F (G *m Q *m G^t*).

Theorem ctrl_gram_inf_psd : psd ctrl_gram_inf.
Proof.
exact: (lyap_sol_inf_psd ler_r2c c2rK c2r_continuous r2c_continuous
         GQGt_psd F_contract).
Qed.

Theorem ctrl_gram_inf_fixpoint :
  ctrl_gram_inf = F *m ctrl_gram_inf *m F^t* + G *m Q *m G^t*.
Proof.
rewrite /ctrl_gram_inf.
exact: (lyap_sol_inf_fixpoint ler_r2c c2rK r2c_continuous
         GQGt_psd F_contract).
Qed.

(* Связь конечного `ctrl_gram` с `lyap_partial`. *)
Lemma ctrl_gram_eq_partial k :
  ctrl_gram F G Q k = lyap_partial F (G *m Q *m G^t*) k.
Proof.
rewrite /ctrl_gram /lyap_partial.
apply: eq_bigr=> j _.
by rewrite trmxCX !mulmxA.
Qed.

(* Конечный Грамиан ≤ бесконечный в порядке Лёвнера. *)
Lemma ctrl_gram_le_inf k :
  psd_le (ctrl_gram F G Q k) ctrl_gram_inf.
Proof.
rewrite ctrl_gram_eq_partial /ctrl_gram_inf /lyap_sol_inf.
apply: (mx_mono_lim_ge_term ler_r2c c2rK c2r_continuous r2c_continuous).
- by move=> k0; apply: lyap_partial_psd; exact: GQGt_psd.
- by move=> k0; apply: lyap_partial_mono; exact: GQGt_psd.
- move=> k0; apply: lyap_partial_le_bnd; [exact: GQGt_psd | exact: F_contract].
Qed.

(* PD-ность бесконечного управляемого Грамиана. *)
Theorem ctrl_gram_inf_pd_of_controllable :
  controllable F G -> pd Q -> pd ctrl_gram_inf.
Proof.
move=> Hctrl Q_pd.
apply: (psd_le_pd (A := ctrl_gram F G Q n)).
- exact: ctrl_gram_le_inf.
- exact: ctrl_gram_pd_of_controllable Q_psd Hctrl Q_pd.
Qed.

(* ================================================================== *)
(*  Обсервационный Грамиан в пределе                                    *)
(* ================================================================== *)

Definition obsv_gram_inf : 'M[C]_n :=
  lyap_sol_inf (F^t*) (H^t* *m H).

Theorem obsv_gram_inf_psd : psd obsv_gram_inf.
Proof.
exact: (lyap_sol_inf_psd ler_r2c c2rK c2r_continuous r2c_continuous
         HtH_psd F_trmxC_contract).
Qed.

Theorem obsv_gram_inf_fixpoint :
  obsv_gram_inf = F^t* *m obsv_gram_inf *m F + H^t* *m H.
Proof.
rewrite /obsv_gram_inf.
rewrite {1}(lyap_sol_inf_fixpoint ler_r2c c2rK r2c_continuous
            HtH_psd F_trmxC_contract).
by rewrite trmxCK.
Qed.

(* Связь конечного `obsv_gram F H 1%:M` (без R-веса) с `lyap_partial`.   *)
(* Используем существующий `obsv_gram` со специальным R = 1%:M.          *)
Lemma obsv_gram_id_eq_partial k :
  obsv_gram F H 1%:M k = lyap_partial (F^t*) (H^t* *m H) k.
Proof.
rewrite /obsv_gram /lyap_partial.
apply: eq_bigr=> j _.
rewrite invmx1 mulmx1 trmxCX.
have ->: ((F^t*)^t*)^+j = F^+j by rewrite trmxCK.
by rewrite mulmxA.
Qed.

(* Конечный обсв. Грамиан (с R = I) ≤ бесконечный. *)
Lemma obsv_gram_id_le_inf k :
  psd_le (obsv_gram F H 1%:M k) obsv_gram_inf.
Proof.
rewrite obsv_gram_id_eq_partial /obsv_gram_inf /lyap_sol_inf.
apply: (mx_mono_lim_ge_term ler_r2c c2rK c2r_continuous r2c_continuous).
- by move=> k0; apply: lyap_partial_psd; exact: HtH_psd.
- by move=> k0; apply: lyap_partial_mono; exact: HtH_psd.
- move=> k0; apply: lyap_partial_le_bnd; [exact: HtH_psd | exact: F_trmxC_contract].
Qed.

(* PD единичной матрицы. *)
Lemma pd1 k : pd (1%:M : 'M[C]_k).
Proof.
split; first by rewrite trmxC1.
move=> v vNZ.
rewrite mulmx1 -/(frob_sq v) lt0r.
apply/andP; split; last exact: frob_sq_ge0.
apply/negP=> /eqP /frob_sq_eq0 v0.
by move: vNZ; rewrite v0 eqxx.
Qed.

(* PD-ность бесконечного обсв. Грамиана.                                 *)
Theorem obsv_gram_inf_pd_of_observable :
  observable F H -> pd obsv_gram_inf.
Proof.
move=> Hobs.
apply: (psd_le_pd (A := obsv_gram F H 1%:M n)).
- exact: obsv_gram_id_le_inf.
- exact: obsv_gram_pd_of_observable (pd1 p) Hobs.
Qed.

End GramianInf.
