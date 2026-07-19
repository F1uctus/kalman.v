(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Исполнимое обращение матрицы методом Фаддеева-Леверье.

  CoqEAL не уточняет `invmx` над произвольным полем, поэтому обращение
  инновационной ковариации в `riccati.v` вынесено в параметр `cinv` с
  обязательством `cinv_correct`. Здесь это обязательство снимается для любого
  порядка $p$ исполнимой программой `cinv_fl`, повторяющей на слое операций
  CoqEAL рекурренту по следу из `faddeev.v`:
  $M_1 = E, c_(n-j) = - tr(A M_j) / j, M_(j+1) = A M_j + c_(n-j) E$,
  $A^(-1) = - c_0^(-1) M_n$.

  Совпадение с `invmx` доказано на обратимой матрице (`cinv_fl_correct`);
  сторона `S \in unitmx` берётся из спецификации, поскольку
  `kalman.innov_cov_pd` даёт `innov_cov ... \in unitmx`. При $p = 1$ совпадение
  верно безусловно (`cinv_fl_correct1`), так как в поле $0^(-1) = 0$.
*)

From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx.
From Kalman Require Import mxnotation faddeev.
From Kalman.seqmx Require Import support.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section EffInverseFL.

  Context (C : Type).
  Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C, !inv_of C}.

  (* Матрица $M_(j+1)$ рекуррентности Фаддеева-Леверье для n*n-матрицы sA. *)
  Fixpoint fl_M (n : nat) (sA : @seqmx C) (j : nat) : @seqmx C :=
    if j is j'.+1 then
      let AM := @hmul_op _ _ _ n n n sA (fl_M n sA j') in
      add_seqmx AM
        (iscalar_seqmx n (- trace_seqmx (m:=n) AM * (cnat j'.+1)^-1)%C)
    else iscalar_seqmx n 1%C.

  (*
    Исполнимое обращение методом Фаддеева-Леверье.

    Последний член рекуррентности `fl_M` нормируется свободным коэффициентом
    характеристического многочлена; программа дословно повторяет `fl_inv` из
    `faddeev.v` на слое операций CoqEAL.
  *)
  Definition cinv_fl (n : nat) (sS : @seqmx C) : @seqmx C :=
    let M := fl_M n sS n.-1 in
    let c := (- trace_seqmx (m:=n) (@hmul_op _ _ _ n n n sS M) * (cnat n)^-1)%C in
    @hmul_op _ _ _ n n n (iscalar_seqmx n (- c^-1)%C) M.

End EffInverseFL.

Section InverseFLcorrect.

  Variable F : numFieldType.
  Local Notation RR a := (Rseqmx (nat_Rxx a) (nat_Rxx a)).

  Existing Instance Rseqmx_mul.
  Existing Instance Rseqmx_add.
  Existing Instance Rseqmx_scalar_seqmx.
  Existing Instance Rseqmx_trace_seqmx.
  Existing Instance Rseqmx_1.

  Lemma refines_mulmx_fl a b c (X : 'M[F]_(a, b)) (Y : 'M[F]_(b, c))
      (sX sY : @seqmx F) :
    refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX ->
    refines (Rseqmx (nat_Rxx b) (nat_Rxx c)) Y sY ->
    refines (Rseqmx (nat_Rxx a) (nat_Rxx c)) (X *m Y) (@hmul_op _ _ _ a b c sX sY).
  Proof.
    move=> rX rY; exact: refines_apply.
  Qed.

  Lemma refines_scalarmx a (x : F) : refines (RR a) (x%:M) (scalar_seqmx a x).
  Proof.
    exact: (refines_apply (Rseqmx_scalar_seqmx _ (nat_Rxx _)) (trivial_refines erefl)).
  Qed.

  Lemma refines_iscalarmx a (x : F) : refines (RR a) (x%:M) (iscalar_seqmx a x).
  Proof.
    by rewrite iscalar_seqmxE; exact: refines_scalarmx.
  Qed.

  Lemma fl_M_refines (n' : nat) (A : 'M[F]_n'.+1) (sA : @seqmx F) j :
    refines (RR n'.+1) A sA ->
    refines (RR n'.+1) (flM A j) (fl_M n'.+1 sA j).
  Proof.
    move=> rA; elim: j => [|j IH].
      rewrite /=.
      exact: refines_iscalarmx.
    have eflM : flM A j.+1
              = A *m flM A j + (- \tr (A *m flM A j) / (j.+1)%:R) *: 1%:M by [].
    have eM : fl_M n'.+1 sA j.+1
            = add_seqmx (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA (fl_M n'.+1 sA j))
                (iscalar_seqmx n'.+1
                  (- trace_seqmx (m:=n'.+1) (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA
                      (fl_M n'.+1 sA j)) * (cnat j.+1)^-1)) by [].
    rewrite eflM eM.
    have rAM : refines (RR n'.+1) (A *m flM A j)
                      (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA (fl_M n'.+1 sA j)).
      exact: refines_apply.
    have htr : \tr (A *m flM A j)
            = trace_seqmx (m:=n'.+1)
                (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA (fl_M n'.+1 sA j)).
      by apply: refines_eq; exact: refines_apply.
    have hcoef : (- \tr (A *m flM A j) / (j.+1)%:R
                = - trace_seqmx (m:=n'.+1)
                      (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA (fl_M n'.+1 sA j))
                    * (cnat j.+1)^-1 :> F).
      by rewrite htr cnat_natr.
    have -> : - \tr (A *m flM A j) / (j.+1)%:R *: 1%:M
            = (- \tr (A *m flM A j) / (j.+1)%:R)%:M :> 'M[F]_n'.+1.
      by rewrite scale_scalar_mx mulr1.
    rewrite hcoef.
    exact: (refines_apply (refines_apply _ rAM) (refines_iscalarmx _ _)).
  Qed.

  (* Уточнение исполнимого обращения абстрактным fl_inv, без условия. *)
  Lemma cinv_fl_refines (n' : nat) (S : 'M[F]_n'.+1) (sS : @seqmx F) :
    refines (RR n'.+1) S sS ->
    refines (RR n'.+1) (fl_inv S) (cinv_fl n'.+1 sS).
  Proof.
    move=> rS; rewrite /fl_inv /cinv_fl.
    have predE : (n'.+1).-1 = n' by [].
    rewrite predE.
    have rM : refines (RR n'.+1) (flM S n') (fl_M n'.+1 sS n').
      exact: fl_M_refines.
    have rAM : refines (RR n'.+1) (S *m flM S n')
                      (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sS (fl_M n'.+1 sS n')).
      exact: refines_apply.
    have htr : \tr (S *m flM S n')
            = trace_seqmx (m:=n'.+1)
                (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sS (fl_M n'.+1 sS n')).
      by apply: refines_eq; exact: refines_apply.
    have hflc : flc S n'
              = (- trace_seqmx (m:=n'.+1)
                    (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sS (fl_M n'.+1 sS n'))
                  * (cnat n'.+1)^-1 :> F).
      by rewrite /flc htr cnat_natr.
    rewrite hflc -mul_scalar_mx.
    exact: (refines_mulmx_fl (refines_iscalarmx _ _) rM).
  Qed.

  (* cinv_fl уточняет invmx для обратимой $p*p$-матрицы. *)
  Lemma cinv_fl_correct (n' : nat) (S : 'M[F]_n'.+1) (sS : @seqmx F) :
    S \in unitmx ->
    refines (RR n'.+1) S sS ->
    refines (RR n'.+1) (invmx S) (cinv_fl n'.+1 sS).
  Proof.
    by move=> Sunit rS; rewrite -(fl_inv_correct Sunit); exact: cinv_fl_refines.
  Qed.

  (* При $p = 1$ обращение верно безусловно, что снимает cinv при $p = 1$. *)
  Lemma cinv_fl_correct1 (S : 'M[F]_1) (sS : @seqmx F) :
    refines (RR 1) S sS ->
    refines (RR 1) (invmx S) (cinv_fl 1 sS).
  Proof.
    by move=> rS; rewrite -(fl_inv1 S); exact: (cinv_fl_refines (n':=0)).
  Qed.

End InverseFLcorrect.
