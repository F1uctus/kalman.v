(* https://en.wikipedia.org/wiki/Loewner_order. *)

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section LoewnerOrder.

  Variable (ℂ : numClosedFieldType) (n : nat).

  Implicit Types (A B C : 'M[ℂ]_n).

  (*
    Порядок Лёвнера.

    $forall A, B in CC^(n,n): A <= B <==> B - A$ неотрицательно определена.
  *)
  Definition psd_le n (A B : 'M[ℂ]_n) : Prop := psd (B - A).

  Lemma psd_le_refl A : psd A -> psd_le A A.
  Proof.
    move=> _; rewrite /psd_le subrr; split; first by rewrite trmxC0.
    by move=> v; rewrite mulmx0 mul0mx mxtrace0 lexx.
  Qed.

  Lemma psd_le_trans A B C :
    psd_le A B -> psd_le B C -> psd_le A C.
  Proof.
    rewrite /psd_le => hAB hBC.
    have hSum : psd ((B - A) + (C - B)) := psd_add hAB hBC.
    suff -> : C - A = (B - A) + (C - B) by exact: hSum.
    by rewrite addrC -addrA addrCA [B + (C - B)]addrCA addrN addr0.
  Qed.

  Lemma psd_le_congr p A B (M : 'M[ℂ]_(n, p)) :
    psd_le A B -> psd_le (M^t* *m A *m M) (M^t* *m B *m M).
  Proof.
    rewrite /psd_le => hAB.
    have -> : M^t* *m B *m M - M^t* *m A *m M = M^t* *m (B - A) *m M.
      by rewrite mulmxBr mulmxBl.
    exact: psd_congr hAB.
  Qed.

  (* Лево-конгруэнтная монотонность: A <= B ⇒ M A M† <= M B M†. *)
  Lemma psd_le_lcongr (Mx A B : 'M[ℂ]_n) :
    psd_le A B -> psd_le (Mx *m A *m Mx^t*) (Mx *m B *m Mx^t*).
  Proof.
    move=> hAB.
    have := psd_le_congr (Mx^t*) hAB.
    by rewrite trmxCK.
  Qed.

  Lemma psd_le0_psd A :
    psd_le 0 A <-> psd A.
  Proof.
    by rewrite /psd_le subr0.
  Qed.

  (* Прибавление слева сохраняет порядок. *)
  Lemma psd_le_add2l A B C :
    psd_le A B -> psd_le (C + A) (C + B).
  Proof.
    rewrite /psd_le => hAB.
    by rewrite opprD addrACA subrr add0r.
  Qed.

  (* Прибавление справа сохраняет порядок. *)
  Lemma psd_le_add2r (C A B : 'M[ℂ]_n) :
    psd_le A B -> psd_le (A + C) (B + C).
  Proof.
    rewrite /psd_le=> h.
    by rewrite opprD addrACA subrr addr0.
  Qed.

  (*
    Если A <= B в порядке Лёвнера и A положительно определена, то B положительно
    определена.
  *)
  Lemma psd_le_pd (A B : 'M[ℂ]_n) :
    psd_le A B -> pd A -> pd B.
  Proof.
    move=> hAB hA.
    have hBA : A + (B - A) = B by rewrite addrC subrK.
    by rewrite -hBA; apply: pd_add hA hAB.
  Qed.

  (* Масштабирование порядка Лёвнера неотрицательным вещественным скаляром. *)
  Lemma psd_le_scaler (a : ℂ) (A B : 'M[ℂ]_n) :
    a \is Num.real -> 0 <= a -> psd_le A B -> psd_le (a *: A) (a *: B).
  Proof.
    move=> a_real a_ge0; rewrite /psd_le=> psdD.
    have ->: a *: B - a *: A = a *: (B - A) by rewrite scalerBr.
    case: psdD => Dsym Dqf; split.
    - rewrite trmxC_scale -Dsym.
      have a_conj : a^* = a by apply/CrealP; exact: a_real.
      by rewrite a_conj.
    - move=> v; rewrite -scalemxAr -scalemxAl mxtraceZ.
      by apply: mulr_ge0; [exact: a_ge0 | exact: Dqf].
  Qed.

  (* Неотрицательная определённость масштаба `a *: X` (вещественный a >= 0). *)
  Lemma psd_scaler (a : ℂ) (X : 'M[ℂ]_n) :
    a \is Num.real -> 0 <= a -> psd X -> psd (a *: X).
  Proof.
    move=> a_real a_ge0 psdX.
    have h0 : psd_le 0 X by apply/psd_le0_psd.
    have Hs := psd_le_scaler a_real a_ge0 h0.
    rewrite scaler0 in Hs.
    by apply/psd_le0_psd; exact: Hs.
  Qed.

End LoewnerOrder.
