(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Вычислимые уточнения грамианов наблюдаемости и управляемости.

  Построены поверх примитивов `support.v` средствами CoqEAL: доказательства
  живут на зависимых матрицах `'M[R]_(m, n)`, исполнение на `seqmx`, связь через
  теоремы `refines`. Один и тот же терм программы запускается над `rat`, `bigQ`
  и `Q` и по построению совпадает со спецификацией.

  Абстрактные грамианы над парой `(R, conj)`, то есть `obsv_gram` и `ctrl_gram`,
  вынесены в `riccati_def.v`. При `conj := conjC` над `numClosedFieldType` они
  совпадают с операторами `obsv_bound.v`, что закрепляет раздел `BridgeC`.
*)

From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx.
From Kalman Require Import mxnotation riccati_def obsv_bound.
From Kalman.seqmx Require Import support.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(* Исполнимые программы над CoqEAL. *)
Section EffPrograms.

  Context (C : Type).
  Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C}.

  Variable conj : C -> C.

  (* Грамиан наблюдаемости: sum_{j<k} (F^j)^t* H^t* W H F^j. *)
  Fixpoint obsv_gram_seqmx (n p : nat) (sF sH sW : @seqmx C) (k : nat)
      : @seqmx C :=
    if k is k'.+1 then
      let Fj := mpow_seqmx n sF k' in
      add_seqmx (obsv_gram_seqmx n p sF sH sW k')
        (@hmul_op _ _ _ n n n
          (@hmul_op _ _ _ n p n
            (@hmul_op _ _ _ n p p
              (@hmul_op _ _ _ n n p (ctr_seqmx conj n n Fj)
                (ctr_seqmx conj p n sH))
              sW)
            sH)
          Fj)
    else seqmx0 n n.

  (* Грамиан управляемости: sum_{j<k} F^j G Q G^t* (F^j)^t*. *)
  Fixpoint ctrl_gram_seqmx (n m : nat) (sF sG sQ : @seqmx C) (k : nat)
      : @seqmx C :=
    if k is k'.+1 then
      let Fj := mpow_seqmx n sF k' in
      add_seqmx (ctrl_gram_seqmx n m sF sG sQ k')
        (@hmul_op _ _ _ n n n
          (@hmul_op _ _ _ n m n
            (@hmul_op _ _ _ n m m
              (@hmul_op _ _ _ n n m Fj sG) sQ)
            (ctr_seqmx conj n m sG))
          (ctr_seqmx conj n n Fj))
    else seqmx0 n n.

End EffPrograms.

(* Корректность: подстановка C := R и теоремы refines. *)
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

  Lemma rzero (a b : nat) : refines (RR a b) (0 : 'M[R]_(a, b)) (seqmx0 a b).
  Proof.
    exact: Rseqmx_0.
  Qed.

  (* Грамиан наблюдаемости. *)
  Lemma obsv_gram_seqmx_correct (n p : nat) (F : 'M[R]_n) (H : 'M[R]_(p, n))
      (W : 'M[R]_p) (sF sH sW : @seqmx R)
      (rF : refines (RR n n) F sF) (rH : refines (RR p n) H sH)
      (rW : refines (RR p p) W sW) (k : nat) :
    refines (RR n n) (riccati_def.obsv_gram conj F H W k)
      (obsv_gram_seqmx conj n p sF sH sW k).
  Proof.
    elim: k => [|k IHk].
    - rewrite riccati_def.obsv_gram0 /=; exact: rzero.
    - rewrite riccati_def.obsv_gram_recr /=.
      have rFj := rmpow rF k.
      apply: refines_addmx => //.
      exact: (refines_mulmx
                (refines_mulmx
                  (refines_mulmx
                    (refines_mulmx (refines_ctr_seqmx conj rFj)
                      (refines_ctr_seqmx conj rH))
                    rW)
                  rH)
                rFj).
  Qed.

  (* Грамиан управляемости. *)
  Lemma ctrl_gram_seqmx_correct (n m : nat) (F : 'M[R]_n) (G : 'M[R]_(n, m))
      (Q : 'M[R]_m) (sF sG sQ : @seqmx R)
      (rF : refines (RR n n) F sF) (rG : refines (RR n m) G sG)
      (rQ : refines (RR m m) Q sQ) (k : nat) :
    refines (RR n n) (riccati_def.ctrl_gram conj F G Q k)
      (ctrl_gram_seqmx conj n m sF sG sQ k).
  Proof.
    elim: k => [|k IHk].
    - rewrite riccati_def.ctrl_gram0 /=; exact: rzero.
    - rewrite riccati_def.ctrl_gram_recr /=.
      have rFj := rmpow rF k.
      apply: refines_addmx => //.
      exact: (refines_mulmx
                (refines_mulmx
                  (refines_mulmx (refines_mulmx rFj rG) rQ)
                  (refines_ctr_seqmx conj rG))
                (refines_ctr_seqmx conj rFj)).
  Qed.

End Refine.

(* Мост к спецификациям при conj := conjC. *)
Section BridgeC.

  Variable ℂ : numClosedFieldType.

  (* Грамиан наблюдаемости уточнения совпадает с `obsv_bound.obsv_gram`. *)
  Lemma gobsv_gram_bridge (n p : nat) (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n))
      (R : 'M[ℂ]_p) (k : nat) :
    riccati_def.obsv_gram conjC F H (invmx R) k = obsv_gram F H R k.
  Proof. by []. Qed.

  (* Грамиан управляемости уточнения совпадает с `obsv_bound.ctrl_gram`. *)
  Lemma gctrl_gram_bridge (m n : nat) (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m))
      (Q : 'M[ℂ]_m) (k : nat) :
    riccati_def.ctrl_gram conjC F G Q k = ctrl_gram F G Q k.
  Proof. by []. Qed.

End BridgeC.
