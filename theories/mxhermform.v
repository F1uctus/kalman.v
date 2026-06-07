From HB Require Import structures.
From Kalman Require Import mxnotation mxdefinite mxloewner mxherm.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(* Эрмитовы формы. Задаются неотрицательно определёнными матрицами. *)
Section PSDQuadraticForms.

  Variable (ℂ : numClosedFieldType) (n : nat).

  Implicit Types (M : 'M[ℂ]_n) (v : 'cV[ℂ]_n).

  Lemma qf_psd_real M v : psd M -> \tr (v^t* *m M *m v) \is Num.real.
  Proof.
    by case=> _ HM; exact: ger0_real (HM v).
  Qed.

  Lemma qf_psd_ge0 M v : psd M -> 0 <= \tr (v^t* *m M *m v).
  Proof.
    by case=> _ HM; exact: HM.
  Qed.

  Lemma qf_psd_le (A B : 'M[ℂ]_n) v :
    psd_le A B ->
    \tr (v^t* *m A *m v) <= \tr (v^t* *m B *m v).
  Proof.
    rewrite /psd_le=> [[Hsym HBA]].
    have := HBA v.
    by rewrite mulmxBr mulmxBl linearB /= subr_ge0.
  Qed.

  (* 'Перекрёстная' эрмитова форма с разными векторами слева/справа. *)
  Lemma qf_delta_cross M (i j : 'I_n) :
    \tr ((delta_mx i ord0 : 'cV[ℂ]_n)^t* *m M *m delta_mx j ord0) = M i j.
  Proof.
    have del_eq : (delta_mx i ord0 : 'cV[ℂ]_n)^t* = (delta_mx ord0 i : 'rV[ℂ]_n).
      by rewrite trmx_delta map_delta_mx.
    rewrite del_eq -rowE trace_mx11 mxE (bigD1 j)//= big1; last first.
      by move=> k nekj; rewrite !mxE eqxx andbT (negbTE nekj) mulr0.
    by rewrite !mxE !eqxx /= mulr1 addr0.
  Qed.

  (* Разложение эрмитовой формы по сумме векторов. *)
  Lemma qf_decomp M (v1 v2 : 'cV[ℂ]_n) :
    \tr ((v1 + v2)^t* *m M *m (v1 + v2)) =
    \tr (v1^t* *m M *m v1) + \tr (v1^t* *m M *m v2)
    + \tr (v2^t* *m M *m v1) + \tr (v2^t* *m M *m v2).
  Proof.
    have step : (v1 + v2)^t* *m M *m (v1 + v2)
              = v1^t* *m M *m v1 + v1^t* *m M *m v2
                + (v2^t* *m M *m v1 + v2^t* *m M *m v2).
      by rewrite trmxC_add !mulmxDl !mulmxDr -addrA.
    by rewrite step !linearD/= addrA.
  Qed.

  (*
    Разложение эрмитовой формы по сумме векторов с умножением на скаляр во
    втором слагаемом.
  *)
  Lemma qf_decomp_scaleZ M (v1 v2 : 'cV[ℂ]_n) (a : ℂ) :
    \tr ((v1 + a *: v2)^t* *m M *m (v1 + a *: v2)) =
    \tr (v1^t* *m M *m v1)
    + a * \tr (v1^t* *m M *m v2)
    + a^* * \tr (v2^t* *m M *m v1)
    + (a^* * a) * \tr (v2^t* *m M *m v2).
  Proof.
    have step :
      (v1 + a *: v2)^t* *m M *m (v1 + a *: v2)
    = (v1^t* *m M *m v1 + a *: (v1^t* *m M *m v2))
      + (a^* *: (v2^t* *m M *m v1) + (a^* * a) *: (v2^t* *m M *m v2)).
      by rewrite trmxC_add trmxC_scale !mulmxDl !mulmxDr
                  -!scalemxAl -!scalemxAr scalerA -addrA.
    by rewrite step !linearD/= !linearZ/= addrA.
  Qed.

  Lemma qf_delta_pair M (i j : 'I_n) :
    \tr ((delta_mx i ord0 + delta_mx j ord0 : 'cV[ℂ]_n)^t*
          *m M *m (delta_mx i ord0 + delta_mx j ord0)) =
    M i i + M i j + M j i + M j j.
  Proof.
    by rewrite qf_decomp !qf_delta !qf_delta_cross.
  Qed.

  Lemma qf_delta_pairi M (i j : 'I_n) :
    \tr ((delta_mx i ord0 + 'i *: delta_mx j ord0 : 'cV[ℂ]_n)^t*
          *m M *m (delta_mx i ord0 + 'i *: delta_mx j ord0)) =
    M i i + M j j + 'i * (M i j - M j i).
  Proof.
    rewrite qf_decomp_scaleZ !qf_delta !qf_delta_cross.
    have conji : ('i : ℂ)^* = - 'i by exact: conjCi.
    rewrite conji.
    have miE : (- ('i : ℂ)) * 'i = 1.
      by rewrite mulNr -expr2 sqrCi opprK.
    rewrite miE mul1r mulNr.
    rewrite mulrBr -!addrA; congr (M i i + _).
    rewrite [- _ + M j j]addrC addrA [_ + M j j]addrC.
    by rewrite -addrA.
  Qed.

End PSDQuadraticForms.
