(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Обращение матрицы методом Фаддеева-Леверье и его корректность.

  Метод Фаддеева-Леверье вычисляет коэффициенты характеристического многочлена и
  обратную матрицу через рекурренту по следу:

  $M_1 = E, c_{n-j} = - tr(A M_j) / j, M_{j+1} = A M_j + c_{n-j} E$,
  $A^{-1} = - c_0^{-1} M_n$.

  Корректность опирается на два факта о присоединённой матрице
  характеристической матрицы $G(x) = adj(xE - A)$ и характеристическом
  многочлене $χ = char_poly A$:

  - тождество Крамера $(xE - A) G(x) = χ(x) E$ (`mul_mx_adj`), откуда
    покоэффициентно извлекается рекурренту для матриц коэффициентов `G` и
    равенство коэффициентов $c_k = χ_k$;
  - тождество Якоби $χ'(x) = tr(G(x))$ (`char_poly_deriv` ниже), откуда
    выводится формула следа $tr(A M_j) = - j χ_{n-j}$, используемая исполняемой
    рекуррентой.

  Тождество Якоби отсутствует в MathComp и CoqEAL, поэтому доказано здесь с нуля
  (через производную определителя как полилинейной функции строк).
*)

Set Warnings "-notation-overridden,-coercions,-default,-ambiguous-paths".

From mathcomp.boot Require Import all_boot.
From mathcomp.fingroup Require Import perm.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra poly mxpoly.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory.
Local Open Scope ring_scope.

(* Тождество Якоби: производная определителя характеристической матрицы. *)

