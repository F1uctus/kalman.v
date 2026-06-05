

Set Warnings "-notation-overridden,-coercions,-default,-ambiguous-paths".

From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx binint binrat.
From Bignums Require Import BigQ.
From Kalman Require Import mxnotation kalman.

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

Section GenericDefs.
Variable R : comUnitRingType.
Variable conj : R -> R.
Variables (m n p : nat).
Variables (F : 'M[R]_n) (G : 'M[R]_(n, m)) (H : 'M[R]_(p, n)).
Variables (Q : 'M[R]_m) (Rm : 'M[R]_p).

Definition gpredict_cov (P : 'M[R]_n) : 'M[R]_n :=
  F *m P *m map_mx conj F^T + G *m Q *m map_mx conj G^T.

Definition ginnov_cov (P : 'M[R]_n) : 'M[R]_p :=
  H *m P *m map_mx conj H^T + Rm.

Definition gkalman_gain (P : 'M[R]_n) : 'M[R]_(n, p) :=
  P *m map_mx conj H^T *m invmx (ginnov_cov P).

Definition gupdate_cov (P : 'M[R]_n) : 'M[R]_n :=
  (1%:M - gkalman_gain P *m H) *m P.

Definition griccati_step (P : 'M[R]_n) : 'M[R]_n :=
  gupdate_cov (gpredict_cov P).
End GenericDefs.

Section EffPrograms.
Context (C : Type).
Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C, !eq_of C}.
Variable conj : C -> C.
Variables (m n p : nat).
Variables (sF sG sH sQ sRm : @seqmx C).
Variable cinv : @seqmx C -> @seqmx C.

Definition ctr_seqmx (a b : nat) (A : @seqmx C) : @seqmx C :=
  map_seqmx conj (@trseqmx C a b A).

Definition predict_cov_seqmx (sP : @seqmx C) : @seqmx C :=
  add_seqmx
    (@hmul_op _ _ _ n n n (@hmul_op _ _ _ n n n sF sP) (ctr_seqmx n n sF))
    (@hmul_op _ _ _ n m n (@hmul_op _ _ _ n m m sG sQ) (ctr_seqmx n m sG)).

Definition innov_cov_seqmx (sP : @seqmx C) : @seqmx C :=
  add_seqmx
    (@hmul_op _ _ _ p n p (@hmul_op _ _ _ p n n sH sP) (ctr_seqmx p n sH))
    sRm.

Definition kalman_gain_seqmx (sP : @seqmx C) : @seqmx C :=
  @hmul_op _ _ _ n p p
    (@hmul_op _ _ _ n n p sP (ctr_seqmx p n sH))
    (cinv (innov_cov_seqmx sP)).

Definition update_cov_seqmx (sP : @seqmx C) : @seqmx C :=
  let K := kalman_gain_seqmx sP in
  @hmul_op _ _ _ n n n
    (sub_seqmx (seqmx1 n) (@hmul_op _ _ _ n p n K sH)) sP.

Definition riccati_step_seqmx (sP : @seqmx C) : @seqmx C :=
  update_cov_seqmx (predict_cov_seqmx sP).
End EffPrograms.

Section RefineRiccati.
Variable R : comUnitRingType.

Existing Instance Rseqmx_add.
Existing Instance Rseqmx_opp.
Existing Instance Rseqmx_mul.
Existing Instance Rseqmx_1.
Existing Instance Rseqmx_trseqmx.
Existing Instance Rseqmx_map_seqmx.

Variable conj : R -> R.
#[local] Instance refines_conj :
  refines (@eq (R -> R)) conj conj := trivial_refines erefl.

#[export] Instance refines_ctr_seqmx (a b : nat) (A : 'M[R]_(a, b))
    (sA : @seqmx R)
    (rA : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) A sA) :
  refines (Rseqmx (nat_Rxx b) (nat_Rxx a)) (map_mx conj A^T)
    (ctr_seqmx conj a b sA).
Proof.
  rewrite /ctr_seqmx.
  exact: (refines_apply
            (refines_apply (Rseqmx_map_seqmx _ _) refines_conj)
            (refines_apply (Rseqmx_trseqmx _ _) rA)).
Qed.

Lemma refines_mulmx (a b c : nat) (X : 'M[R]_(a, b)) (Y : 'M[R]_(b, c))
    (sX sY : @seqmx R)
    (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX)
    (rY : refines (Rseqmx (nat_Rxx b) (nat_Rxx c)) Y sY) :
  refines (Rseqmx (nat_Rxx a) (nat_Rxx c)) (X *m Y)
    (@hmul_op _ _ _ a b c sX sY).
Proof. exact: refines_apply. Qed.

Lemma refines_addmx (a b : nat) (X Y : 'M[R]_(a, b)) (sX sY : @seqmx R)
    (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX)
    (rY : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) Y sY) :
  refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) (X + Y) (add_seqmx sX sY).
Proof. exact: refines_apply. Qed.

Lemma refines_oppmx (a b : nat) (X : 'M[R]_(a, b)) (sX : @seqmx R)
    (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX) :
  refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) (- X) (opp_seqmx sX).
Proof. exact: refines_apply. Qed.

Section System.
Variables (m n p : nat).
Variables (F : 'M[R]_n) (G : 'M[R]_(n, m)) (H : 'M[R]_(p, n)).
Variables (Q : 'M[R]_m) (Rm : 'M[R]_p).

Variables (sF sG sH sQ sRm : @seqmx R).
Hypothesis rF : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) F sF.
Hypothesis rG : refines (Rseqmx (nat_Rxx n) (nat_Rxx m)) G sG.
Hypothesis rH : refines (Rseqmx (nat_Rxx p) (nat_Rxx n)) H sH.
Hypothesis rQ : refines (Rseqmx (nat_Rxx m) (nat_Rxx m)) Q sQ.
Hypothesis rRm : refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) Rm sRm.

Variable cinv : @seqmx R -> @seqmx R.
Hypothesis cinv_correct : forall (S : 'M[R]_p) (sS : @seqmx R),
  refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) S sS ->
  refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) (invmx S) (cinv sS).

Lemma predict_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
    (gpredict_cov conj F G Q P) (predict_cov_seqmx conj m n sF sG sQ sP).
Proof.
  rewrite /gpredict_cov /predict_cov_seqmx.
  have rX := refines_mulmx (refines_mulmx rF rP) (refines_ctr_seqmx rF).
  have rY := refines_mulmx (refines_mulmx rG rQ) (refines_ctr_seqmx rG).
  exact: refines_apply.
Qed.

Lemma innov_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx p) (nat_Rxx p))
    (ginnov_cov conj H Rm P) (innov_cov_seqmx conj n p sH sRm sP).
