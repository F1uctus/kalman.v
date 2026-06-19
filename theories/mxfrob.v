(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Норма Фробениуса для матриц над алгебраически замкнутым полем.
  $norm(M)_F^2 = "tr" (M† M) = sum_(i,j) (M_(i j))† M_(i j) = sum_(i,j) |M_(i j)|^2$
  Нужна для:
  - Метрики на матрицах (через $norm(A - B)_F^2$);
  - Монотонной сходимости неотрицательно определённых последовательностей;
  - Утверждений о сходимости коэффициента усиления Калмана.
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite mxloewner spectral.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section Frob.

  Variable (ℂ : numClosedFieldType).

  Definition frob_sq r c (M : 'M[ℂ]_(r, c)) : ℂ := \tr (M^t* *m M).

  (* Раскрытие определения: $norm(M)_F^2 = sum_(i,j) (M_(i j))† dot M_(i j)$. *)
  Lemma frob_sqE r c (M : 'M[ℂ]_(r, c)) :
    frob_sq M = \sum_j \sum_i (M i j)^* * M i j.
  Proof.
    rewrite /frob_sq /mxtrace.
    apply: eq_bigr=> j _; rewrite mxE.
    by apply: eq_bigr=> i _; rewrite !mxE.
  Qed.

  (* Неотрицательность. *)
  Lemma frob_sq_ge0 r c (M : 'M[ℂ]_(r, c)) :
    0 <= frob_sq M.
  Proof.
    rewrite frob_sqE; apply: sumr_ge0=> j _; apply: sumr_ge0=> i _.
    by rewrite mulrC; exact: mul_conjC_ge0.
  Qed.

  (* Норма равна нулю только для нулевой матрицы. *)
  Lemma frob_sq_eq0 r c (M : 'M[ℂ]_(r, c)) :
    frob_sq M = 0 -> M = 0.
  Proof.
    rewrite frob_sqE => sum0.
    have step1 : forall j : 'I_c, \sum_i (M i j)^* * M i j = 0.
      move=> j; move/eqP: sum0; rewrite psumr_eq0; last first.
        move=> j' _; apply: sumr_ge0=> i _.
        by rewrite mulrC; exact: mul_conjC_ge0.
      by move/allP=> /(_ j (mem_index_enum _)) /= /eqP.
    apply/matrixP=> i j.
    have hzero : (M i j)^* * M i j = 0.
      move/eqP: (step1 j); rewrite psumr_eq0; last first.
        by move=> i' _; rewrite mulrC; exact: mul_conjC_ge0.
      by move/allP=> /(_ i (mem_index_enum _)) /= /eqP.
    move/eqP: hzero; rewrite mulf_eq0=> /orP[].
      by rewrite conjC_eq0 => /eqP->; rewrite mxE.
    by move/eqP->; rewrite mxE.
  Qed.

  (* View: ‖M‖ꜰ² = 0 <=> M = 0. *)
  Lemma frob_sq_eq0P r c (M : 'M[ℂ]_(r, c)) :
    reflect (M = 0) (frob_sq M == 0).
  Proof.
    apply: (iffP eqP).
    - exact: frob_sq_eq0.
    - by move=> ->; rewrite /frob_sq trmxC0 mul0mx mxtrace0.
  Qed.

  (*
    Если для любого eps > 0 имеем frob_sq < eps, то frob_sq = 0, откуда будет M
    = 0. Это нужно для отделимости метрики Фробениуса: разные матрицы лежат на
    положительном расстоянии.
  *)
  Lemma frob_sq_lt_eps_eq0 r c (M : 'M[ℂ]_(r, c)) :
    (forall eps : ℂ, 0 < eps -> frob_sq M < eps) -> frob_sq M = 0.
  Proof.
    move=> Hlt; apply/eqP; apply: contraT=> Hne.
    have nneg := frob_sq_ge0 M.
    have pos : 0 < frob_sq M by rewrite lt0r Hne nneg.
    by have := Hlt _ pos; rewrite ltxx.
  Qed.

  (* Алгебраические тождества. *)

  Lemma frob_sq0 r c :
    frob_sq (0 : 'M[ℂ]_(r, c)) = 0.
  Proof.
    by rewrite /frob_sq trmxC0 mul0mx mxtrace0.
  Qed.

  (* Инвариантность относительно знака. *)
  Lemma frob_sqN r c (M : 'M[ℂ]_(r, c)) :
    frob_sq (- M) = frob_sq M.
  Proof.
    rewrite /frob_sq trmxCN.
    have -> : (- M^t*) *m (- M) = M^t* *m M by rewrite mulNmx mulmxN opprK.
    by [].
  Qed.

  (* Эрмитово сопряжение не меняет нормы. *)
  Lemma frob_sq_trmxC r c (M : 'M[ℂ]_(r, c)) :
    frob_sq (M^t*) = frob_sq M.
  Proof.
    rewrite /frob_sq trmxCK.
    have e : \tr (M *m M^t*) = \tr (M^t* *m M) by rewrite mxtrace_mulC.
    by rewrite e.
  Qed.

  (*
    Норма разности двух матриц = 0 тогда и только тогда, когда матрицы равны.
  *)
  Lemma frob_sq_subr0 r c (A B : 'M[ℂ]_(r, c)) :
    frob_sq (A - B) = 0 -> A = B.
  Proof.
    by move/frob_sq_eq0/eqP; rewrite subr_eq0=> /eqP.
  Qed.

  (* Полное разложение скалярного произведения матриц через след. *)
  Lemma trmxC_dotE r c (A B : 'M[ℂ]_(r, c)) :
    \tr (A^t* *m B) = \sum_j \sum_i (A i j)^* * B i j.
  Proof.
    rewrite /mxtrace; apply: eq_bigr=> j _; rewrite mxE.
    by apply: eq_bigr=> i _; rewrite !mxE.
  Qed.

  (*
    Квадрат нормы Фробениуса есть след неотрицательно определённой матрицы
    $M† M$; в частности, неотрицательность даёт >= 0.
  *)
  Lemma psd_frob r c (M : 'M[ℂ]_(r, c)) :
    psd (M^t* *m M).
  Proof.
    split.
      by rewrite trmxC_mul trmxCK.
    move=> v.
    have nneg := frob_sq_ge0 (M *m v).
    rewrite /frob_sq trmxC_mul in nneg.
    suff -> : v^t* *m (M^t* *m M) *m v = (v^t* *m M^t*) *m (M *m v) by [].
    by rewrite !mulmxA.
  Qed.

  (*
    Неотрицательно определённая разность $A - B$ имеет неотрицательный след; в
    частности, $"tr" A - "tr" B >= 0$ при $B <= A$ согласно порядку Лёвнера.
  *)
  Lemma psd_le_trace n (A B : 'M[ℂ]_n) :
    psd (B - A) -> \tr A <= \tr B.
  Proof.
    move=> hpsd.
    have := psd_tr_ge0 hpsd.
    rewrite linearB /= subr_ge0; by [].
  Qed.

  (* $M M† <= "frob_sq"(M E)$ (через след: $"tr"(M M†) = "frob_sq" M$). *)
  Lemma MM_le_frob_id n (Mx : 'M[ℂ]_n) :
    psd_le (Mx *m Mx^t*) (frob_sq Mx *: 1%:M).
  Proof.
    have psdMM : psd (Mx *m Mx^t*) by have := psd_frob (Mx^t*); rewrite trmxCK.
    have trEq : \tr (Mx *m Mx^t*) = frob_sq Mx by rewrite /frob_sq mxtrace_mulC.
    have step := psd_le_trace_id psdMM; by rewrite trEq in step.
  Qed.

  (* Положительная определённость единичной матрицы. *)
  Lemma pd1 n : pd (1%:M : 'M[ℂ]_n).
  Proof.
    split; first by rewrite trmxC1.
    move=> v vNZ.
    rewrite mulmx1 -/(frob_sq v) lt0r.
    apply/andP; split; last exact: frob_sq_ge0.
    apply/negP=> /eqP /frob_sq_eq0 v0.
    by move: vNZ; rewrite v0 eqxx.
  Qed.

  (* Матрицы, пропорциональные единичной, и их упорядочивание. *)

  (* $a E$ неотрицательно определена при вещественном неотрицательном $a$. *)
  Lemma psd_scale1 n (a : ℂ) :
    a \is Num.real -> 0 <= a -> psd (a *: (1%:M : 'M[ℂ]_n)).
  Proof.
    move=> areal a_ge0.
    have ac : a^* = a by apply/CrealP.
    split; first by rewrite trmxC_scale trmxC1 ac.
    move=> v.
    rewrite -scalemxAr -scalemxAl mxtraceZ mulmx1.
    by apply: mulr_ge0=> //; exact: (frob_sq_ge0 v).
  Qed.

  (* Монотонность скалярного кратного единичной матрицы в порядке Лёвнера. *)
  Lemma psd_le_scale1 n (a b : ℂ) :
    a \is Num.real -> b \is Num.real -> a <= b ->
    psd_le (a *: (1%:M : 'M[ℂ]_n)) (b *: 1%:M).
  Proof.
    move=> areal breal aleb.
    rewrite /psd_le -scalerBl.
    apply: psd_scale1; first by apply: rpredB.
    by rewrite subr_ge0.
  Qed.

  (*
    Мажоранта следа сопряжения неотрицательно определённой матрицы:
    $tr (F M F†) <= frob_sq F * tr M$ при $M succ.eq 0$.
  *)
  Lemma tr_conj_frob_le n m (Fm : 'M[ℂ]_(n, m)) (M : 'M[ℂ]_m) :
    psd M -> \tr (Fm *m M *m Fm^t*) <= frob_sq Fm * \tr M.
  (*
    Спектральное разложение $M = U diag(l) U†, l_i >= 0$; для
    $W := (F U)† (F U)$ (неотрицательно определена) получаем
    $tr (F M F†) = ∑_i l_i W_(i i) <= ∑_i l_i (tr W) = (tr W)(∑_i l_i) = frob_sq F * tr M$,
    где $W_(i i) <= tr W$ ($W$ неотрицательно определена => диагональ <= след) и
    $tr W = frob_sq F$. Это заменяет общую субмультипликативность Фробениуса:
    нужный частный случай выводится напрямую из спектральной теоремы.
  *)
  Proof.
    move=> pM.
    have herm := psd_hermsym pM.
    have [U [l [hU [lreal Mdec]]]] := spectral_decomp herm.
    have psdD : psd (diag l) by apply: (psd_spec_conjK hU); rewrite -Mdec.
    have lnn := proj1 (psd_diagE lreal) psdD.
    pose X := Fm *m U.
    pose W := X^t* *m X.
    have Wpsd : psd W := psd_frob X.
    have trEq : \tr (Fm *m M *m Fm^t*) = \tr (diag l *m W).
      rewrite Mdec.
      rewrite (_ : Fm *m (U *m diag l *m U^t*) *m Fm^t*
                = X *m diag l *m X^t*); last by rewrite /X trmxC_mul !mulmxA.
      by rewrite mxtrace_mulC mulmxA -/W mxtrace_mulC.
    have trW : \tr W = frob_sq Fm.
      rewrite /W /X /frob_sq trmxC_mul mxtrace_mulC !mulmxA -[_ *m U *m U^t*]mulmxA.
      have /unitarymxP hUU := hU.
      by rewrite hUU mulmx1 mxtrace_mulC.
    have trSum : \tr (diag l *m W) = \sum_(i < m) l i * W i i.
      rewrite /mxtrace; apply: eq_bigr=> i _.
      rewrite mxE (bigD1 i) //=.
      rewrite big1 ?addr0; last first.
        by move=> j neij; rewrite mxE [i == j]eq_sym (negbTE neij) mul0r.
      by rewrite mxE eqxx.
    have Wii_ge0 : forall k, 0 <= W k k.
      by move=> k; rewrite -(qf_delta W k); exact: (proj2 Wpsd).
    have Wii_le : forall k, W k k <= \tr W.
      move=> k; rewrite /mxtrace (bigD1 k) //= lerDl.
      by apply: sumr_ge0=> j _; exact: Wii_ge0.
    have trM_eq : \tr M = \sum_(i < m) l i.
      rewrite Mdec mxtrace_mulC mulmxA (unitary_mulV hU) mul1mx.
      by rewrite /mxtrace; apply: eq_bigr=> i _; rewrite !mxE eqxx.
    rewrite trEq trSum trM_eq -trW mulr_sumr.
    apply: ler_sum=> i _; rewrite mulrC.
    apply: ler_pM; [exact: Wii_ge0 | exact: lnn | exact: Wii_le | exact: lexx].
  Qed.

  (*
    Мажоранта Фробениуса следом для неотрицательно определённых матриц:
    $"psd" M => "frob_sq" M <= ("tr" M)^2$.
  *)
  Lemma frob_sq_le_tr_sq n (M : 'M[ℂ]_n) :
    psd M -> frob_sq M <= (\tr M) ^+ 2.
  (*
    Через спектральное разложение $M = U "diag"(l) U†, space l_i >= 0$:
    $"frob_sq" M = "tr"(M† M) = "tr" M^2 = sum_i l_i^2$, $"tr" M = sum_i l_i$, и
    для неотрицательных $l_i$: $sum l_i^2 <= (sum l_i)^2$ (перекрёстные $>= 0$).

    Нужно, чтобы из $"tr"(U_k - L_k) -> 0$ и $0 <= X_k - L_k <= U_k - L_k$
    (неотрицательно определены) вывести $"frob_sq" -> 0$.
  *)
  Proof.
    move=> pM.
    have herm := psd_hermsym pM.
    have [U [l [hU [lreal Mdec]]]] := spectral_decomp herm.
    have psdD : psd (diag l) by apply: (psd_spec_conjK hU); rewrite -Mdec.
    have lnn := proj1 (psd_diagE lreal) psdD.
    have trM_eq : \tr M = \sum_(i < n) l i.
      rewrite Mdec mxtrace_mulC mulmxA (unitary_mulV hU) mul1mx.
      by rewrite /mxtrace; apply: eq_bigr=> i _; rewrite !mxE eqxx.
    have frob_sq_eq : frob_sq M = \sum_(i < n) (l i) ^+ 2.
      rewrite /frob_sq.
      have Mhermt : M^t* = M by rewrite -(hermsym_eq herm).
      rewrite Mhermt Mdec.
      have e1 : (U *m diag l *m U^t*) *m (U *m diag l *m U^t*)
              = U *m (diag l *m diag l) *m U^t*.
        by rewrite spec_conjM.
      rewrite e1 diagM.
      rewrite mxtrace_mulC mulmxA (unitary_mulV hU) mul1mx.
      rewrite /mxtrace; apply: eq_bigr=> i _.
      by rewrite !mxE eqxx /= -expr2.
    rewrite frob_sq_eq trM_eq.
    (* Цель: ∑ l_i² <= (∑ l_i)², раскрываем справа как сумму множителей. *)
    rewrite expr2 mulr_suml.
    apply: ler_sum=> i _.
    rewrite expr2 mulr_sumr.
    rewrite (bigD1 i) //= lerDl.
    apply: sumr_ge0=> j _.
    exact: mulr_ge0.
  Qed.

  (* Для эрмитовой матрицы: $"frob_sq" D = "tr"(D^2)$ (так как $D† = D$). *)
  Lemma frob_sq_herm n (D : 'M[ℂ]_n) :
    D \is hermsymmx -> frob_sq D = \tr (D *m D).
  Proof.
    move=> Dherm.
    have hD : D^t* = D by rewrite -(hermsym_eq Dherm).
    by rewrite /frob_sq hD.
  Qed.

  (* Эрмитовость произведения $F D F†$ при эрмитовой $D$. *)
  Lemma herm_conj n m (Fm : 'M[ℂ]_(n, m)) (D : 'M[ℂ]_m) :
    D \is hermsymmx -> (Fm *m D *m Fm^t*) \is hermsymmx.
  Proof.
    move=> Dherm.
    apply/is_hermitianmxP; rewrite expr0 scale1r.
    rewrite trmxC_mul trmxC_mul trmxCK mulmxA.
    by rewrite -(hermsym_eq Dherm).
  Qed.

  (*
    Неотрицательная определённость $D dot F_m† dot F_m dot D$ при эрмитовой
    $D$ - частный случай `psd_congr` для неотрицательно определённой матрицы
    $F_m† dot F_m$ (через `psd_frob`).
  *)
  Lemma psd_conj_herm_FtF n m (Fm : 'M[ℂ]_(n, m)) (D : 'M[ℂ]_m) :
    D \is hermsymmx -> psd (D *m Fm^t* *m Fm *m D).
  Proof.
    move=> Dherm.
    have hD : D = D^t* by exact: hermsym_eq.
    have eq1 : D *m Fm^t* *m Fm *m D = D^t* *m (Fm^t* *m Fm) *m D.
      by rewrite -hD !mulmxA.
    rewrite eq1.
    exact: psd_congr (psd_frob Fm).
  Qed.

  (*
    Контракция предсказывающего шага в норме Фробениуса:
    $D "эрмитова" => "frob_sq"(F_m D F_m†) <= ("frob_sq" F_m)^2 dot "frob_sq" D$.
  *)
  Lemma predict_diff_frob_bound n m (Fm : 'M[ℂ]_(n, m)) (D : 'M[ℂ]_m) :
    D \is hermsymmx ->
    frob_sq (Fm *m D *m Fm^t*) <= (frob_sq Fm) ^+ 2 * frob_sq D.
  (*
    Схема: $F_m D F_m†$ эрмитова (т.к. $D$ эрмитова), значит
    $"frob_sq"(F_m D F_m†) = "tr"((F_m D F_m†)^2)$. Применяем `tr_conj_frob_le`
    ($"psd"(D F_m† F_m D)$) и `tr_conj_frob_le` ($"psd"(F_m† F_m)$) - каждое
    даёт коэффициент $"frob_sq" F_m$. Итого
    $("frob_sq" F_m)^2 dot "tr"(D^2) = ("frob_sq" F_m)^2 dot "frob_sq" D$
    ($D$ эрмитова $=> "frob_sq" D = "tr" D^2$).
  *)
  Proof.
    move=> Dherm.
    have FDFherm : (Fm *m D *m Fm^t*) \is hermsymmx := herm_conj Fm Dherm.
    rewrite (frob_sq_herm FDFherm).
    (* Шаг 1: tr((F D F†) (F D F†)) = tr(F (D F† F D) F†). *)
    have step1 : (Fm *m D *m Fm^t*) *m (Fm *m D *m Fm^t*)
              = Fm *m (D *m Fm^t* *m Fm *m D) *m Fm^t*.
      by rewrite !mulmxA.
    rewrite step1.
    (* Шаг 2: `tr_conj_frob_le` с неотрицательно определённой $D F† F D$. *)
    have psd_DFtFD : psd (D *m Fm^t* *m Fm *m D) := psd_conj_herm_FtF Fm Dherm.
    apply: (le_trans (tr_conj_frob_le Fm psd_DFtFD)).
    (* Цель: frob_sq Fm * tr(D F† F D) <= (frob_sq Fm)² * frob_sq D. *)
    rewrite expr2 -mulrA.
    apply: ler_pM; first by exact: frob_sq_ge0.
    - by apply: psd_tr_ge0; exact: psd_DFtFD.
    - exact: lexx.
    (*
      Цель: $"tr"(D F† F D) <= "frob_sq" F_m dot "frob_sq" D$.
      $D F† F D = D (F† F) D$, и $D = D†$ (Эрмитовость); применяем
      `tr_conj_frob_le` ещё раз с $F_m := D$, $M := F† F_m$.
    *)
    - have hD : D = D^t* by exact: hermsym_eq.
      have rewriteDFtFD : D *m Fm^t* *m Fm *m D = D *m (Fm^t* *m Fm) *m D^t*.
        by rewrite -hD !mulmxA.
      rewrite rewriteDFtFD.
      apply: (le_trans (tr_conj_frob_le D (psd_frob Fm))).
      rewrite (frob_sq_herm Dherm).
      (* Цель: frob_sq D * tr(Fm† Fm) <= frob_sq Fm * tr(D D). *)
      have e1 : \tr (Fm^t* *m Fm) = frob_sq Fm by [].
      rewrite e1 [_ * \tr _]mulrC; exact: lexx.
  Qed.

End Frob.

(* Удобные нотации. *)

Notation "\fnorm M ^+ 2" := (frob_sq M)
  (at level 2,
  format "\fnorm  M  ^+  2") : ring_scope.
