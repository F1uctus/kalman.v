(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Вычислимое уточнение матрицы замкнутого контура.

  Матрица $A_(c l) = F - F K_f H$, где $K_f$ обозначает усиление Калмана на
  предсказанной ковариации, строится поверх полушагов `riccati.v` средствами
  CoqEAL и извлекается для эксперимента по устойчивости Шура.

  Абстрактное определение `closed_loop` над парой `(R, conj)` вынесено в
  `riccati_def.v`. При `conj := conjC` оно совпадает с предсказательной матрицей
  замкнутого контура $F_p = F - F K_f H$ @kailath2000[§ 14.5], исследуемой в
  `dare.v`; это закрепляет раздел `BridgeC`.

  Обращение $p crossproduct p$-матрицы для усиления Калмана остаётся параметром
  `cinv` с обязательством `cinv_correct`, как и в `riccati.v`; оно снимается
  программой `cinv_fl` из `inverse.v`.
*)

From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx.
From Kalman Require Import mxnotation riccati_def kalman dare.
From Kalman.seqmx Require Import support riccati.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(* Исполнимая программа над CoqEAL. *)
Section EffPrograms.

  Context (C : Type).
  Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C}.

  Variable conj : C -> C.

  Definition closed_loop_seqmx (m n p : nat) (sF sG sH sQ sR_m : @seqmx C)
      (cinv : @seqmx C -> @seqmx C) (sP : @seqmx C) : @seqmx C :=
    let K_f := filter_gain_seqmx conj n p sH sR_m cinv
                (predict_cov_seqmx conj m n sF sG sQ sP) in
    add_seqmx sF
      (opp_seqmx (@hmul_op _ _ _ n p n (@hmul_op _ _ _ n n p sF K_f) sH)).

End EffPrograms.

(* Корректность: подстановка $C := R$ и теоремы refines. *)
Section Refine.

  Variable R : comUnitRingType.

  Existing Instance Rseqmx_add.
  Existing Instance Rseqmx_opp.
  Existing Instance Rseqmx_mul.
  Existing Instance Rseqmx_1.
  Existing Instance Rseqmx_0.
  Existing Instance Rseqmx_trseqmx.
  Existing Instance Rseqmx_map_seqmx.

  Variable conj : R -> R.

  Local Notation RR a b := (Rseqmx (nat_Rxx a) (nat_Rxx b)).

  Lemma closed_loop_seqmx_correct (m n p : nat)
      (F : 'M[R]_n) (G : 'M[R]_(n, m)) (H : 'M[R]_(p, n))
      (Q : 'M[R]_m) (R_m : 'M[R]_p) (P : 'M[R]_n)
      (sF sG sH sQ sR_m sP : @seqmx R)
      (rF : refines (RR n n) F sF) (rG : refines (RR n m) G sG)
      (rH : refines (RR p n) H sH) (rQ : refines (RR m m) Q sQ)
      (rR_m : refines (RR p p) R_m sR_m) (rP : refines (RR n n) P sP)
      (cinv : @seqmx R -> @seqmx R)
      (cinv_correct : forall (S : 'M[R]_p) (sS : @seqmx R),
        refines (RR p p) S sS -> refines (RR p p) (invmx S) (cinv sS)) :
    refines (RR n n) (riccati_def.closed_loop conj F G H Q R_m P)
      (closed_loop_seqmx conj m n p sF sG sH sQ sR_m cinv sP).
  Proof.
    rewrite /riccati_def.closed_loop /closed_loop_seqmx.
    have rPpred : refines (RR n n) (riccati_def.predict_cov conj F G Q P)
        (predict_cov_seqmx conj m n sF sG sQ sP).
      rewrite /riccati_def.predict_cov /predict_cov_seqmx.
      apply: refines_addmx;
        first exact: (refines_mulmx (refines_mulmx rF rP)
                        (refines_ctr_seqmx conj rF)).
      exact: (refines_mulmx (refines_mulmx rG rQ) (refines_ctr_seqmx conj rG)).
    have rInnov : refines (RR p p)
        (riccati_def.innov_cov conj H R_m (riccati_def.predict_cov conj F G Q P))
        (innov_cov_seqmx conj n p sH sR_m
          (predict_cov_seqmx conj m n sF sG sQ sP)).
      rewrite /riccati_def.innov_cov /innov_cov_seqmx.
      apply: refines_addmx => //.
      exact: (refines_mulmx (refines_mulmx rH rPpred)
                (refines_ctr_seqmx conj rH)).
    have rKf : refines (RR n p)
        (riccati_def.filter_gain conj H R_m
          (riccati_def.predict_cov conj F G Q P))
        (filter_gain_seqmx conj n p sH sR_m cinv
          (predict_cov_seqmx conj m n sF sG sQ sP)).
      rewrite /riccati_def.filter_gain /filter_gain_seqmx.
      exact: (refines_mulmx (refines_mulmx rPpred (refines_ctr_seqmx conj rH))
                (cinv_correct _ _ rInnov)).
    exact: (refines_addmx rF
              (refines_oppmx (refines_mulmx (refines_mulmx rF rKf) rH))).
  Qed.

End Refine.

(* Мост к спецификациям при $"conj" := "conjC"$. *)
Section BridgeC.

  Variable ℂ : numClosedFieldType.

  (*
    Замкнутый контур совпадает с предсказательной матрицей $F_p = F - F K_f H$,
    где $K_f$ обозначает усиление Калмана на предсказанной ковариации; эта
    матрица исследуется в `dare.v`.
  *)
  Lemma gclosed_loop_bridge (m n p : nat) (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m))
      (H : 'M[ℂ]_(p, n)) (Q : 'M[ℂ]_m) (R : 'M[ℂ]_p) (P : 'M[ℂ]_n) :
    riccati_def.closed_loop conjC F G H Q R P =
    F - F *m filter_gain H R (predict_cov F G Q P) *m H.
  Proof. by []. Qed.

End BridgeC.