Proof.
  rewrite /ginnov_cov /innov_cov_seqmx.
  have rX := refines_mulmx (refines_mulmx rH rP) (refines_ctr_seqmx rH).
  exact: refines_apply.
Qed.

Lemma kalman_gain_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx p))
    (gkalman_gain conj H Rm P)
    (kalman_gain_seqmx conj n p sH sRm cinv sP).
Proof.
  rewrite /gkalman_gain /kalman_gain_seqmx.
  have rinv := cinv_correct (innov_cov_seqmx_correct rP).
  exact: (refines_mulmx (refines_mulmx rP (refines_ctr_seqmx rH)) rinv).
Qed.

Lemma update_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
    (gupdate_cov conj H Rm P)
    (update_cov_seqmx conj n p sH sRm cinv sP).
Proof.
  rewrite /gupdate_cov /update_cov_seqmx.
  have rK := kalman_gain_seqmx_correct rP.
  have rKH := refines_mulmx rK rH.
  have r1 := Rseqmx_1 R (nat_Rxx n).
  have rsub := refines_addmx r1 (refines_oppmx rKH).
  exact: (refines_mulmx rsub rP).
Qed.

Lemma riccati_step_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
    (griccati_step conj F G H Q Rm P)
    (riccati_step_seqmx conj m n p sF sG sH sQ sRm cinv sP).
