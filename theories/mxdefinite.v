(*
  Положительная и неотрицательная определённость над алг. замкнутым полем.

  Эрмитова матрица: `A = A^t*`
  (где `^t* = (^T)^conjC` из `mathcomp.algebra.sesquilinear`).

  Доказательства адаптированы из `CoqQ/src/mxpred.v`
  (`psdmxD`, `psdmx_bimap_closed_gen`, `psdmx_dot`).
*)

Set Warnings "-coercions".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.


Section MatrixDefiniteness.

  Variable (ℂ : numClosedFieldType) (n : nat).

  Definition psd n (A : 'M[ℂ]_n) : Prop :=
    A = A^t* /\ forall (v : 'cV[ℂ]_n), 0 <= \tr (v^t* *m A *m v).

  Definition pd n (A : 'M[ℂ]_n) : Prop :=
    A = A^t* /\ forall (v : 'cV[ℂ]_n), v != 0 -> 0 < \tr (v^t* *m A *m v).

  Implicit Types (A B C : 'M[ℂ]_n) (v : 'cV[ℂ]_n).

  (* Положительно определённая матрица определена неотрицательно. *)
  Lemma pd_psd A :
    pd A -> psd A.
  Proof.
    case=> Asym pdA; split=> // v.
    have [/eqP->|vNZ] := boolP (v == 0).
      by rewrite trmxC0 mul0mx mulmx0 mxtrace0 lexx.
    exact: ltW (pdA v vNZ).
  Qed.

  (* Нулевая матрица определена неотрицательно. *)
  Lemma psd0 :
    psd (0 : 'M[ℂ]_n).
  Proof.
    split; first by rewrite trmxC0.
    by move=> v; rewrite mulmx0 mul0mx mxtrace0 lexx.
  Qed.

  (* Сумма неотрицательных матриц определена неотрицательно. *)
  Lemma psd_add A B :
    psd A -> psd B -> psd (A + B).
  Proof.
    move=> [Asym psdA] [Bsym psdB]; split.
      by rewrite trmxC_add -Asym -Bsym.
    move=> v; rewrite mulmxDr mulmxDl mxtraceD.
    exact: addr_ge0 (psdA v) (psdB v).
  Qed.

  (* Определённость матрицы сохраняется при эрмитовой конгруэнтности. *)
  Lemma psd_congr m (A : 'M[ℂ]_m) (P : 'M[ℂ]_(m, n)) :
    @psd m A -> @psd n (P^t* *m A *m P).
  Proof.
    move=> [Asym hA]; split.
    - by rewrite trmxC_mul trmxC_mul trmxCK mulmxA -Asym.
    - move=> v.
      rewrite !mulmxA -mulmxA -trmxC_mul.
      exact: hA (P *m v).
  Qed.

  (* Определённость матрицы сохраняется при эрмитовой конгруэнтности (слева). *)
  Lemma psd_lcongr m (A : 'M[ℂ]_m) (P : 'M[ℂ]_(n, m)) :
    @psd m A -> @psd n (P *m A *m P^t*).
  Proof.
    move=> psdA.
    have -> : (P *m A *m P^t*) = (P^t*)^t* *m A *m P^t* by rewrite trmxCK.
    exact: psd_congr psdA.
  Qed.

  (* i-й диагональный элемент через delta_mx. *)
  Lemma qf_delta (M : 'M[ℂ]_n) i :
    \tr ((delta_mx i ord0 : 'cV[ℂ]_n)^t* *m M *m delta_mx i ord0) = M i i.
  Proof.
    have del_eq : (delta_mx i ord0 : 'cV[ℂ]_n)^t* = (delta_mx ord0 i : 'rV[ℂ]_n).
      by rewrite trmx_delta map_delta_mx.
    rewrite del_eq -rowE trace_mx11 mxE (bigD1 i) //= big1 ?addr0; last first.
      move=> j neji; rewrite !mxE eqxx andbT.
      by rewrite (negbTE neji) mulr0.
    by rewrite !mxE !eqxx /= mulr1.
  Qed.

  (* След неотрицательно определённой матрицы неотрицателен. *)
  Lemma psd_tr_ge0 A :
    psd A -> 0 <= \tr A.
  Proof.
    case=> _ psdA; rewrite /mxtrace; apply: sumr_ge0 => i _.
    by rewrite -(qf_delta A i); exact: psdA (delta_mx i ord0).
  Qed.

  (* Положительно определённая матрица обратима. *)
  Lemma pd_invertible A :
    pd A -> A \in unitmx.
  Proof.
    move=> [Asym pdA]; apply: contraT => Anu.
    have cokerNZ : cokermx A != 0 by rewrite cokermx_eq0 row_full_unit.
    have /matrix0Pn [i [j Cij_nz]] := cokerNZ.
    pose u := cokermx A *m delta_mx j ord0 : 'cV[ℂ]_n.
    have uNZ : u != 0.
      apply/cV0Pn; exists i; rewrite /u -colE mxE; exact: Cij_nz.
    have Au0 : A *m u = 0 by rewrite /u mulmxA mulmx_coker mul0mx.
    by move: (pdA u uNZ); rewrite -mulmxA Au0 mulmx0 mxtrace0 ltxx.
  Qed.

  (*
    Зануление квадратичной формы положительно определённой матрицы влечёт
    зануление вектора: pd R -> u† R u = 0 -> u = 0
    (контрапозиция определения `pd`).
  *)
  Lemma pd_qf0_col0 p (R : 'M[ℂ]_p) (u : 'cV[ℂ]_p) :
    pd R -> \tr (u^t* *m R *m u) = 0 -> u = 0.
  Proof.
    move=> Rpd qf0; apply/eqP; apply: contraT => uNZ.
    by have := (proj2 Rpd) u uNZ; rewrite qf0 ltxx.
  Qed.

  (*
    Сумма положительно определённой и неотрицательно определённой матриц
    положительно определена.
  *)
  Lemma pd_add A B :
    pd A -> psd B -> pd (A + B).
  Proof.
    move=> [Asym pdA] [Bsym psdB]; split.
      by rewrite trmxC_add -Asym -Bsym.
    move=> v vNZ.
    rewrite mulmxDr mulmxDl mxtraceD addrC.
    exact: ltr_wpDl (psdB v) (pdA v vNZ).
  Qed.

  (* Обратная к положительно определённой тоже положительно определена. *)
  Lemma pd_inv A :
    pd A -> pd (invmx A).
  Proof.
    move=> pdA; have Aunit : A \in unitmx := pd_invertible pdA.
    case: pdA => Asym pdAq; split.
      by rewrite trmx_inv map_invmx -Asym.
    move=> v vNZ.
    pose w := invmx A *m v.
    have vw : v = A *m w by rewrite /w mulmxA mulmxV // mul1mx.
    have wNZ : w != 0.
      apply: contraNneq vNZ => w0.
      by rewrite vw w0 mulmx0.
    have eq_qform : v^t* *m invmx A *m v = w^t* *m A *m w.
      rewrite vw trmxC_mul -Asym.
      rewrite [in LHS]mulmxA.
      rewrite -[in LHS](mulmxA _ (invmx A) A).
      by rewrite mulVmx // mulmx1.
    by rewrite eq_qform; exact: pdAq.
  Qed.

End MatrixDefiniteness.
