
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx binint binrat.
From Bignums Require Import BigQ.
From Kalman Require Import mxnotation kalman obsv_bound dare.
From Kalman.seqmx Require Import riccati_seqmx.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

#[local] Instance ring_zero (R : comUnitRingType) : zero_of R := 0%R.
#[local] Instance ring_one  (R : comUnitRingType) : one_of R  := 1%R.
#[local] Instance ring_opp  (R : comUnitRingType) : opp_of R  := -%R.
#[local] Instance ring_add  (R : comUnitRingType) : add_of R  := +%R.
#[local] Instance ring_mul  (R : comUnitRingType) : mul_of R  := *%R.
#[local] Instance ring_eq   (R : comUnitRingType) : eq_of R   := eqtype.eq_op.
#[local] Instance ring_inv  (R : comUnitRingType) : inv_of R  := GRing.inv.

Section EffPrograms.

  Context (C : Type).
  Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C}.

  Variable conj : C -> C.

  Definition mpow_seqmx (n : nat) (sA : @seqmx C) (k : nat) : @seqmx C :=
    iter k (fun acc => @hmul_op _ _ _ n n n acc sA) (seqmx1 n).

  Fixpoint obsv_gram_seqmx (n p : nat) (sF sH sW : @seqmx C) (k : nat)
      : @seqmx C :=
    if k is k'.+1 then
      let Fj := mpow_seqmx n sF k' in
      add_seqmx (obsv_gram_seqmx n p sF sH sW k')
        (@hmul_op _ _ _ n n n
          (@hmul_op _ _ _ n p n
            (@hmul_op _ _ _ n p p
              (@hmul_op _ _ _ n n p (ctr_seqmx conj n n Fj) (ctr_seqmx conj p n sH))
              sW)
            sH)
          Fj)
    else seqmx0 n n.

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

  Definition closed_loop_seqmx (m n p : nat) (sF sG sH sQ sRm : @seqmx C)
      (cinv : @seqmx C -> @seqmx C) (sP : @seqmx C) : @seqmx C :=
    let Kf := kalman_gain_seqmx conj n p sH sRm cinv
                (predict_cov_seqmx conj m n sF sG sQ sP) in
    add_seqmx sF (opp_seqmx (@hmul_op _ _ _ n p n (@hmul_op _ _ _ n n p sF Kf) sH)).

End EffPrograms.

Section GenericDefs.

  Variable R : comUnitRingType.

  Variable conj : R -> R.

  Fixpoint gobsv_gram (n p : nat) (F : 'M[R]_n) (H : 'M[R]_(p, n))
      (W : 'M[R]_p) (k : nat) : 'M[R]_n :=
    if k is k'.+1 then
      gobsv_gram F H W k' +
      ((F ^+ k') ^t conj) *m (H ^t conj) *m W *m H *m (F ^+ k')
    else 0.

  Fixpoint gctrl_gram (n m : nat) (F : 'M[R]_n) (G : 'M[R]_(n, m))
      (Q : 'M[R]_m) (k : nat) : 'M[R]_n :=
    if k is k'.+1 then
      gctrl_gram F G Q k' +
      (F ^+ k') *m G *m Q *m (G ^t conj) *m ((F ^+ k') ^t conj)
    else 0.

  Definition gclosed_loop (m n p : nat) (F : 'M[R]_n) (G : 'M[R]_(n, m))
      (H : 'M[R]_(p, n)) (Q : 'M[R]_m) (Rm : 'M[R]_p) (P : 'M[R]_n) : 'M[R]_n :=
    F - F *m gkalman_gain conj H Rm (gpredict_cov conj F G Q P) *m H.

End GenericDefs.

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

  Lemma rmul (a b c : nat) (X : 'M[R]_(a, b)) (Y : 'M[R]_(b, c))
      (sX sY : @seqmx R) (rX : refines (RR a b) X sX) (rY : refines (RR b c) Y sY) :
    refines (RR a c) (X *m Y) (@hmul_op _ _ _ a b c sX sY).
  Proof.
    exact: refines_apply.
  Qed.

  Lemma radd (a b : nat) (X Y : 'M[R]_(a, b)) (sX sY : @seqmx R)
      (rX : refines (RR a b) X sX) (rY : refines (RR a b) Y sY) :
    refines (RR a b) (X + Y) (add_seqmx sX sY).
  Proof.
    exact: refines_apply.
  Qed.

  Lemma ropp (a b : nat) (X : 'M[R]_(a, b)) (sX : @seqmx R)
      (rX : refines (RR a b) X sX) :
    refines (RR a b) (- X) (opp_seqmx sX).
  Proof.
    exact: refines_apply.
  Qed.

  Lemma rctr (a b : nat) (A : 'M[R]_(a, b)) (sA : @seqmx R)
      (rA : refines (RR a b) A sA) :
    refines (RR b a) (A ^t conj) (ctr_seqmx conj a b sA).
  Proof.
    exact: (refines_ctr_seqmx conj rA).
  Qed.

  Lemma rmpow (n : nat) (A : 'M[R]_n) (sA : @seqmx R)
      (rA : refines (RR n n) A sA) (k : nat) :
    refines (RR n n) (A ^+ k) (mpow_seqmx n sA k).
  Proof.
    elim: k => [|k IHk].
    - rewrite expr0 /mpow_seqmx /=; exact: Rseqmx_1.
    - rewrite exprSr /mpow_seqmx /= -/(mpow_seqmx n sA k) -mulmxE.
      exact: (rmul IHk rA).
  Qed.

  Lemma rzero (a b : nat) : refines (RR a b) (0 : 'M[R]_(a, b)) (seqmx0 a b).
  Proof.
    exact: Rseqmx_0.
  Qed.

  Lemma obsv_gram_seqmx_correct (n p : nat) (F : 'M[R]_n) (H : 'M[R]_(p, n))
      (W : 'M[R]_p) (sF sH sW : @seqmx R)
      (rF : refines (RR n n) F sF) (rH : refines (RR p n) H sH)
      (rW : refines (RR p p) W sW) (k : nat) :
    refines (RR n n) (gobsv_gram conj F H W k)
      (obsv_gram_seqmx conj n p sF sH sW k).
  Proof.
    elim: k => [|k IHk] /=; first exact: rzero.
    have rFj := rmpow rF k.
    apply: radd => //.
    exact: (rmul (rmul (rmul (rmul (rctr rFj) (rctr rH)) rW) rH) rFj).
  Qed.

  Lemma ctrl_gram_seqmx_correct (n m : nat) (F : 'M[R]_n) (G : 'M[R]_(n, m))
      (Q : 'M[R]_m) (sF sG sQ : @seqmx R)
      (rF : refines (RR n n) F sF) (rG : refines (RR n m) G sG)
      (rQ : refines (RR m m) Q sQ) (k : nat) :
    refines (RR n n) (gctrl_gram conj F G Q k)
      (ctrl_gram_seqmx conj n m sF sG sQ k).
  Proof.
    elim: k => [|k IHk] /=; first exact: rzero.
    have rFj := rmpow rF k.
    apply: radd => //.
    exact: (rmul (rmul (rmul (rmul rFj rG) rQ) (rctr rG)) (rctr rFj)).
  Qed.

  Lemma closed_loop_seqmx_correct (m n p : nat)
      (F : 'M[R]_n) (G : 'M[R]_(n, m)) (H : 'M[R]_(p, n))
      (Q : 'M[R]_m) (Rm : 'M[R]_p) (P : 'M[R]_n)
      (sF sG sH sQ sRm sP : @seqmx R)
      (rF : refines (RR n n) F sF) (rG : refines (RR n m) G sG)
      (rH : refines (RR p n) H sH) (rQ : refines (RR m m) Q sQ)
      (rRm : refines (RR p p) Rm sRm) (rP : refines (RR n n) P sP)
      (cinv : @seqmx R -> @seqmx R)
      (cinv_correct : forall (S : 'M[R]_p) (sS : @seqmx R),
        refines (RR p p) S sS -> refines (RR p p) (invmx S) (cinv sS)) :
    refines (RR n n) (gclosed_loop conj F G H Q Rm P)
      (closed_loop_seqmx conj m n p sF sG sH sQ sRm cinv sP).
  Proof.
    rewrite /gclosed_loop /closed_loop_seqmx.
    have rPpred : refines (RR n n) (gpredict_cov conj F G Q P)
        (predict_cov_seqmx conj m n sF sG sQ sP).
      rewrite /gpredict_cov /predict_cov_seqmx.
      apply: radd; first exact: (rmul (rmul rF rP) (rctr rF)).
      exact: (rmul (rmul rG rQ) (rctr rG)).
    have rInnov : refines (RR p p)
        (ginnov_cov conj H Rm (gpredict_cov conj F G Q P))
        (innov_cov_seqmx conj n p sH sRm (predict_cov_seqmx conj m n sF sG sQ sP)).
      rewrite /ginnov_cov /innov_cov_seqmx.
      apply: radd => //; exact: (rmul (rmul rH rPpred) (rctr rH)).
    have rKf : refines (RR n p)
        (gkalman_gain conj H Rm (gpredict_cov conj F G Q P))
        (kalman_gain_seqmx conj n p sH sRm cinv
          (predict_cov_seqmx conj m n sF sG sQ sP)).
      rewrite /gkalman_gain /kalman_gain_seqmx.
      exact: (rmul (rmul rPpred (rctr rH)) (cinv_correct _ _ rInnov)).
    exact: (radd rF (ropp (rmul (rmul rF rKf) rH))).
  Qed.

End Refine.

Section BridgeC.

  Variable ℂ : numClosedFieldType.

  Lemma gobsv_gram_bridge (n p : nat) (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n))
      (R : 'M[ℂ]_p) (k : nat) :
    gobsv_gram conjC F H (invmx R) k = obsv_gram F H R k.
  Proof.
    elim: k => [|k IHk] /=; first by rewrite obsv_gram0.
    by rewrite obsv_gram_recr IHk.
  Qed.

  Lemma gctrl_gram_bridge (m n : nat) (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m))
      (Q : 'M[ℂ]_m) (k : nat) :
    gctrl_gram conjC F G Q k = ctrl_gram F G Q k.
  Proof.
    elim: k => [|k IHk] /=; first by rewrite ctrl_gram0.
    by rewrite ctrl_gram_recr IHk.
  Qed.

  Lemma gclosed_loop_bridge (m n p : nat) (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m))
      (H : 'M[ℂ]_(p, n)) (Q : 'M[ℂ]_m) (R : 'M[ℂ]_p) (P : 'M[ℂ]_n) :
    gclosed_loop conjC F G H Q R P =
    F - F *m kalman_gain H R (predict_cov F G Q P) *m H.
  Proof.
    by [].
  Qed.

End BridgeC.
