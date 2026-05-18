(*  Фробениусов квадрат нормы матриц над numClosedFieldType.            *)
(*                                                                       *)
(*  Frobenius² norm:  ||M||_F² = \tr (M^t* *m M)                         *)
(*                            = \sum_{i,j} (M_{ij})^conj * M_{ij}         *)
(*                            = \sum_{i,j} `|M_{ij}|^2                    *)
(*                                                                       *)
(*  Этот файл — фундамент для:                                           *)
(*    * метрики на матрицах (через ||A - B||_F²);                        *)
(*    * монотонной сходимости PSD-последовательностей;                   *)
(*    * утверждений о пределах фильтра Калмана.                          *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import psd_base.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section Frob.
Variable (C : numClosedFieldType).

(* ================================================================== *)
(* Определение и базовые тождества                                    *)
(* ================================================================== *)

Definition frob_sq r c (M : 'M[C]_(r, c)) : C := \tr (M^t* *m M).

(* Развёртка: ||M||_F² = \sum_{i,j} M_{ij}^* * M_{ij}.
   Удобно для энтрипоинтных аргументов. *)
Lemma frob_sqE r c (M : 'M[C]_(r, c)) :
  frob_sq M = \sum_j \sum_i (M i j)^* * M i j.
Proof.
rewrite /frob_sq /mxtrace.
apply: eq_bigr=> j _; rewrite mxE.
by apply: eq_bigr=> i _; rewrite !mxE.
Qed.

(* Неотрицательность. *)
Lemma frob_sq_ge0 r c (M : 'M[C]_(r, c)) : 0 <= frob_sq M.
Proof.
rewrite frob_sqE; apply: sumr_ge0=> j _; apply: sumr_ge0=> i _.
by rewrite mulrC; exact: mul_conjC_ge0.
Qed.

(* Зануление характеризует нулевую матрицу. *)
Lemma frob_sq_eq0 r c (M : 'M[C]_(r, c)) : frob_sq M = 0 -> M = 0.
Proof.
rewrite frob_sqE => sum0.
have step1 : forall j : 'I_c, \sum_i (M i j)^* * M i j = 0.
  move=> j; move/eqP: sum0; rewrite psumr_eq0; last first.
    move=> j' _; apply: sumr_ge0=> i _.
    by rewrite mulrC; exact: mul_conjC_ge0.
  by move/allP=> /(_ j (mem_index_enum _)) /= /eqP.
apply/matrixP=> i j.
have hzero : (M i j)^* * M i j = 0.
  move/eqP: (step1 j); rewrite psumr_eq0; last first.
    by move=> i' _; rewrite mulrC; exact: mul_conjC_ge0.
  by move/allP=> /(_ i (mem_index_enum _)) /= /eqP.
move/eqP: hzero; rewrite mulf_eq0=> /orP[].
  by rewrite conjC_eq0 => /eqP->; rewrite mxE.
by move/eqP->; rewrite mxE.
Qed.

Lemma frob_sq_eq0P r c (M : 'M[C]_(r, c)) :
  reflect (M = 0) (frob_sq M == 0).
Proof.
apply: (iffP eqP).
- exact: frob_sq_eq0.
- by move=> ->; rewrite /frob_sq trmxC0 mul0mx mxtrace0.
Qed.

(* Если для любого eps > 0 имеем frob_sq < eps, то frob_sq = 0,
   откуда M = 0.  Это даст нам "Хаусдорфовость" Фробениусовой
   метрики: разные матрицы лежат на положительном расстоянии. *)
Lemma frob_sq_lt_eps_eq0 r c (M : 'M[C]_(r, c)) :
  (forall eps : C, 0 < eps -> frob_sq M < eps) -> frob_sq M = 0.
Proof.
move=> Hlt; apply/eqP; apply: contraT=> Hne.
have nneg := frob_sq_ge0 M.
have pos : 0 < frob_sq M by rewrite lt0r Hne nneg.
by have := Hlt _ pos; rewrite ltxx.
Qed.

(* ================================================================== *)
(* Алгебраические тождества                                            *)
(* ================================================================== *)

Lemma frob_sq0 r c : frob_sq (0 : 'M[C]_(r, c)) = 0.
Proof. by rewrite /frob_sq trmxC0 mul0mx mxtrace0. Qed.

Lemma frob_sqN r c (M : 'M[C]_(r, c)) : frob_sq (- M) = frob_sq M.
Proof.
rewrite /frob_sq trmxCN.
have -> : (- M^t*) *m (- M) = M^t* *m M by rewrite mulNmx mulmxN opprK.
by [].
Qed.

(* Сопряжение/транспонирование не меняет Фробениусов квадрат. *)
Lemma frob_sq_trmxC r c (M : 'M[C]_(r, c)) : frob_sq (M^t*) = frob_sq M.
Proof.
rewrite /frob_sq trmxCK.
have e : \tr (M *m M^t*) = \tr (M^t* *m M) by rewrite mxtrace_mulC.
by rewrite e.
Qed.

(* "Loose triangle": ||A + B||² ≤ 2 (||A||² + ||B||²).  Однако нам
   достаточно более простого факта: если ||A - B||_F² = 0, то A = B. *)
Lemma frob_sq_subr0 r c (A B : 'M[C]_(r, c)) :
  frob_sq (A - B) = 0 -> A = B.
Proof. by move/frob_sq_eq0/eqP; rewrite subr_eq0=> /eqP. Qed.

(* Полное разложение скалярного произведения матриц через след:
     tr(A^t* B) = \sum_{i,j} (A_{ij})^* * B_{ij}                        *)
Lemma trmxC_dotE r c (A B : 'M[C]_(r, c)) :
  \tr (A^t* *m B) = \sum_j \sum_i (A i j)^* * B i j.
Proof.
rewrite /mxtrace; apply: eq_bigr=> j _; rewrite mxE.
by apply: eq_bigr=> i _; rewrite !mxE.
Qed.

(* ================================================================== *)
(* PSD-связи                                                           *)
(* ================================================================== *)

(* Фробениусов квадрат есть след psd-матрицы M^t* *m M; в частности,
   PSD-неотрицательность даёт ≥ 0 (повторно — уже доказали). *)
Lemma psd_frob r c (M : 'M[C]_(r, c)) : psd (M^t* *m M).
Proof.
split.
  by rewrite trmxC_mul trmxCK.
move=> v.
have nneg := frob_sq_ge0 (M *m v).
rewrite /frob_sq trmxC_mul in nneg.
suff -> : v^t* *m (M^t* *m M) *m v = (v^t* *m M^t*) *m (M *m v) by [].
by rewrite !mulmxA.
Qed.

(* Для psd-матрицы A её след неотрицателен (повторно с psd_tr_ge0). *)
Lemma psd_trace_ge0 n (A : 'M[C]_n) : psd A -> 0 <= \tr A.
Proof. exact: psd_tr_ge0. Qed.

(* PSD-разность A - B имеет неотрицательный след; в частности,
   tr A - tr B ≥ 0 при B ≤ A в смысле Лёвнера. *)
Lemma psd_le_trace n (A B : 'M[C]_n) :
  psd (B - A) -> \tr A <= \tr B.
Proof.
move=> hpsd.
have := psd_tr_ge0 hpsd.
rewrite linearB /= subr_ge0; by [].
Qed.

End Frob.

(* ================================================================== *)
(* Удобные нотации                                                     *)
(* ================================================================== *)

Notation "\fnorm M ^+ 2" := (frob_sq M) (at level 2, format "\fnorm  M  ^+  2") : ring_scope.