Proof.
  rewrite /griccati_step /riccati_step_seqmx.
  exact: (update_cov_seqmx_correct (predict_cov_seqmx_correct rP)).
Qed.

Lemma riccati_iter_seqmx_correct (k : nat) (P0 : 'M[R]_n) (sP0 : @seqmx R)
    (rP0 : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P0 sP0) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
    (iter k (griccati_step conj F G H Q Rm) P0)
    (iter k (riccati_step_seqmx conj m n p sF sG sH sQ sRm cinv) sP0).
Proof.
  elim: k => [|k IHk] /=; first exact: rP0.
  exact: (riccati_step_seqmx_correct IHk).
Qed.

End System.
End RefineRiccati.

Section ScalarInverse.
Variable K : fieldType.

Lemma invmx_1x1 (S : 'M[K]_1) : invmx S = map_mx GRing.inv S.
Proof.
  rewrite {1}[S]mx11_scalar invmx_scalar.
  by rewrite [X in _ = X]mx11_scalar mxE.
Qed.
End ScalarInverse.

Local Notation i1of2 := (lift ord0 ord0).

Lemma ord2_eq (i : 'I_2) : {i = ord0} + {i = i1of2}.
Proof.
  case: i => [[|[|m]] pf]; [left|right|]; try by apply: val_inj.
  by [].
Qed.

Lemma det22 (R : comRingType) (S : 'M[R]_2) :
  \det S = S ord0 ord0 * S i1of2 i1of2 - S ord0 i1of2 * S i1of2 ord0.
Proof.
  rewrite (expand_det_row S ord0) big_ord_recl big_ord1.
  rewrite /cofactor !det_mx11 !mxE /=.
  rewrite expr0 mul1r expr1 mulN1r mulrN.
  have l2 : lift i1of2 (ord0 : 'I_1) = ord0 :> 'I_2 by apply: val_inj.
  by rewrite l2.
Qed.

Lemma adj22 (R : comRingType) (S : 'M[R]_2) :
  \adj S = (S ord0 ord0 + S i1of2 i1of2)%:M - S.
Proof.
  have lb : lift i1of2 (ord0 : 'I_1) = ord0 :> 'I_2 by apply: val_inj.
  have b1 : bump 0 0 = 1 by [].
  apply/matrixP => i j; rewrite !mxE /cofactor.
  case: (ord2_eq i) => ->; case: (ord2_eq j) => ->;
    rewrite !det_mx11 !mxE /=.
  - by rewrite expr0 mul1r mulr1n (addrC (S ord0 ord0)) addrK.
  - by rewrite b1 lb expr1 mulN1r mulr0n sub0r.
  - by rewrite b1 lb expr1 mulN1r mulr0n sub0r.
  - by rewrite b1 lb exprD !expr1 mulrNN !mul1r mulr1n addrK.
Qed.

Section EffInverse2.
Context (C : Type).
Context `{!zero_of C, !opp_of C, !add_of C, !mul_of C, !inv_of C}.

Definition cinv2 (sS : @seqmx C) : @seqmx C :=
  let a := nth 0%C (nth [::] sS 0) 0 in
  let b := nth 0%C (nth [::] sS 0) 1 in
  let c := nth 0%C (nth [::] sS 1) 0 in
  let d := nth 0%C (nth [::] sS 1) 1 in
  let di := (a * d + - (b * c))%C^-1%C in
  [:: [:: (d * di)%C ; ((- b) * di)%C ];
      [:: ((- c) * di)%C ; (a * di)%C ] ].
End EffInverse2.

Section Inverse2Correct.
Variable F : fieldType.

Lemma seqmxE m n (A : 'M[F]_(m, n)) (sA : @seqmx F) (i : 'I_m) (j : 'I_n) :
  refines (Rseqmx (nat_Rxx m) (nat_Rxx n)) A sA ->
  A i j = nth 0%C (nth [::] sA i) j.
Proof. by rewrite refinesE => -[A' M _ _ hel]; apply: hel. Qed.

Lemma cinv2_correct (S : 'M[F]_2) (sS : @seqmx F) :
  S \in unitmx ->
  refines (Rseqmx (nat_Rxx 2) (nat_Rxx 2)) S sS ->
  refines (Rseqmx (nat_Rxx 2) (nat_Rxx 2)) (invmx S) (cinv2 sS).
Proof.
  move=> Sunit rS.
  have HdetE : \det S = S ord0 ord0 * S i1of2 i1of2
                        + - (S ord0 i1of2 * S i1of2 ord0).
    by rewrite det22.
  have HinvE : invmx S = (\det S)^-1 *: \adj S by rewrite /invmx ifT.
  have e00 : nth 0%C (nth [::] sS 0) 0 = S ord0 ord0
    by rewrite (seqmxE ord0 ord0 rS).
  have e01 : nth 0%C (nth [::] sS 0) 1 = S ord0 i1of2
    by rewrite (seqmxE ord0 i1of2 rS).
  have e10 : nth 0%C (nth [::] sS 1) 0 = S i1of2 ord0
    by rewrite (seqmxE i1of2 ord0 rS).
  have e11 : nth 0%C (nth [::] sS 1) 1 = S i1of2 i1of2
    by rewrite (seqmxE i1of2 i1of2 rS).
  rewrite refinesE; constructor => //.
  - by case=> [|[|i]].
  move=> i j.
  rewrite HinvE.
  case: (ord2_eq i) => ->; case: (ord2_eq j) => ->;
    rewrite /cinv2 /mul_op /add_op /opp_op /inv_op
            /ring_mul /ring_add /ring_opp /ring_inv /=
            e00 e01 e10 e11 adj22 !mxE HdetE /=.
  - by rewrite mulr1n (addrC (S ord0 ord0) (S i1of2 i1of2)) addrK mulrC.
  - by rewrite mulr0n sub0r mulrC.
  - by rewrite mulr0n sub0r mulrC.
  - by rewrite mulr1n addrK mulrC.
Qed.
End Inverse2Correct.

Section BridgeC.
Variable ℂ : numClosedFieldType.
Variables (m n p : nat).
Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
Variables (Q : 'M[ℂ]_m) (Rm : 'M[ℂ]_p).

Lemma gpredict_cov_bridge (P : 'M[ℂ]_n) :
  gpredict_cov conjC F G Q P = predict_cov F G Q P.
Proof. by []. Qed.

Lemma griccati_step_bridge (P : 'M[ℂ]_n) :
  griccati_step conjC F G H Q Rm P = riccati_step F G H Q Rm P.
Proof. by []. Qed.

Variables (sF sG sH sQ sRm : @seqmx ℂ).
Hypothesis rF : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) F sF.
Hypothesis rG : refines (Rseqmx (nat_Rxx n) (nat_Rxx m)) G sG.
Hypothesis rH : refines (Rseqmx (nat_Rxx p) (nat_Rxx n)) H sH.
Hypothesis rQ : refines (Rseqmx (nat_Rxx m) (nat_Rxx m)) Q sQ.
Hypothesis rRm : refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) Rm sRm.
Variable cinv : @seqmx ℂ -> @seqmx ℂ.
Hypothesis cinv_correct : forall (S : 'M[ℂ]_p) (sS : @seqmx ℂ),
  refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) S sS ->
  refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) (invmx S) (cinv sS).

Corollary kalman_riccati_step_seqmx_correct (P : 'M[ℂ]_n) (sP : @seqmx ℂ)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
    (riccati_step F G H Q Rm P)
    (riccati_step_seqmx conjC m n p sF sG sH sQ sRm cinv sP).
Proof.
  rewrite -griccati_step_bridge.
  apply: riccati_step_seqmx_correct; assumption.
Qed.
End BridgeC.

Section ConcreteRat.

Existing Instance Rseqmx_map_seqmx.

Definition cinv1 (sS : @seqmx rat) : @seqmx rat := map_seqmx GRing.inv sS.

#[local] Instance refines_invQ :
  refines (@eq (rat -> rat)) GRing.inv GRing.inv := trivial_refines erefl.

Lemma cinv1_correct (S : 'M[rat]_1) (sS : @seqmx rat)
    (rS : refines (Rseqmx (nat_Rxx 1) (nat_Rxx 1)) S sS) :
  refines (Rseqmx (nat_Rxx 1) (nat_Rxx 1)) (invmx S) (cinv1 sS).
Proof.
  rewrite invmx_1x1 /cinv1.
  exact: (refines_apply
            (refines_apply (Rseqmx_map_seqmx _ _) refines_invQ) rS).
Qed.

Lemma rseqmx_11 (a : rat) :
  refines (Rseqmx (nat_Rxx 1) (nat_Rxx 1)) (a%:M : 'M[rat]_1) [:: [:: a]].
Proof.
  rewrite refinesE; constructor.
  - by [].
  - by case=> [|?].
  - by move=> i j; rewrite !ord1 mxE eqxx mulr1n.
Qed.

Definition exF : 'M[rat]_1 := (2%:R)%:M.
Definition exG : 'M[rat]_1 := 1%:M.
Definition exH : 'M[rat]_1 := 1%:M.
Definition exQ : 'M[rat]_1 := 1%:M.
Definition exR : 'M[rat]_1 := 1%:M.
Definition exP0 : 'M[rat]_1 := 1%:M.

Definition sxF : @seqmx rat := [:: [:: 2%:R : rat]].
Definition sxG : @seqmx rat := [:: [:: 1 : rat]].
Definition sxH : @seqmx rat := [:: [:: 1 : rat]].
Definition sxQ : @seqmx rat := [:: [:: 1 : rat]].
Definition sxR : @seqmx rat := [:: [:: 1 : rat]].
Definition sxP0 : @seqmx rat := [:: [:: 1 : rat]].

Definition ex_step : @seqmx rat -> @seqmx rat :=
  riccati_step_seqmx (idfun : rat -> rat) 1 1 1 sxF sxG sxH sxQ sxR cinv1.

Lemma ex_iter_correct (k : nat) :
  refines (Rseqmx (nat_Rxx 1) (nat_Rxx 1))
    (iter k (griccati_step idfun exF exG exH exQ exR) exP0)
    (iter k ex_step sxP0).
Proof.
  apply: (@riccati_iter_seqmx_correct rat idfun 1 1 1
            exF exG exH exQ exR sxF sxG sxH sxQ sxR
            (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _)
            cinv1 cinv1_correct k exP0 sxP0).
  exact: rseqmx_11.
Qed.

End ConcreteRat.

Definition ex_two : @seqmx rat := iter 2 ex_step sxP0.

Lemma ex_two_val :
  (ex_two == [:: [:: (13%:R / 16%:R : rat)]] :> @seqmx rat) = true.
Proof. by vm_compute. Qed.

Section ConcreteBigQ.
Definition bxF : @seqmx bigQ := [:: [:: 2%bigQ]].
Definition bx1 : @seqmx bigQ := [:: [:: 1%bigQ]].
Definition bcinv (sS : @seqmx bigQ) : @seqmx bigQ := map_seqmx inv_op sS.

Definition bx_step : @seqmx bigQ -> @seqmx bigQ :=
  riccati_step_seqmx (idfun : bigQ -> bigQ) 1 1 1 bxF bx1 bx1 bx1 bx1 bcinv.

Definition bx_two : @seqmx bigQ := iter 2 bx_step bx1.
End ConcreteBigQ.

Section BridgeBigQ.

Notation RC a b := (RseqmxC r_ratBigQ (nat_Rxx a) (nat_Rxx b)).

Variable conj : rat -> rat.
Variable conjC : bigQ -> bigQ.
Context (rconj : refines (r_ratBigQ ==> r_ratBigQ) conj conjC).

Lemma refinesC_ctr (a b : nat) (A : 'M[rat]_(a, b)) (sA : @seqmx bigQ)
    (rA : refines (RC a b) A sA) :
  refines (RC b a) (map_mx conj A^T) (ctr_seqmx conjC a b sA).
Proof.
  rewrite /ctr_seqmx.
  exact: (refines_apply
            (refines_apply (refine_map_seqmx r_ratBigQ r_ratBigQ b a) rconj)
            (refines_apply (refine_trseqmx r_ratBigQ a b) rA)).
Qed.

Lemma refinesC_mulmx (a b c : nat) (X : 'M[rat]_(a, b)) (Y : 'M[rat]_(b, c))
    (sX sY : @seqmx bigQ)
    (rX : refines (RC a b) X sX) (rY : refines (RC b c) Y sY) :
  refines (RC a c) (X *m Y) (@hmul_op _ _ _ a b c sX sY).
Proof. exact: refines_apply. Qed.

Lemma refinesC_addmx (a b : nat) (X Y : 'M[rat]_(a, b)) (sX sY : @seqmx bigQ)
    (rX : refines (RC a b) X sX) (rY : refines (RC a b) Y sY) :
  refines (RC a b) (X + Y) (add_seqmx sX sY).
Proof. exact: refines_apply. Qed.

Lemma refinesC_oppmx (a b : nat) (X : 'M[rat]_(a, b)) (sX : @seqmx bigQ)
    (rX : refines (RC a b) X sX) :
  refines (RC a b) (- X) (opp_seqmx sX).
Proof. exact: refines_apply. Qed.

Section System.
Variables (m n p : nat).
Variables (F : 'M[rat]_n) (G : 'M[rat]_(n, m)) (H : 'M[rat]_(p, n)).
Variables (Q : 'M[rat]_m) (Rm : 'M[rat]_p).
Variables (sF sG sH sQ sRm : @seqmx bigQ).
Hypothesis rF : refines (RC n n) F sF.
Hypothesis rG : refines (RC n m) G sG.
Hypothesis rH : refines (RC p n) H sH.
Hypothesis rQ : refines (RC m m) Q sQ.
Hypothesis rRm : refines (RC p p) Rm sRm.

Variable cinv : @seqmx bigQ -> @seqmx bigQ.
Hypothesis cinv_correct : forall (S : 'M[rat]_p) (sS : @seqmx bigQ),
  refines (RC p p) S sS -> refines (RC p p) (invmx S) (cinv sS).

Lemma predict_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
    (rP : refines (RC n n) P sP) :
  refines (RC n n)
    (gpredict_cov conj F G Q P) (predict_cov_seqmx conjC m n sF sG sQ sP).
Proof.
  rewrite /gpredict_cov /predict_cov_seqmx.
  have rX := refinesC_mulmx (refinesC_mulmx rF rP) (refinesC_ctr rF).
  have rY := refinesC_mulmx (refinesC_mulmx rG rQ) (refinesC_ctr rG).
  exact: refines_apply.
Qed.

Lemma innov_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
    (rP : refines (RC n n) P sP) :
  refines (RC p p)
    (ginnov_cov conj H Rm P) (innov_cov_seqmx conjC n p sH sRm sP).
Proof.
  rewrite /ginnov_cov /innov_cov_seqmx.
  have rX := refinesC_mulmx (refinesC_mulmx rH rP) (refinesC_ctr rH).
  exact: refines_apply.
Qed.

Lemma kalman_gain_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
    (rP : refines (RC n n) P sP) :
  refines (RC n p)
    (gkalman_gain conj H Rm P)
    (kalman_gain_seqmx conjC n p sH sRm cinv sP).
Proof.
  rewrite /gkalman_gain /kalman_gain_seqmx.
  have rinv := cinv_correct (innov_cov_seqmxC rP).
  exact: (refinesC_mulmx (refinesC_mulmx rP (refinesC_ctr rH)) rinv).
Qed.

Lemma update_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
    (rP : refines (RC n n) P sP) :
  refines (RC n n)
    (gupdate_cov conj H Rm P)
    (update_cov_seqmx conjC n p sH sRm cinv sP).
Proof.
  rewrite /gupdate_cov /update_cov_seqmx.
  have rK := kalman_gain_seqmxC rP.
  have rKH := refinesC_mulmx rK rH.
  have r1 : refines (RC n n) 1%:M (seqmx1 n) by tc.
  have rsub := refinesC_addmx r1 (refinesC_oppmx rKH).
  exact: (refinesC_mulmx rsub rP).
Qed.

Lemma riccati_step_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
    (rP : refines (RC n n) P sP) :
  refines (RC n n)
    (griccati_step conj F G H Q Rm P)
    (riccati_step_seqmx conjC m n p sF sG sH sQ sRm cinv sP).
Proof.
  rewrite /griccati_step /riccati_step_seqmx.
  exact: (update_cov_seqmxC (predict_cov_seqmxC rP)).
Qed.

Lemma riccati_iter_seqmxC (k : nat) (P0 : 'M[rat]_n) (sP0 : @seqmx bigQ)
    (rP0 : refines (RC n n) P0 sP0) :
  refines (RC n n)
    (iter k (griccati_step conj F G H Q Rm) P0)
    (iter k (riccati_step_seqmx conjC m n p sF sG sH sQ sRm cinv) sP0).
Proof.
  elim: k => [|k IHk] /=; first exact: rP0.
  exact: (riccati_step_seqmxC IHk).
Qed.

End System.
End BridgeBigQ.

Section ConcreteBigQRefine.

Notation RC11 := (RseqmxC r_ratBigQ (nat_Rxx 1) (nat_Rxx 1)).

Lemma rb2 : refines r_ratBigQ (2%:R : rat) 2%bigQ.
Proof.
  have e : cast_op 2%N = 2%bigQ by vm_compute.
  rewrite -e (_ : (2%:R : rat) = 2%:~R); last by rewrite pmulrn.
  exact: (refines_apply refine_ratBigQ_of_nat (trivial_refines (nat_Rxx 2))).
Qed.

Lemma rb1 : refines r_ratBigQ (1 : rat) 1%bigQ.
Proof. exact: refine_ratBigQ_one. Qed.

Lemma rseqmxC_11 (a : rat) (b : bigQ) (rab : refines r_ratBigQ a b) :
  refines RC11 (a%:M : 'M[rat]_1) [:: [:: b]].
Proof.
  apply: (refines_trans (b := [:: [:: a]]) _ (rseqmx_11 a)).
  rewrite refinesE.
  apply: cons_R; last exact: nil_R.
  apply: cons_R; last exact: nil_R.
  exact: refinesP rab.
Qed.

Lemma refines_idfunQ : refines (r_ratBigQ ==> r_ratBigQ) idfun idfun.
Proof. by rewrite refinesE => x y h; apply: h. Qed.

Lemma bcinv_correctC (S : 'M[rat]_1) (sS : @seqmx bigQ) :
  refines RC11 S sS -> refines RC11 (invmx S) (bcinv sS).
Proof.
  move=> rS; rewrite invmx_1x1 /bcinv.
  exact: (refines_apply
            (refines_apply (refine_map_seqmx r_ratBigQ r_ratBigQ 1 1)
                           refine_ratBigQ_inv) rS).
Qed.

Lemma bx_iter_correct (k : nat) :
  refines RC11
    (iter k (griccati_step idfun exF exG exH exQ exR) exP0)
    (iter k bx_step bx1).
Proof.
  apply: (@riccati_iter_seqmxC idfun idfun refines_idfunQ 1 1 1
            exF exG exH exQ exR bxF bx1 bx1 bx1 bx1
            (rseqmxC_11 rb2) (rseqmxC_11 rb1) (rseqmxC_11 rb1)
            (rseqmxC_11 rb1) (rseqmxC_11 rb1)
            bcinv bcinv_correctC k exP0 bx1).
  exact: (rseqmxC_11 rb1).
Qed.

End ConcreteBigQRefine.
