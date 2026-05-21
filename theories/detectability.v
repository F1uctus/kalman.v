(*  Детектируемость, стабилизируемость, PBH-тест.                         *)
(*                                                                         *)
(*  Определения (PBH — Popov–Belevitch–Hautus критерий):                  *)
(*                                                                         *)
(*    detectable F H —                                                     *)
(*      каждый правый собственный вектор `F` с |λ| ≥ 1 наблюдаем парой    *)
(*      (F, H), т.е. `H v ≠ 0`.                                            *)
(*                                                                         *)
(*    stabilizable F G —                                                   *)
(*      каждый левый собственный вектор `F` с |λ| ≥ 1 управляем парой     *)
(*      (F, G), т.е. `w G ≠ 0`.                                            *)
(*                                                                         *)
(*    unit_circle_controllable F G —                                       *)
(*      условие УПРАВЛЯЕМОСТИ ровно на единичной окружности |λ| = 1.       *)
(*                                                                         *)
(*  Schur-стабильность:                                                    *)
(*                                                                         *)
(*    schur_stable A := frob_sq A < 1                                      *)
(*                                                                         *)
(*  (Это наш текущий аналог классической Шуровости — Фробениусова          *)
(*  контракция строго меньше единицы.  Имплицирует, что все собственные   *)
(*  значения внутри единичного круга, но строго сильнее: для матриц с    *)
(*  спектральным радиусом < 1, но frob_sq ≥ 1, этого недостаточно.)        *)
(*                                                                         *)
(*  Основные теоремы:                                                     *)
(*    * `observable_detectable`: observable F H ⇒ detectable F H.         *)
(*    * `controllable_stabilizable`: controllable F G ⇒ stabilizable F G. *)
(*    * `stabilizable_ucc`: stabilizable F G ⇒                             *)
(*       unit_circle_controllable F G (тривиально, т.к. |λ| = 1 ⇒ ≥ 1).   *)
(*                                                                         *)
(*  Этот файл — инфраструктура для Sessions 16–18 (стабильность            *)
(*  замкнутого контура `Fp`, замена `F_contract` на детектируемость +     *)
(*  UCC в `dare.v`).                                                       *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import psd_base mxfrob kalman.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(* ================================================================== *)
(*  Schur-стабильность через Фробениусовую контракцию                  *)
(* ================================================================== *)

Definition schur_stable (C : numClosedFieldType) (n : nat) (A : 'M[C]_n)
  : Prop := frob_sq A < 1.

(* ================================================================== *)
(*  Детектируемость (правый PBH)                                       *)
(* ================================================================== *)

Section Detectability.
Variable (C : numClosedFieldType).
Variables (n p : nat).
Variables (F : 'M[C]_n) (H : 'M[C]_(p, n)).

Definition detectable : Prop :=
  forall (lam : C) (v : 'cV[C]_n),
    v != 0 -> F *m v = lam *: v -> 1 <= `|lam| -> H *m v != 0.

(* Степень F на собственном векторе: F^+i *m v = lam^+i *: v. *)
Lemma F_pow_eigvec i (lam : C) (v : 'cV[C]_n) :
  F *m v = lam *: v -> F^+i *m v = lam^+i *: v.
Proof.
move=> Fv.
elim: i => [|i IH]; first by rewrite !expr0 mul1mx scale1r.
by rewrite exprS -mulmxA IH -scalemxAr Fv scalerA exprSr.
Qed.

Theorem observable_detectable : observable F H -> detectable.
Proof.
move=> Hobs lam v vNZ Fv_eq _.
apply/negP=> /eqP Hv_eq0.
have Hblock : forall i : 'I_n, obsv_block F H i *m v = 0.
  move=> i.
  rewrite /obsv_block -mulmxA (F_pow_eigvec _ Fv_eq).
  by rewrite -scalemxAr Hv_eq0 scaler0.
have v0 := Hobs v Hblock.
by move: vNZ; rewrite v0 eqxx.
Qed.

End Detectability.

(* ================================================================== *)
(*  Стабилизируемость и UCC (двойственное, левый PBH)                  *)
(* ================================================================== *)

Section Stabilizability.
Variable (C : numClosedFieldType).
Variables (m n : nat).
Variables (F : 'M[C]_n) (G : 'M[C]_(n, m)).

Definition stabilizable : Prop :=
  forall (lam : C) (w : 'rV[C]_n),
    w != 0 -> w *m F = lam *: w -> 1 <= `|lam| -> w *m G != 0.

Definition unit_circle_controllable : Prop :=
  forall (lam : C) (w : 'rV[C]_n),
    w != 0 -> w *m F = lam *: w -> `|lam| = 1 -> w *m G != 0.

(* Степень F на левом собственном векторе. *)
Lemma F_pow_left_eigvec i (lam : C) (w : 'rV[C]_n) :
  w *m F = lam *: w -> w *m F^+i = lam^+i *: w.
Proof.
move=> wF.
elim: i => [|i IH]; first by rewrite !expr0 mulmx1 scale1r.
rewrite exprS [_ *m (_ *m _)]mulmxA wF -scalemxAl IH scalerA.
by rewrite mulrC exprSr.
Qed.

Theorem controllable_stabilizable :
  controllable F G -> stabilizable.
Proof.
move=> Hctrl lam w wNZ wF_eq _.
apply/negP=> /eqP wG_eq0.
have Hblock : forall i : 'I_n, w *m ctrl_block F G i = 0.
  move=> i.
  rewrite /ctrl_block mulmxA (F_pow_left_eigvec _ wF_eq).
  by rewrite -scalemxAl wG_eq0 scaler0.
have w0 := Hctrl w Hblock.
by move: wNZ; rewrite w0 eqxx.
Qed.

(* UCC слабее стабилизируемости: на единичной окружности |λ| = 1 ≥ 1. *)
Theorem stabilizable_ucc :
  stabilizable -> unit_circle_controllable.
Proof.
move=> Hstab lam w wNZ wF_eq lam_eq1.
apply: (Hstab lam w wNZ wF_eq).
by rewrite lam_eq1.
Qed.

End Stabilizability.

(* ================================================================== *)
(*  Связь со Schur-стабильностью                                       *)
(* ================================================================== *)

(* Если матрица Schur-стабильна, то у неё нет собственных значений с    *)
(* |λ| ≥ 1.  Поэтому условия detectable / stabilizable выполняются      *)
(* тривиально (нет «неустойчивых» мод вообще).                          *)
Section SchurStableTrivialDet.
Variable (C : numClosedFieldType).
Variables (n p : nat).
Variables (F : 'M[C]_n) (H : 'M[C]_(p, n)).

(* Frobenius-сжатие исключает собственные значения с |λ| ≥ 1: для      *)
(* любого собственного значения `lam` верно `|lam|^+2 ≤ frob_sq F < 1`.  *)
(* Доказательство: если F v = lam v с v ≠ 0, то                         *)
(*   |lam|^+2 * (v^t* v) = (lam v)^t* (lam v)                          *)
(*                       = (F v)^t* (F v)                              *)
(*                       = v^t* (F^t* F) v                             *)
(*                       ≤ frob_sq F * (v^t* v)                        *)
(* (последнее — `tr_conj_frob_le`).  Сокращая на `v^t* v > 0`,           *)
(* получаем `|lam|^+2 ≤ frob_sq F`.                                     *)

(* Эта лемма — мост между Шуровостью и PBH-условиями: при `schur_stable F` *)
(* любая пара `(F, H)` детектируема, потому что у F нет неустойчивых мод. *)
Theorem schur_stable_detectable : schur_stable F -> detectable F H.
Proof.
move=> Fc lam v vNZ Fv_eq lam_ge1.
(* Шаг 1: |lam|^+2 * (v^t* v) = v^t* (F^t* F) v. *)
have step1 :
   `|lam| ^+ 2 * \tr (v^t* *m v) = \tr (v^t* *m (F^t* *m F) *m v).
  have e1 : v^t* *m (F^t* *m F) *m v = (F *m v)^t* *m (F *m v).
    by rewrite trmxC_mul !mulmxA.
  rewrite e1 Fv_eq trmxC_scale.
  rewrite -scalemxAl -scalemxAr !mxtraceZ.
  by rewrite mulrA -normCKC.
(* Шаг 2: \tr (vᶜ (Fᶜ F) v) ≤ frob_sq F * \tr (vᶜ v).                      *)
(* Доказательство: LHS = \tr (F (v vᶜ) Fᶜ) (cyclic trace + trmxC_mul),    *)
(* затем `tr_conj_frob_le F (psd (v vᶜ))`.                                *)
have step2 :
   \tr (v^t* *m (F^t* *m F) *m v) <= frob_sq F * \tr (v^t* *m v).
  have e3 : v^t* *m (F^t* *m F) *m v = (F *m v)^t* *m (F *m v).
    by rewrite trmxC_mul !mulmxA.
  have e4 : \tr ((F *m v)^t* *m (F *m v)) = \tr (F *m (v *m v^t*) *m F^t*).
    rewrite mxtrace_mulC; congr (\tr _).
    by rewrite trmxC_mul !mulmxA.
  rewrite e3 e4.
  have vvtpsd : psd (v *m v^t*).
    have := psd_frob (v^t*); by rewrite trmxCK.
  apply: (le_trans (tr_conj_frob_le F vvtpsd)).
  by rewrite [\tr (v *m v^t*)]mxtrace_mulC.
(* Шаг 3: `v^t* *m v` — strictly positive (v ≠ 0). *)
have vvpos : 0 < \tr (v^t* *m v).
  rewrite lt0r; apply/andP; split; last first.
    by have := frob_sq_ge0 v; rewrite /frob_sq.
  apply/negP=> /eqP /frob_sq_eq0 v0.
  by move: vNZ; rewrite v0 eqxx.
(* Шаг 4: |lam|^+2 ≤ frob_sq F. *)
have lam2_le : `|lam| ^+ 2 <= frob_sq F.
  rewrite -(ler_pM2r vvpos).
  by rewrite step1.
(* Шаг 5: но 1 ≤ |lam|, значит 1 ≤ |lam|^+2 ≤ frob_sq F < 1 — противоречие. *)
have one_le : (1 : C) <= `|lam| ^+ 2.
  rewrite expr2 -[1]mul1r.
  apply: ler_pM => //; exact: ler01.
have : (1 : C) < 1 by exact: (lt_le_trans (le_lt_trans one_le (le_lt_trans lam2_le Fc))).
by rewrite ltxx.
Qed.

End SchurStableTrivialDet.
