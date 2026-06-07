(*
  Спектральная теорема для эрмитовых матриц над numClosedFieldType.

  Используется напрямую mathcomp.algebra.spectral.orthomx_spectralP: всякая
  эрмитова матрица унитарно диагонализируема с вещественным спектром
  (hermitian_spectral_diag_real).
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra mxpoly.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite mxloewner.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section Spectral.

  Variable (ℂ : numClosedFieldType).

  (* Производные факты об эрмитовых и унитарных матрицах. *)

  Lemma psd_hermsym n (M : 'M[ℂ]_n) :
    psd M -> M \is hermsymmx.
  Proof.
    case=> Msym _; apply/is_hermitianmxP.
    by rewrite expr0 scale1r -Msym.
  Qed.

  Lemma pd_hermsym n (M : 'M[ℂ]_n) :
    pd M -> M \is hermsymmx.
  Proof.
    by move/pd_psd/psd_hermsym.
  Qed.

  Lemma hermsym_eq n (M : 'M[ℂ]_n) :
    M \is hermsymmx -> M = M^t*.
  Proof.
    move/is_hermitianmxP; rewrite expr0 scale1r => <-.
    by [].
  Qed.

  Lemma unitary_mulV n (U : 'M[ℂ]_n) :
    U \is unitarymx -> U^t* *m U = 1%:M.
  Proof.
    move=> hU.
    have hUu : U \in unitmx := unitarymx_unit hU.
    have := invmx_unitary hU; move=> <-.
    by rewrite mulVmx.
  Qed.

  Lemma hermsym_congr n (U M : 'M[ℂ]_n) :
    M \is hermsymmx -> (U^t* *m M *m U) \is hermsymmx.
  Proof.
    move=> hM.
    apply/is_hermitianmxP; rewrite expr0 scale1r.
    rewrite [in RHS]trmxC_mul trmxC_mul trmxCK mulmxA.
    by rewrite -[in RHS](hermsym_eq hM).
  Qed.

  (* diag_of и базовая алгебра диагональных матриц. *)

  Definition diag_of n (l : 'I_n -> ℂ) : 'M[ℂ]_n :=
    \matrix_(i, j) (if i == j then l i else 0).

  Lemma diag_of_hermsym n (l : 'I_n -> ℂ) :
    (forall i, l i \is Num.real) -> diag_of l \is hermsymmx.
  Proof.
    move=> hreal; apply/is_hermitianmxP; rewrite expr0 scale1r.
    apply/matrixP=> i j; rewrite !mxE.
    have [<-|_] := eqVneq i j.
      by apply/esym/CrealP; exact: hreal.
    by rewrite rmorph0.
  Qed.

  Lemma diag_of_eq n (f g : 'I_n -> ℂ) :
    f =1 g -> diag_of f = diag_of g.
  Proof.
    move=> hfg; apply/matrixP=> i j; rewrite !mxE.
    by case: eqP=> // ->; rewrite hfg.
  Qed.

  Lemma diag_of_const1 n :
    diag_of (fun _ : 'I_n => (1 : ℂ)) = 1%:M.
  Proof.
    apply/matrixP=> i j; rewrite !mxE.
    by case: (i == j); rewrite ?mulr1n ?mulr0n.
  Qed.

  Lemma diag_of_mul n (f g : 'I_n -> ℂ) :
    diag_of f *m diag_of g = diag_of (fun i => f i * g i).
  Proof.
    apply/matrixP=> i j; rewrite !mxE.
    rewrite (bigD1 i) //= big1 ?addr0; last first.
      by move=> k /negbTE neki; rewrite !mxE eq_sym neki mul0r.
    rewrite !mxE eqxx.
    by case: eqP=> [->|_]; rewrite ?mulr0.
  Qed.

  Lemma diag_of_sub n (f g : 'I_n -> ℂ) :
    diag_of f - diag_of g = diag_of (fun i => f i - g i).
  Proof.
    apply/matrixP=> i j; rewrite !mxE.
    by case: eqP=> [_|_]; rewrite ?subr0.
  Qed.

  (*
    Спектральное разложение эрмитовой матрицы.

    Всякая эрмитова матрица унитарно диагонализируема с вещественным спектром:
    существуют унитарная $U$ и вещественная диагональная $D$, для которых
    $M = U D U†$. Доказательство переиспользует результат $"orthomx_spectralP"$
    из библиотеки $"mathcomp.algebra.spectral"$.

    - @kailath2000[App. A, § A.1 "Some Matrix Identities"].
  *)

  Lemma spectral_decomp n (M : 'M[ℂ]_n) :
    M \is hermsymmx ->
    exists (U : 'M[ℂ]_n) (l : 'I_n -> ℂ),
      U \is unitarymx /\ (forall i, l i \is Num.real) /\
      M = U *m diag_of l *m U^t*.
  Proof.
    move=> Mherm.
    have Mnorm := hermitian_normalmx Mherm.
    have Mdec : M = (spectralmx M)^t* *m diag_mx (spectral_diag M) *m spectralmx M.
      have h := orthomx_spectralP Mnorm.
      rewrite -invmx_unitary //; exact: spectral_unitarymx.
    have Mreal := hermitian_spectral_diag_real Mherm.
    pose U := (spectralmx M)^t*.
    pose l : 'I_n -> ℂ := fun i => spectral_diag M ord0 i.
    have Punit : spectralmx M \is unitarymx := spectral_unitarymx M.
    have Uunit : U \is unitarymx by rewrite /U trmxC_unitary.
    have UtCK : U^t* = spectralmx M by rewrite /U trmxCK.
    exists U, l; split; first by [].
    split.
      by move=> i; have /mxOverP -> := Mreal.
    rewrite Mdec -/U.
    rewrite UtCK.
    congr (_ *m _ *m _).
    apply/matrixP=> i j; rewrite !mxE.
    by case: eqP=> [->|_]; rewrite ?(mulr1n, mulr0n).
  Qed.

  (*
    Эрмитовы формы; характеризация неотрицательной определённости через спектр.
  *)

  Lemma diag_of_qform n (l : 'I_n -> ℂ) (v : 'cV[ℂ]_n) :
    \tr (v^t* *m diag_of l *m v) =
    \sum_i (l i) * ((v i ord0)^* * (v i ord0)).
  Proof.
    rewrite trace_mx11 mxE.
    apply: eq_bigr => i _.
    rewrite !mxE.
    rewrite (bigD1 i) //= !mxE eqxx big1 ?addr0; last first.
      move=> k neki.
      by rewrite !mxE (negbTE neki) mulr0.
    by rewrite mulrA [_ * l i]mulrC -!mulrA.
  Qed.

  Lemma psd_diag_iff_real n (l : 'I_n -> ℂ) :
    (forall i, l i \is Num.real) ->
    psd (diag_of l) <-> (forall i, 0 <= l i).
  Proof.
    move=> hreal; split.
    - case=> _ hQ i.
      have hi := hQ (delta_mx i ord0).
      rewrite diag_of_qform (bigD1 i) //= big1 ?addr0 in hi; last first.
        move=> j /negbTE neji.
        by rewrite !mxE neji /= conjC0 mul0r mulr0.
      have del1 : (delta_mx i ord0 : 'cV[ℂ]_n) i ord0 = 1
        by rewrite mxE !eqxx /=.
      rewrite del1 conjC1 mul1r mulr1 in hi.
      exact: hi.
    - move=> hl; split; first by apply: hermsym_eq; exact: diag_of_hermsym.
      move=> v; rewrite diag_of_qform.
      apply: sumr_ge0=> i _.
      apply: mulr_ge0 (hl i) _.
      by rewrite -normCKC exprn_ge0.
  Qed.

  Lemma psd_iff_eigvals_nn n (M : 'M[ℂ]_n) :
    M \is hermsymmx ->
    (psd M <->
    exists (U : 'M[ℂ]_n) (l : 'I_n -> ℂ),
      U \is unitarymx /\ (forall i, l i \is Num.real) /\
      M = U *m diag_of l *m U^t* /\ (forall i, 0 <= l i)).
  Proof.
    move=> hSym.
    have [U [l [hU [hreal hEq]]]] := spectral_decomp hSym.
    split.
    - move=> hPsd.
      have hPsdD : psd (diag_of l).
        have hEqRev : U^t* *m M *m U = diag_of l.
          rewrite hEq.
          have e1 : U^t* *m (U *m diag_of l *m U^t*) =
                    (U^t* *m U) *m diag_of l *m U^t*
            by rewrite !mulmxA.
          rewrite e1.
          have h := unitary_mulV hU.
          by rewrite !h !mul1mx -mulmxA h mulmx1.
        have -> : diag_of l = U^t* *m M *m U by rewrite hEqRev.
        exact: psd_congr hPsd.
      exists U, l; do !split=> //.
      by apply/(psd_diag_iff_real hreal).
    - case=> U' [l' [hU' [hreal' [hEq' hl']]]].
      rewrite hEq'.
      apply: psd_lcongr.
      by apply/(psd_diag_iff_real hreal').
  Qed.

  (*
    Зануление квадратичной формы неотрицательно определённой матрицы влечёт
    зануление столбца: $"psd" M -> v† M v = 0 ==> M v = 0$. Через спектральную
    теорему $M = U "diag"(l) U†, l_i >= 0 : v† M v = Σ_i l_i |(U† v)_i|²$;
    зануление суммы неотрицательных слагаемых даёт $forall i: l_i (U† v)_i = 0$,
    откуда $"diag"(l) (U† v) = 0$ и $M v = U ("diag"(l) (U† v)) = 0$. Это факт о
    том, что для неотрицательно определённой матрицы зануление формы ⟺ зануление
    столбца, нужный для перехода от энергетического баланса Ляпунова к
    PBH-условию.
  *)
  Lemma psd_qf0_mul0 n (M : 'M[ℂ]_n) (v : 'cV[ℂ]_n) :
    psd M -> \tr (v^t* *m M *m v) = 0 -> M *m v = 0.
  Proof.
    move=> Mpsd qf0.
    have Mherm : M \is hermsymmx := psd_hermsym Mpsd.
    have [U [l [Uunit [lreal Meq]]]] := spectral_decomp Mherm.
    have hUV : U^t* *m U = 1%:M := unitary_mulV Uunit.
    have lnn : forall i, 0 <= l i.
      apply/(psd_diag_iff_real lreal).
      have e : diag_of l = U^t* *m M *m U.
        rewrite Meq.
        have e1 : U^t* *m (U *m diag_of l *m U^t*) *m U
                = (U^t* *m U) *m diag_of l *m (U^t* *m U) by rewrite !mulmxA.
        by rewrite e1 hUV !mul1mx mulmx1.
      rewrite e; exact: psd_congr Mpsd.
    set u := U^t* *m v.
    have qf_eq : \tr (v^t* *m M *m v) = \tr (u^t* *m diag_of l *m u).
      by rewrite Meq /u trmxC_mul trmxCK !mulmxA.
    rewrite qf_eq diag_of_qform in qf0.
    have nn : forall i : 'I_n, true ->
        0 <= l i * ((u i ord0)^* * (u i ord0)).
      move=> i _; apply: mulr_ge0; first exact: lnn.
      by rewrite -normCKC exprn_ge0.
    have allz := psumr_eq0P nn qf0.
    have key : forall i, l i * (u i ord0) = 0.
      move=> i; move/eqP: (allz i isT); rewrite mulf_eq0 => /orP[/eqP->|huu].
        by rewrite mul0r.
      move: huu; rewrite mulf_eq0 conjC_eq0 orbb => /eqP->.
      by rewrite mulr0.
    have dl0 : diag_of l *m u = 0.
      apply/matrixP=> i j; rewrite mxE [RHS]mxE.
      rewrite (bigD1 i) //= mxE eqxx big1 ?addr0; last first.
        by move=> k /negbTE neki; rewrite mxE eq_sym neki mul0r.
      by rewrite [j]ord1; exact: key i.
    by rewrite Meq -!mulmxA -/u dl0 mulmx0.
  Qed.

  (* Сопряжение $A |-> U A U†$. *)

  Lemma spec_conj_mul n (U D1 D2 : 'M[ℂ]_n) :
    U \is unitarymx ->
    (U *m D1 *m U^t*) *m (U *m D2 *m U^t*) = U *m (D1 *m D2) *m U^t*.
  Proof.
    move=> hU.
    have eq1 : (U *m D1 *m U^t*) *m (U *m D2 *m U^t*) =
              U *m D1 *m (U^t* *m U) *m D2 *m U^t*
      by rewrite !mulmxA.
    by rewrite eq1 (unitary_mulV hU) mulmx1 !mulmxA.
  Qed.

  Lemma spec_conj_one n (U : 'M[ℂ]_n) :
    U \is unitarymx -> U *m 1%:M *m U^t* = 1%:M.
  Proof.
    by move=> hU; rewrite mulmx1; have /unitarymxP -> := hU.
  Qed.

  Lemma invmx_spec_conj n (U : 'M[ℂ]_n) (l : 'I_n -> ℂ) :
    U \is unitarymx -> (forall i, l i != 0) ->
    invmx (U *m diag_of l *m U^t*) =
      U *m diag_of (fun i => (l i)^-1) *m U^t*.
  Proof.
    move=> hU hl.
    pose L := U *m diag_of l *m U^t*.
    pose M := U *m diag_of (fun i => (l i)^-1) *m U^t*.
    have prod_id : L *m M = 1%:M.
      rewrite /L /M spec_conj_mul // diag_of_mul.
      suff -> : diag_of (fun i : 'I_n => l i * (l i)^-1) =
                (1%:M : 'M[ℂ]_n).
        by rewrite spec_conj_one.
      rewrite -[RHS]diag_of_const1.
      apply: diag_of_eq=> i /=.
      by rewrite mulfV //; exact: hl.
    have unitL : L \in unitmx := proj1 (mulmx1_unit prod_id).
    rewrite -/L -/M.
    by rewrite -[LHS]mulmx1 -prod_id mulmxA mulVmx ?mul1mx.
  Qed.

  Lemma UAU_decomp n (A U : 'M[ℂ]_n) (l : 'I_n -> ℂ) :
    U \is unitarymx -> A = U *m diag_of l *m U^t* ->
    U^t* *m A *m U = diag_of l.
  Proof.
    move=> hU hAdec.
    rewrite hAdec.
    have e2 : U^t* *m (U *m diag_of l *m U^t*) *m U =
              U^t* *m U *m diag_of l *m U^t* *m U
      by rewrite !mulmxA.
    have h := unitary_mulV hU.
    by rewrite e2 !h !mul1mx -mulmxA h mulmx1.
  Qed.

  Lemma pd_eigvals_pos n (A U : 'M[ℂ]_n) (l : 'I_n -> ℂ) :
    pd A -> U \is unitarymx -> (forall i, l i \is Num.real) ->
    A = U *m diag_of l *m U^t* ->
    forall i, 0 < l i.
  Proof.
    move=> pdA hU hreal hAdec i.
    case: pdA => _ pdAq.
    pose ei : 'cV[ℂ]_n := delta_mx i (ord0 : 'I_1).
    pose v : 'cV[ℂ]_n := U *m ei.
    have eiNZ : ei != 0.
      apply/cV0Pn; exists i; rewrite /ei !mxE !eqxx /=.
      by rewrite oner_neq0.
    have Uunit : U \in unitmx := unitarymx_unit hU.
    have vNZ : v != 0.
      apply: contraNneq eiNZ => v0.
      by rewrite -[ei]mul1mx -(mulVmx Uunit) -mulmxA -/v v0 mulmx0.
    have UAU : U^t* *m A *m U = diag_of l := UAU_decomp hU hAdec.
    have hVAV : v^t* *m A *m v = ei^t* *m diag_of l *m ei.
      by rewrite /v -UAU trmxC_mul -!mulmxA.
    have lqf : \tr (ei^t* *m diag_of l *m ei) = l i.
      rewrite diag_of_qform (bigD1 i) //= big1 ?addr0; last first.
        move=> j /negbTE neji.
        by rewrite !mxE neji /= conjC0 mul0r mulr0.
      have del1 : (ei : 'cV[ℂ]_n) i ord0 = 1 by rewrite mxE !eqxx /=.
      by rewrite del1 conjC1 mul1r mulr1.
    suff: 0 < \tr (v^t* *m A *m v) by rewrite hVAV lqf.
    exact: pdAq.
  Qed.

  Lemma psd_spec_conj_inj n (V X : 'M[ℂ]_n) :
    V \is unitarymx -> psd (V *m X *m V^t*) -> psd X.
  Proof.
    move=> hV hPsd.
    have he : V^t* *m (V *m X *m V^t*) *m V = X.
      have e1 : V^t* *m (V *m X *m V^t*) = V^t* *m V *m X *m V^t*
        by rewrite !mulmxA.
      have e2 : V^t* *m (V *m X *m V^t*) *m V = V^t* *m V *m X *m V^t* *m V
        by rewrite e1.
      have h := unitary_mulV hV.
      by rewrite e2 !h !mul1mx -mulmxA h mulmx1.
    by rewrite -he; apply: psd_congr.
  Qed.

  (*
    Антимонотонность обращения на конусе положительно определённых матриц.

    Если $A prec.eq B$ и обе матрицы положительно определены, то
    $B^(-1) prec.eq A^(-1)$.
  *)
  Theorem pd_inv_antimono n (A B : 'M[ℂ]_n) :
    pd A -> pd B -> psd_le A B -> psd_le (invmx B) (invmx A).
  (*
    Если $A prec.eq B$ и обе матрицы положительно определены, выберем
    спектральное разложение $A = U D U†$, рассмотрим эрмитов квадратный корень
    $S := U D^(-1/2) U†$ и заметим, что $S A S = E$, откуда
    $E prec.eq S B S =: B'$. Из $B' succ.eq E$ следует, что все собственные
    числа $B' >= 1$, а значит собственные числа $(B')^(-1) <= 1$, т. е.
    $(B')^(-1) prec.eq E$. Применяя к обеим частям неравенства эрмитову
    конгруэнцию с матрицей $S$ и подставляя обратно $S^2 = A^(-1)$, получаем
    $B^(-1) prec.eq A^(-1)$.
  *)
  Proof.
    move=> pdA pdB hAB.
    have Aherm := pd_hermsym pdA.
    have Bherm := pd_hermsym pdB.
    have [U [l [hU [hreal hAdec]]]] := spectral_decomp Aherm.
    have lpos : forall i, 0 < l i := pd_eigvals_pos pdA hU hreal hAdec.
    have lnz : forall i, l i != 0 by move=> i; rewrite gt_eqF // lpos.
    have l_real_nneg : forall i, l i \is Num.nneg
      by move=> i; rewrite qualifE /=; exact: ltW.
    have sl_gt0 : forall i, 0 < sqrtC (l i)
      by move=> i; rewrite sqrtC_gt0 lpos.
    have sl_real : forall i, sqrtC (l i) \is Num.real
      by move=> i; rewrite ger0_real // ltW // sl_gt0.
    have isl_nz : forall i, (sqrtC (l i))^-1 != 0
      by move=> i; rewrite invr_eq0 gt_eqF // sl_gt0.
    pose isl : 'I_n -> ℂ := fun i => (sqrtC (l i))^-1.
    pose S : 'M[ℂ]_n := U *m diag_of isl *m U^t*.
    have isl_real : forall i, isl i \is Num.real
      by move=> i; rewrite /isl realV.
    have Sherm : S \is hermsymmx.
      rewrite /S.
      have hD : diag_of isl \is hermsymmx := diag_of_hermsym isl_real.
      have hH : (U *m diag_of isl *m U^t*) \is hermsymmx.
        have := @hermsym_congr n (U^t*) (diag_of isl) hD.
        by rewrite trmxCK.
      exact: hH.
    have Ssym : S = S^t* by exact: hermsym_eq.
    have isl_l_isl : forall i : 'I_n, isl i * l i * isl i = 1.
      move=> i; rewrite /isl mulrAC -invfM.
      have -> : sqrtC (l i) * sqrtC (l i) = l i by rewrite -expr2 sqrtCK.
      by rewrite mulVf // lnz.
    have SAS_eq : S *m A *m S = 1%:M.
      rewrite /S hAdec.
      have step1 : (U *m diag_of isl *m U^t*) *m (U *m diag_of l *m U^t*) =
                  U *m (diag_of isl *m diag_of l) *m U^t*
        := spec_conj_mul _ _ hU.
      rewrite step1.
      have step2 : (U *m (diag_of isl *m diag_of l) *m U^t*) *m
                  (U *m diag_of isl *m U^t*) =
                  U *m ((diag_of isl *m diag_of l) *m diag_of isl) *m U^t*
        := spec_conj_mul _ _ hU.
      rewrite step2 !diag_of_mul.
      suff -> : diag_of (fun i : 'I_n => isl i * l i * isl i) =
                (1%:M : 'M[ℂ]_n).
        exact: spec_conj_one.
      by rewrite -[RHS]diag_of_const1; apply: diag_of_eq.
    have S_unit : S \in unitmx by have [_ h] := mulmx1_unit SAS_eq.
    have invA_eq : invmx A = S *m S.
      rewrite hAdec invmx_spec_conj //.
      rewrite /S spec_conj_mul // diag_of_mul.
      congr (U *m _ *m U^t*).
      apply: diag_of_eq=> i /=.
      rewrite /isl -invfM.
      have -> : sqrtC (l i) * sqrtC (l i) = l i by rewrite -expr2 sqrtCK.
      by [].
    pose B' : 'M[ℂ]_n := S *m B *m S.
    have B'herm : B' \is hermsymmx.
      rewrite /B'.
      have -> : S *m B *m S = S^t* *m B *m S by rewrite -Ssym.
      exact: hermsym_congr (pd_hermsym pdB).
    have hIB' : psd_le 1%:M B'.
      rewrite -SAS_eq /psd_le /B'.
      have -> : S *m B *m S - S *m A *m S = S *m (B - A) *m S
        by rewrite mulmxBr mulmxBl.
      rewrite {1}Ssym; exact: psd_congr.
    have [V [lam [hV [lamreal B'dec]]]] := spectral_decomp B'herm.
    have lam_ge1 : forall i, 1 <= lam i.
      have hpsd0 : psd (B' - 1%:M) := hIB'.
      have key : B' - 1%:M = V *m diag_of (fun j : 'I_n => lam j - 1) *m V^t*.
        rewrite B'dec.
        rewrite -[X in _ - X](spec_conj_one hV).
        rewrite -mulmxBl -mulmxBr.
        suff -> : (diag_of lam : 'M[ℂ]_n) - 1%:M =
                  diag_of (fun j : 'I_n => lam j - 1) by [].
        by rewrite -diag_of_const1 diag_of_sub.
      rewrite key in hpsd0.
      have psdD : psd (diag_of (fun j : 'I_n => lam j - 1)).
        have := psd_spec_conj_inj hV hpsd0; by [].
      have lamreal_sub : forall i, lam i - 1 \is Num.real
        by move=> i; rewrite rpredB // realE; apply/orP; left; exact: ler01.
      by move=> i; rewrite -subr_ge0;
        exact: (proj1 (psd_diag_iff_real lamreal_sub) psdD i).
    have lam_gt0 : forall i, 0 < lam i
      by move=> i; apply: lt_le_trans ltr01 _; exact: lam_ge1.
    have lam_nz : forall i, lam i != 0
      by move=> i; rewrite gt_eqF // lam_gt0.
    have ilamreal : forall i, (lam i)^-1 \is Num.real
      by move=> i; rewrite realV.
    pose X : 'M[ℂ]_n := (S *m V) *m
                        diag_of (fun i : 'I_n => (lam i)^-1) *m (S *m V)^t*.
    have X_alt : X = S *m V *m diag_of (fun i : 'I_n => (lam i)^-1) *m V^t* *m S^t*.
      by rewrite /X trmxC_mul !mulmxA.
    have hSBS_eq : S *m B *m S = V *m diag_of lam *m V^t* by rewrite -/B'.
    have SBX : S *m (B *m X) = S^t*.
      rewrite X_alt.
      have eq1 :
        S *m (B *m (S *m V *m diag_of (fun i : 'I_n => (lam i)^-1) *m V^t* *m S^t*)) =
        S *m B *m S *m V *m diag_of (fun i : 'I_n => (lam i)^-1) *m V^t* *m S^t*
        by rewrite !mulmxA.
      rewrite eq1 hSBS_eq.
      have eq2 :
        V *m diag_of lam *m V^t* *m V *m diag_of (fun i : 'I_n => (lam i)^-1)
          *m V^t* *m S^t* =
        V *m diag_of lam *m (V^t* *m V) *m diag_of (fun i : 'I_n => (lam i)^-1)
          *m V^t* *m S^t*
        by rewrite !mulmxA.
      rewrite eq2 (unitary_mulV hV) mulmx1.
      rewrite -[V *m diag_of lam *m diag_of _]mulmxA diag_of_mul.
      have -> : diag_of (fun i : 'I_n => lam i * (lam i)^-1) =
                (1%:M : 'M[ℂ]_n).
        rewrite -[RHS]diag_of_const1; apply: diag_of_eq=> i /=.
        by rewrite mulfV //; exact: lam_nz.
      rewrite mulmx1.
      have /unitarymxP -> := hV.
      exact: mul1mx.
    have SBX' : S *m (B *m X) = S by rewrite SBX -Ssym.
    have BX_eq : B *m X = 1%:M.
      by rewrite -[B *m X]mul1mx -(mulVmx S_unit) -mulmxA SBX' mulVmx.
    have X_eq_invB : X = invmx B.
      have B_unit : B \in unitmx := pd_invertible pdB.
      by rewrite -[X]mul1mx -(mulVmx B_unit) -mulmxA BX_eq mulmx1.
    have SVSV_eq : (S *m V) *m (S *m V)^t* = S *m S.
      rewrite trmxC_mul.
      have e1 : (S *m V) *m (V^t* *m S^t*) = S *m (V *m V^t*) *m S^t*
        by rewrite !mulmxA.
      rewrite e1.
      have /unitarymxP -> := hV.
      by rewrite mulmx1 -Ssym.
    have diff_eq : invmx A - X =
        (S *m V) *m diag_of (fun i : 'I_n => 1 - (lam i)^-1) *m (S *m V)^t*.
      rewrite invA_eq -SVSV_eq.
      have factor :
        (S *m V) *m ((1%:M : 'M[ℂ]_n) - diag_of (fun i : 'I_n => (lam i)^-1))
          *m (S *m V)^t* =
        (S *m V) *m (S *m V)^t* -
          (S *m V) *m diag_of (fun i : 'I_n => (lam i)^-1) *m (S *m V)^t*
        by rewrite mulmxBr mulmxBl mulmx1.
      rewrite /X -factor.
      suff -> : (1%:M : 'M[ℂ]_n) - diag_of (fun i : 'I_n => (lam i)^-1) =
                diag_of (fun i : 'I_n => 1 - (lam i)^-1) by [].
      by rewrite -diag_of_const1 diag_of_sub.
    rewrite /psd_le -X_eq_invB diff_eq.
    apply: psd_lcongr.
    have sub_real : forall i, 1 - (lam i)^-1 \is Num.real
      by move=> i; rewrite rpredB // realE; apply/orP; left; exact: ler01.
    apply/(psd_diag_iff_real sub_real)=> i.
    rewrite subr_ge0.
    have : (lam i)^-1 <= 1.
      by rewrite invf_le1 ?lam_gt0 //; exact: lam_ge1.
    by [].
  Qed.

  (*
    Антисимметрия порядка Лёвнера.

    Если $A prec.eq B$ и $B prec.eq A$, то $A = B$.
  *)
  Theorem psd_le_antisym n (A B : 'M[ℂ]_n) :
    psd_le A B -> psd_le B A -> A = B.
  (*
    Пусть $M := B - A$. По условию $M$ и $-M$ обе определены неотрицательно. По
    спектральной теореме (см. @sec:spectral) $M = U D U†$, где $U$ унитарна, а
    $D = "diag"(l_1, ..., l_n)$ вещественна. Эрмитова конгруэнция с матрицей
    $U†$ даёт $D = U† M U$ и $-D = U† (-M) U$, обе положительно полуопределены.
    Из характеризации положительно полуопределённых диагональных матриц
    ($"diag"(l_1, ..., l_n) succ.eq 0 <=> l_i >= 0$) получаем одновременно
    $l_i >= 0$ и $-l_i >= 0$, откуда $l_i = 0$ и $M = 0$.
  *)
  Proof.
    rewrite /psd_le => h1 h2.
    have Mherm : (B - A) \is hermsymmx := psd_hermsym h1.
    have [U [l [hU [lreal Mdec]]]] := spectral_decomp Mherm.
    have UMU : U^t* *m (B - A) *m U = diag_of l := UAU_decomp hU Mdec.
    have psd_diag_l : psd (diag_of l).
      rewrite -UMU.
      exact: psd_congr h1.
    have l_ge0 : forall i, 0 <= l i
      := proj1 (psd_diag_iff_real lreal) psd_diag_l.
    have UnMU : U^t* *m (A - B) *m U = - diag_of l.
      have ABe : A - B = - (B - A) by rewrite opprB.
      by rewrite ABe mulmxN mulNmx UMU.
    have negl_real : forall i, - l i \is Num.real
      by move=> i; rewrite rpredN.
    have negl_eq : - diag_of l = diag_of (fun i => - l i).
      apply/matrixP=> i j; rewrite !mxE.
      by case: ifP=> _; rewrite ?oppr0.
    have psd_diag_negl : psd (diag_of (fun i => - l i)).
      rewrite -negl_eq -UnMU.
      exact: psd_congr h2.
    have negl_ge0 : forall i, 0 <= - l i
      := proj1 (psd_diag_iff_real negl_real) psd_diag_negl.
    have l_eq0 : forall i, l i = 0.
      move=> i; apply: le_anti.
      apply/andP; split; last exact: l_ge0.
      by rewrite -oppr_ge0; exact: negl_ge0.
    have diag_l0 : diag_of l = (0 : 'M[ℂ]_n).
      apply/matrixP=> i j; rewrite !mxE.
      by case: ifP=> _; rewrite ?l_eq0.
    have BA0 : B - A = 0 by rewrite Mdec diag_l0 mulmx0 mul0mx.
    by apply/eqP; rewrite eq_sym -subr_eq0; apply/eqP; exact: BA0.
  Qed.

  (*
    Для любой неотрицательно определённой матрицы $A$ выполнено $A prec.eq ("tr" A) E$
    в порядке Лёвнера.
  *)
  Lemma psd_le_trace_id n (A : 'M[ℂ]_n) :
    psd A -> psd_le A (\tr A *: 1%:M).
  (*
    Пусть A = U diag(λ_1,...,λ_n) U†, где U унитарна, λ_i >= 0. Тогда (tr A) E −
    A = U ((tr A) E − diag(λ_i)) U† = U diag(tr A − λ_i) U†, причём tr A − λ_i =
    Σ_(j!=i) λ_j >= 0, поэтому разность неотрицательно определена, откуда и
    следует неравенство.
  *)
  Proof.
    move=> psdA.
    have herm := psd_hermsym psdA.
    have [U [l [hU [lreal Adec]]]] := spectral_decomp herm.
    have psdD : psd (diag_of l).
      apply: (psd_spec_conj_inj hU); by rewrite -Adec.
    have lnn := proj1 (psd_diag_iff_real lreal) psdD.
    have diag_const : forall a : ℂ, diag_of (fun _ : 'I_n => a) = a *: 1%:M.
      move=> a; apply/matrixP=> i j; rewrite !mxE.
      by case: eqP=> [_|_]; rewrite ?mulr1n ?mulr0n ?mulr1 ?mulr0.
    have trA_eq : \tr A = \sum_(i < n) l i.
      rewrite Adec mxtrace_mulC mulmxA (unitary_mulV hU) mul1mx.
      by rewrite /mxtrace; apply: eq_bigr=> i _; rewrite !mxE eqxx.
    have creal : \tr A \is Num.real.
      by rewrite trA_eq; apply: rpred_sum=> i _; exact: lreal i.
    have idU : (\tr A *: 1%:M : 'M[ℂ]_n)
            = U *m diag_of (fun _ => \tr A) *m U^t*.
      by rewrite diag_const -scalemxAr -scalemxAl (spec_conj_one hU).
    have decomp : \tr A *: 1%:M - A
                = U *m diag_of (fun i => \tr A - l i) *m U^t*.
      rewrite (_ : \tr A *: 1%:M - A
                = U *m diag_of (fun _ => \tr A) *m U^t*
                  - U *m diag_of l *m U^t*); last first.
        by congr (_ - _); [exact: idU | exact: Adec].
      by rewrite -mulmxBl -mulmxBr diag_of_sub.
    rewrite /psd_le decomp.
    apply: psd_lcongr.
    have sub_real : forall i, (\tr A - l i) \is Num.real.
      by move=> i; apply: rpredB; [exact: creal | exact: lreal i].
    apply/(psd_diag_iff_real sub_real)=> i.
    rewrite subr_ge0 trA_eq (bigD1 i) //= lerDl.
    by apply: sumr_ge0=> j _; exact: lnn j.
  Qed.

End Spectral.