(* Производная постоянного знака `(-1)^m` равна нулю. *)
Lemma deriv_signC (R : ringType) m :
  ((-1 : {poly R}) ^+ m)^`() = 0.
Proof.
  have d1 : (1 : {poly R})^`() = 0 by rewrite -polyC1 derivC.
  have dN : (-1 : {poly R})^`() = 0 by rewrite derivN d1 oppr0.
  elim: m => [|m IH]; first by rewrite expr0 d1.
  by rewrite exprS derivM IH mulr0 addr0 dN mul0r.
Qed.

Lemma deriv_signM (R : ringType) m (p : {poly R}) :
  ((-1) ^+ m * p)^`() = (-1) ^+ m * p^`().
Proof.
  by rewrite derivM deriv_signC mul0r add0r.
Qed.

(* Производная конечного произведения (правило Лейбница). *)
Lemma deriv_prod_seq (R : comRingType) (I : eqType) (s : seq I)
    (f : I -> {poly R}) :
  uniq s ->
  (\prod_(i <- s) f i)^`() =
  \sum_(i <- s) ((f i)^`() * \prod_(j <- s | j != i) f j).
Proof.
  elim: s => [|a s IH]; first by rewrite !big_nil -polyC1 derivC.
  rewrite cons_uniq => /andP[aNs us].
  rewrite big_cons derivM IH //.
  rewrite [RHS]big_cons; congr (_ + _).
    congr (_ * _).
    rewrite big_cons; case: ifP => [Ht|_]; first by move: Ht; rewrite eqxx.
    rewrite -[RHS]big_filter (_ : [seq j <- s | j != a] = s) //.
    by apply/all_filterP/allP => j js; apply: contraNneq aNs => <-.
  rewrite mulr_sumr.
  apply: eq_big_seq => i ixs.
  have ai : a != i by apply: contraNneq aNs => ->.
  rewrite big_cons; case: ifP => [_|Hf]; last by move: ai; rewrite Hf.
  by rewrite mulrCA.
Qed.

Lemma deriv_prod (R : comRingType) (I : finType) (f : I -> {poly R}) :
  (\prod_i f i)^`() = \sum_i ((f i)^`() * \prod_(j | j != i) f j).
Proof.
  exact: deriv_prod_seq (index_enum_uniq I).
Qed.

(* Производная определителя матрицы многочленов по строкам. *)
Lemma det_deriv (R : comRingType) n (M : 'M[{poly R}]_n) :
  (\det M)^`() =
  \sum_(k : 'I_n)
    \det (\matrix_(i, j) (if i == k then (M i j)^`() else M i j)).
Proof.
  rewrite /determinant (big_morph _ (@derivD _) (@deriv0 _)).
  transitivity
    (\sum_(s : 'S_n) \sum_(k : 'I_n)
      (-1) ^+ s * ((M k (s k))^`() * \prod_(i | i != k) M i (s i))).
    apply: eq_bigr => s _.
    by rewrite deriv_signM deriv_prod mulr_sumr.
  rewrite exchange_big.
  apply: eq_bigr => k _.
  rewrite /determinant; apply: eq_bigr => s _.
  rewrite [X in _ = _ * X](bigD1 k) // mxE (ifT _ _ (eqxx k)).
  congr (_ * (_ * _)).
  by apply: eq_bigr => i ineqk; rewrite mxE (ifF _ _ (negbTE ineqk)).
Qed.

(*
  Поэлементная производная характеристической матрицы есть элемент единичной.
*)
Lemma char_poly_mx_deriv (R : comRingType) n (A : 'M[R]_n) (i j : 'I_n) :
  ((char_poly_mx A) i j)^`() = (1%:M : 'M[{poly R}]_n) i j.
Proof.
  by rewrite /char_poly_mx !mxE derivB derivMn derivX derivC subr0.
Qed.

(* Дополнение по строке k не зависит от строки k. *)
Lemma cofactor_repl (R : comRingType) n (B M : 'M[{poly R}]_n) (k j : 'I_n) :
  (forall i l, i != k -> B i l = M i l) ->
  cofactor B k j = cofactor M k j.
Proof.
  move=> hBM; rewrite /cofactor; congr (_ * \det _).
  apply/matrixP => a b; rewrite !mxE hBM //.
  by rewrite lift_eqF.
Qed.

(*
  Определитель характеристической матрицы со строкой k, заменённой на её
  производную, равен дополнению (k, k).
*)
Lemma det_repl_row (R : comRingType) n (A : 'M[R]_n) (k : 'I_n) :
  \det (\matrix_(i, j)
          (if i == k then (char_poly_mx A i j)^`() else char_poly_mx A i j))
  = cofactor (char_poly_mx A) k k.
Proof.
  set Rpl := (X in \det X).
  have hrow : forall j, Rpl k j = (1%:M : 'M[{poly R}]_n) k j.
    by move=> j; rewrite mxE (ifT _ _ (eqxx k)) char_poly_mx_deriv.
  have hcof : forall j, cofactor Rpl k j = cofactor (char_poly_mx A) k j.
    move=> j; apply: cofactor_repl => i l iNk.
    by rewrite mxE (ifF _ _ (negbTE iNk)).
  rewrite (expand_det_row _ k).
  under eq_bigr => j _ do rewrite hrow hcof.
  rewrite (bigD1 k) //.
  rewrite big1; last first.
    move=> j jNk.
    have -> : (1%:M : 'M[{poly R}]_n) k j = 0
      by rewrite mxE eq_sym (negbTE jNk) mulr0n.
    by rewrite mul0r.
  have -> : (1%:M : 'M[{poly R}]_n) k k = 1 by rewrite mxE eqxx mulr1n.
  by rewrite mul1r; apply: addr0.
Qed.

(*
  Тождество Якоби.

  Производная характеристического многочлена равна следу присоединённой матрицы
  характеристической матрицы: $chi'(x) = "tr"("adj"(x E - A))$, где
  $chi = "char_poly" A$. Тождество отсутствует в MathComp и CoqEAL; оно даёт
  формулу следа, на которой основана рекуррента метода Фаддеева-Леверье.
*)
Lemma char_poly_deriv (R : comRingType) n (A : 'M[R]_n) :
  (char_poly A)^`() = \tr (\adj (char_poly_mx A)).
Proof.
  rewrite /char_poly det_deriv /mxtrace.
  apply: eq_bigr => k _.
  by rewrite mxE det_repl_row.
Qed.

(* k-th coefficient matrix of a matrix of polynomials *)
Definition pcoef (R : ringType) n (k : nat) (M : 'M[{poly R}]_n) : 'M[R]_n :=
  \matrix_(i, j) (M i j)`_k.

Section PCoef.

  Variable R : comRingType.

  Variable n : nat.
  Implicit Types (M N : 'M[{poly R}]_n).

  Lemma pcoefD k M N :
    pcoef k (M + N) = pcoef k M + pcoef k N.
  Proof.
    by apply/matrixP => i j; rewrite !mxE coefD.
  Qed.

  Lemma pcoef_scaleX k M :
    pcoef k.+1 ('X *: M) = pcoef k M.
  Proof.
    by apply/matrixP => i j; rewrite !mxE coefXM.
  Qed.

  Lemma pcoef0_scaleX M :
    pcoef 0 ('X *: M) = 0.
  Proof.
    by apply/matrixP => i j; rewrite !mxE coefXM eqxx.
  Qed.

  Lemma pcoef_constmul k (B : 'M[R]_n) M :
    pcoef k ((map_mx (@polyC R) B) *m M) = B *m pcoef k M.
  Proof.
    apply/matrixP => i j; rewrite !mxE coef_sum.
    by apply: eq_bigr => l _; rewrite !mxE coefCM.
  Qed.

  Lemma pcoef_scalar k (c : {poly R}) :
    pcoef k (c%:M : 'M[{poly R}]_n) = (c`_k) *: 1%:M.
  Proof. by apply/matrixP => i j; rewrite !mxE coefMn mulrnAr mulr1. Qed.

End PCoef.

Section PCoefB.

  Variable R : comRingType.

  Variable n : nat.
  Implicit Types (M N : 'M[{poly R}]_n).

  Lemma pcoefN k M : pcoef k (- M) = - pcoef k M.
  Proof.
    by apply/matrixP => i j; rewrite !mxE coefN.
  Qed.

  Lemma pcoefB k M N : pcoef k (M - N) = pcoef k M - pcoef k N.
  Proof.
    by rewrite pcoefD pcoefN.
  Qed.

End PCoefB.

Section AdjRec.

  Variable R : comRingType.

  Variable n' : nat.
  Local Notation n := n'.+1.
  Variable A : 'M[R]_n.
  Local Notation cpm := (char_poly_mx A).
  Local Notation G := (\adj (char_poly_mx A)).
  Local Notation chi := (char_poly A).

  Lemma adjE :
    cpm *m G = chi%:M.
  Proof.
    by rewrite mul_mx_adj.
  Qed.

  Lemma cpmGE :
    cpm *m G = 'X *: G - (map_mx (@polyC R) A) *m G.
  Proof.
    by rewrite {1}/char_poly_mx mulmxBl mul_scalar_mx.
  Qed.

  Lemma recS k :
    pcoef k G = A *m pcoef k.+1 G + (chi`_(k.+1)) *: 1%:M.
  Proof.
    have key : pcoef k G - A *m pcoef k.+1 G = (chi`_(k.+1)) *: 1%:M.
      by rewrite -pcoef_scaleX -pcoef_constmul -pcoefB -cpmGE adjE pcoef_scalar.
    by rewrite -key addrC subrK.
  Qed.

  Lemma rec0 :
    A *m pcoef 0 G = - (chi`_0 *: 1%:M).
  Proof.
    have key : - (A *m pcoef 0 G) = chi`_0 *: 1%:M.
      by rewrite -sub0r -{1}(pcoef0_scaleX G) -pcoef_constmul -pcoefB -cpmGE adjE
                pcoef_scalar.
    by rewrite -key opprK.
  Qed.

End AdjRec.

Section DetSize.

  Variable R : comRingType.

  Lemma size_prod_le2 (I : eqType) (s : seq I) (p : I -> {poly R}) :
    (forall i, leq (size (p i)) 2) -> leq (size (\prod_(i <- s) p i)) (size s).+1.
  Proof.
    move=> Hp; elim: s => [|a s IH]; first by rewrite big_nil size_poly1.
    rewrite big_cons.
    apply: (leq_trans (size_mul_leq _ _)).
    rewrite -subn1 leq_subLR.
    by apply: (leq_trans (leq_add (Hp a) IH)).
  Qed.

  Lemma size_prod_ord (T : finType) (p : T -> {poly R}) :
    (forall i, leq (size (p i)) 2) -> leq (size (\prod_i p i)) #|T|.+1.
  Proof.
    move=> Hp.
    have hs : size (index_enum T) = #|T| by rewrite [index_enum T]unlock -enumT -cardT.
    by rewrite -hs; exact: size_prod_le2.
  Qed.

  Lemma det_size (m : nat) (M : 'M[{poly R}]_m) :
    (forall i j, leq (size (M i j)) 2) -> leq (size (\det M)) m.+1.
  Proof.
    move=> Hsz; rewrite /determinant.
    apply: (leq_trans (size_sum _ _ _)).
    apply/bigmax_leqP => s _; rewrite size_Msign.
    rewrite -[X in leq _ X.+1](card_ord m).
    by apply: size_prod_ord => i; exact: (Hsz i (s i)).
  Qed.

End DetSize.

Section FLdeg.

  Variable R : comRingType.

  Variable n' : nat.
  Local Notation n := n'.+1.
  Variable A : 'M[R]_n.
  Local Notation G := (\adj (char_poly_mx A)).

  Lemma size_cpm_entry (a b : 'I_n) :
    leq (size (char_poly_mx A a b)) 2.
  Proof.
    rewrite /char_poly_mx !mxE.
    case: (a == b); rewrite ?mulr1n ?mulr0n.
      apply: (leq_trans (size_polyD _ _)); rewrite geq_max size_polyX /=.
      by rewrite size_opp (leq_trans (size_polyC_leq1 _)).
    by rewrite sub0r size_opp (leq_trans (size_polyC_leq1 _)).
  Qed.

  Lemma Bn0 :
    pcoef n G = 0.
  Proof.
    apply/matrixP => i j; rewrite !mxE.
    have hsz : leq (size (cofactor (char_poly_mx A) j i)) n.
      rewrite /cofactor size_Msign.
      by apply: det_size => a b; rewrite 2!mxE; exact: size_cpm_entry.
    by move: hsz => /leq_sizeP/(_ n (leqnn n)) ->.
  Qed.

  Lemma Bnm1 :
    pcoef n' G = 1%:M.
  Proof.
    have hlead : (char_poly A)`_n = 1.
      by rewrite -(monicP (char_poly_monic A)) lead_coefE size_char_poly.
    by rewrite (recS A n') Bn0 mulmx0 add0r hlead scale1r.
  Qed.

End FLdeg.

Section TraceB.

  Variable R : comRingType.

  Variable n' : nat.
  Local Notation n := n'.+1.
  Variable A : 'M[R]_n.
  Local Notation G := (\adj (char_poly_mx A)).

  Lemma traceB k :
    \tr (pcoef k G) = (char_poly A)`_(k.+1) *+ k.+1.
  Proof.
    have htr : \tr (pcoef k G) = ((\tr G)`_k).
      rewrite /mxtrace coef_sum.
      by apply: eq_bigr => i _; rewrite mxE.
    by rewrite htr -char_poly_deriv coef_deriv.
  Qed.

End TraceB.

Section FL.

  Variable F : numFieldType.

  Variable n' : nat.
  Local Notation n := n'.+1.
  Variable A : 'M[F]_n.
  Local Notation G := (\adj (char_poly_mx A)).

  (*
    Рекуррента Фаддеева-Леверье.

    Последовательность матриц $M_0 = E$, $M_(j+1) = A M_j + c_j E$ со скалярами
    $c_j = - "tr"(A M_j) \/ (j + 1)$. Лемма `flMB` отождествляет $M_j$ с
    матричными коэффициентами присоединённой матрицы $"adj"(x E - A)$, а скаляры
    $c_j$ с коэффициентами характеристического многочлена.
  *)
  Fixpoint flM (j : nat) : 'M[F]_n :=
    if j is j'.+1 then
      A *m flM j' + (- (\tr (A *m flM j')) / (j'.+1)%:R) *: 1%:M
    else 1%:M.

  Definition flc (j : nat) : F :=
    - (\tr (A *m flM j)) / (j.+1)%:R.

  (*
    Обратная матрица методом Фаддеева-Леверье.

    $A^(-1) = - c_(n-1)^(-1) M_(n-1)$: последний член рекуррентности с точностью
    до скалярного множителя совпадает с присоединённой матрицей $"adj"(A)$, а
    нормирующий скаляр с точностью до знака равен определителю $A$.
  *)
  Definition fl_inv : 'M[F]_n :=
    - (flc n')^-1 *: flM n'.

  Lemma flMB j : (j <= n')%N -> flM j = pcoef (n' - j) G.
  Proof.
    elim: j => [_|j IH hj]; first by rewrite subn0 Bnm1.
    have hj' : (j <= n')%N by apply: ltnW.
    have IHj := IH hj'.
    have hm : (0 < n' - j)%N by rewrite subn_gt0.
    have hsum : (n = (n' - j) + j.+1)%N by rewrite addnS (subnK hj').
    have hflc : flc j = (char_poly A)`_(n' - j).
      rewrite /flc IHj.
      have hr := recS A (n' - j).-1; rewrite (prednK hm) in hr.
      have hAB : A *m pcoef (n' - j) G
              = pcoef (n' - j).-1 G - (char_poly A)`_(n' - j) *: 1%:M.
        by rewrite hr addrK.
      have key2 : (char_poly A)`_(n' - j) *+ (n' - j)
                - (char_poly A)`_(n' - j) *+ n
                = - ((char_poly A)`_(n' - j) *+ j.+1).
        set c := (char_poly A)`_(n' - j).
        by rewrite hsum mulrnDr opprD addrA addrN add0r.
      rewrite hAB raddfB /= (traceB A (n' - j).-1) (prednK hm) mxtraceZ mxtrace1.
      have hj1 : (j.+1)%:R != 0 :> F by rewrite pnatr_eq0.
      rewrite mulr_natr key2 opprK.
      have -> : (char_poly A)`_(n' - j) *+ j.+1
              = (char_poly A)`_(n' - j) * (j.+1)%:R by rewrite mulr_natr.
      by rewrite (mulfK hj1).
    rewrite /= -/(flc j) IHj hflc.
    have e : (n' - j.+1)%N = (n' - j).-1 by rewrite subnS.
    by rewrite e (recS A (n' - j).-1) (prednK hm).
  Qed.

  (*
    Корректность обращения методом Фаддеева-Леверье.

    На обратимой матрице $A$ результат `fl_inv` совпадает с `invmx`. Свободный
    коэффициент характеристического многочлена отличен от нуля в точности при
    обратимости $A$, что позволяет нормировать последний член рекуррентности.
  *)
  Lemma fl_inv_correct :
    A \in unitmx -> fl_inv = invmx A.
  Proof.
    move=> Aunit.
    have hSn : (n'.+1)%:R != 0 :> F by rewrite pnatr_eq0.
    have flcn' : flc n' = (char_poly A)`_0.
      rewrite /flc (flMB (leqnn n')) subnn rec0 raddfN /= mxtraceZ mxtrace1 opprK.
      by rewrite (mulfK hSn).
    have hc0 : (char_poly A)`_0 != 0.
      rewrite char_poly_det; apply: mulf_neq0; last by move: Aunit; rewrite unitmxE unitfE.
      by rewrite expf_eq0 oppr_eq0 oner_eq0 andbF.
    have key : A *m fl_inv = 1%:M.
      rewrite /fl_inv -scalemxAr (flMB (leqnn n')) subnn rec0.
      by rewrite scalerN scalerA flcn' mulNr (mulVf hc0) scaleN1r opprK.
    by rewrite -[fl_inv]mul1mx -(mulVmx Aunit) -mulmxA key mulmx1.
  Qed.

End FL.

(*
  Безусловное совпадение с `invmx` при $p = 1$.

  В поле $0^(-1) = 0$, поэтому при $p = 1$ обращение методом Фаддеева-Леверье
  совпадает с `invmx` без предположения обратимости; это снимает обязательство
  `cinv` при одном канале наблюдения.
*)
Lemma fl_inv1 (F : numFieldType) (S : 'M[F]_1) :
  fl_inv S = invmx S.
Proof.
  have e1 : ((0%N.+1)%:R : F) = 1 by rewrite mulrSr mulr0n add0r.
  have flM0 : flM S 0 = 1%:M by [].
  have flc0 : flc S 0 = - (S ord0 ord0).
    rewrite /flc flM0 mulmx1 {1}[S]mx11_scalar mxtrace_scalar mulr1n.
    by rewrite e1 divr1.
  rewrite /fl_inv flM0 flc0 invrN opprK.
  rewrite {2}[S]mx11_scalar invmx_scalar.
  by rewrite scale_scalar_mx mulr1.
Qed.
