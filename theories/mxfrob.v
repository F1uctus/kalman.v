(*  Фробениусов квадрат нормы матриц над numClosedFieldType.            *)
(*                                                                       *)
(*  Frobenius² norm:  ||M||_F² = \tr (M^t* *m M)                         *)
(*                            = \sum_{i,j} (M_{ij})^conj * M_{ij}         *)
(*                            = \sum_{i,j} `|M_{ij}|^2                    *)
(*                                                                       *)
(*  Этот файл — фундамент для:                                           *)
(*    * метрики на матрицах (через ||A - B||_F²);                        *)
(*    * монотонной сходимости PSD-последовательностей;                   *)
(*    * утверждений о пределах фильтра Калмана.                          *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import psd_base psd_order spectral.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.
Import Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section Frob.
Variable (C : numClosedFieldType).

(* ================================================================== *)
(* Определение и базовые тождества                                    *)
(* ================================================================== *)

Definition frob_sq r c (M : 'M[C]_(r, c)) : C := \tr (M^t* *m M).

(* Развёртка: ||M||_F² = \sum_{i,j} M_{ij}^* * M_{ij}.
   Удобно для энтрипоинтных аргументов. *)
Lemma frob_sqE r c (M : 'M[C]_(r, c)) :
  frob_sq M = \sum_j \sum_i (M i j)^* * M i j.
Proof.
rewrite /frob_sq /mxtrace.
apply: eq_bigr=> j _; rewrite mxE.
by apply: eq_bigr=> i _; rewrite !mxE.
Qed.

(* Неотрицательность. *)
Lemma frob_sq_ge0 r c (M : 'M[C]_(r, c)) : 0 <= frob_sq M.
Proof.
rewrite frob_sqE; apply: sumr_ge0=> j _; apply: sumr_ge0=> i _.
by rewrite mulrC; exact: mul_conjC_ge0.
Qed.

(* Зануление характеризует нулевую матрицу. *)
Lemma frob_sq_eq0 r c (M : 'M[C]_(r, c)) : frob_sq M = 0 -> M = 0.
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

Lemma frob_sq_eq0P r c (M : 'M[C]_(r, c)) :
  reflect (M = 0) (frob_sq M == 0).
Proof.
apply: (iffP eqP).
- exact: frob_sq_eq0.
- by move=> ->; rewrite /frob_sq trmxC0 mul0mx mxtrace0.
Qed.

(* Если для любого eps > 0 имеем frob_sq < eps, то frob_sq = 0,
   откуда M = 0.  Это даст нам "Хаусдорфовость" Фробениусовой
   метрики: разные матрицы лежат на положительном расстоянии. *)
Lemma frob_sq_lt_eps_eq0 r c (M : 'M[C]_(r, c)) :
  (forall eps : C, 0 < eps -> frob_sq M < eps) -> frob_sq M = 0.
Proof.
move=> Hlt; apply/eqP; apply: contraT=> Hne.
have nneg := frob_sq_ge0 M.
have pos : 0 < frob_sq M by rewrite lt0r Hne nneg.
by have := Hlt _ pos; rewrite ltxx.
Qed.

(* ================================================================== *)
(* Алгебраические тождества                                            *)
(* ================================================================== *)

Lemma frob_sq0 r c : frob_sq (0 : 'M[C]_(r, c)) = 0.
Proof. by rewrite /frob_sq trmxC0 mul0mx mxtrace0. Qed.

Lemma frob_sqN r c (M : 'M[C]_(r, c)) : frob_sq (- M) = frob_sq M.
Proof.
rewrite /frob_sq trmxCN.
have -> : (- M^t*) *m (- M) = M^t* *m M by rewrite mulNmx mulmxN opprK.
by [].
Qed.

(* Сопряжение/транспонирование не меняет Фробениусов квадрат. *)
Lemma frob_sq_trmxC r c (M : 'M[C]_(r, c)) : frob_sq (M^t*) = frob_sq M.
Proof.
rewrite /frob_sq trmxCK.
have e : \tr (M *m M^t*) = \tr (M^t* *m M) by rewrite mxtrace_mulC.
by rewrite e.
Qed.

(* "Loose triangle": ||A + B||² ≤ 2 (||A||² + ||B||²).  Однако нам
   достаточно более простого факта: если ||A - B||_F² = 0, то A = B. *)
Lemma frob_sq_subr0 r c (A B : 'M[C]_(r, c)) :
  frob_sq (A - B) = 0 -> A = B.
Proof. by move/frob_sq_eq0/eqP; rewrite subr_eq0=> /eqP. Qed.

(* Полное разложение скалярного произведения матриц через след:
     tr(A^t* B) = \sum_{i,j} (A_{ij})^* * B_{ij}                        *)
Lemma trmxC_dotE r c (A B : 'M[C]_(r, c)) :
  \tr (A^t* *m B) = \sum_j \sum_i (A i j)^* * B i j.
Proof.
rewrite /mxtrace; apply: eq_bigr=> j _; rewrite mxE.
by apply: eq_bigr=> i _; rewrite !mxE.
Qed.

(* ================================================================== *)
(* PSD-связи                                                           *)
(* ================================================================== *)

(* Фробениусов квадрат есть след psd-матрицы M^t* *m M; в частности,
   PSD-неотрицательность даёт ≥ 0 (повторно — уже доказали). *)
Lemma psd_frob r c (M : 'M[C]_(r, c)) : psd (M^t* *m M).
Proof.
split.
  by rewrite trmxC_mul trmxCK.
move=> v.
have nneg := frob_sq_ge0 (M *m v).
rewrite /frob_sq trmxC_mul in nneg.
suff -> : v^t* *m (M^t* *m M) *m v = (v^t* *m M^t*) *m (M *m v) by [].
by rewrite !mulmxA.
Qed.

(* Для psd-матрицы A её след неотрицателен (повторно с psd_tr_ge0). *)
Lemma psd_trace_ge0 n (A : 'M[C]_n) : psd A -> 0 <= \tr A.
Proof. exact: psd_tr_ge0. Qed.

(* PSD-разность A - B имеет неотрицательный след; в частности,
   tr A - tr B ≥ 0 при B ≤ A в смысле Лёвнера. *)
Lemma psd_le_trace n (A B : 'M[C]_n) :
  psd (B - A) -> \tr A <= \tr B.
Proof.
move=> hpsd.
have := psd_tr_ge0 hpsd.
rewrite linearB /= subr_ge0; by [].
Qed.

(* ================================================================== *)
(* Скалярные кратные единичной матрицы и их PSD-порядок                *)
(* ================================================================== *)

(* `a *: 1%:M` PSD при вещественном неотрицательном `a`. *)
Lemma psd_scale1 n (a : C) :
  a \is Num.real -> 0 <= a -> psd (a *: (1%:M : 'M[C]_n)).
Proof.
move=> areal a_ge0.
have ac : a^* = a by apply/CrealP.
split; first by rewrite trmxC_scale trmxC1 ac.
move=> v.
rewrite -scalemxAr -scalemxAl mxtraceZ mulmx1.
by apply: mulr_ge0=> //; exact: (frob_sq_ge0 v).
Qed.

(* Монотонность скалярного кратного единичной матрицы в порядке Лёвнера. *)
Lemma psd_le_scale1 n (a b : C) :
  a \is Num.real -> b \is Num.real -> a <= b ->
  psd_le (a *: (1%:M : 'M[C]_n)) (b *: 1%:M).
Proof.
move=> areal breal aleb.
rewrite /psd_le -scalerBl.
apply: psd_scale1; first by apply: rpredB.
by rewrite subr_ge0.
Qed.

(* ================================================================== *)
(* Фробениусова мажоранта следа сопряжения PSD-матрицы:               *)
(*   tr (F M Fconj) <= frob_sq F * tr M   при psd M.                  *)
(*                                                                    *)
(* Доказательство: спектральное разложение M = U diag(l) Uconj,       *)
(* l_i >= 0; для W := (F U)conj (F U) (PSD) получаем                  *)
(*   tr (F M Fconj) = \sum_i l_i W_ii <= \sum_i l_i (tr W)            *)
(*                  = (tr W)(\sum_i l_i) = frob_sq F * tr M,          *)
(* где W_ii <= tr W (W PSD => диагональ <= след) и tr W = frob_sq F.  *)
(* Это заменяет общую субмультипликативность Фробениуса:              *)
(* нужный частный случай выводится напрямую из спектральной теоремы.  *)
Lemma tr_conj_frob_le n m (Fm : 'M[C]_(n, m)) (M : 'M[C]_m) :
  psd M -> \tr (Fm *m M *m Fm^t*) <= frob_sq Fm * \tr M.
Proof.
move=> pM.
have herm := psd_hermsym pM.
have [U [l [hU [lreal Mdec]]]] := spectral_theorem herm.
have psdD : psd (diag_of l) by apply: (psd_spec_conj_inj hU); rewrite -Mdec.
have lnn := proj1 (psd_diag_iff_real lreal) psdD.
pose X := Fm *m U.
pose W := X^t* *m X.
have Wpsd : psd W := psd_frob X.
have trEq : \tr (Fm *m M *m Fm^t*) = \tr (diag_of l *m W).
  rewrite Mdec.
  rewrite (_ : Fm *m (U *m diag_of l *m U^t*) *m Fm^t*
             = X *m diag_of l *m X^t*); last by rewrite /X trmxC_mul !mulmxA.
  by rewrite mxtrace_mulC mulmxA -/W mxtrace_mulC.
have trW : \tr W = frob_sq Fm.
  rewrite /W /X /frob_sq trmxC_mul mxtrace_mulC !mulmxA -[_ *m U *m U^t*]mulmxA.
  have /unitarymxP hUU := hU.
  by rewrite hUU mulmx1 mxtrace_mulC.
have trSum : \tr (diag_of l *m W) = \sum_(i < m) l i * W i i.
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

(* ================================================================== *)
(* Мажоранта Фробениуса следом для PSD-матриц:                         *)
(*   psd M  ⇒  frob_sq M ≤ (\tr M)^+2.                                  *)
(*                                                                    *)
(* Через спектральное разложение M = U diag(l) U^t*, l_i ≥ 0:           *)
(*   frob_sq M = \tr (M^t* M) = \tr M² = \sum_i l_i²,                  *)
(*   \tr M = \sum_i l_i,                                                *)
(* и для неотрицательных l_i: ∑ l_i² ≤ (∑ l_i)² (перекрёстные ≥ 0).    *)
(*                                                                    *)
(* Нужно в Session 12 для tracesqueeze: чтобы из `\tr (U_k - L_k) → 0` *)
(* и `0 ≤ X_k - L_k ≤ U_k - L_k` (PSD) вывести `frob_sq → 0`.           *)
Lemma frob_sq_le_tr_sq n (M : 'M[C]_n) :
  psd M -> frob_sq M <= (\tr M) ^+ 2.
Proof.
move=> pM.
have herm := psd_hermsym pM.
have [U [l [hU [lreal Mdec]]]] := spectral_theorem herm.
have psdD : psd (diag_of l) by apply: (psd_spec_conj_inj hU); rewrite -Mdec.
have lnn := proj1 (psd_diag_iff_real lreal) psdD.
have trM_eq : \tr M = \sum_(i < n) l i.
  rewrite Mdec mxtrace_mulC mulmxA (unitary_mulV hU) mul1mx.
  by rewrite /mxtrace; apply: eq_bigr=> i _; rewrite !mxE eqxx.
have frob_sq_eq : frob_sq M = \sum_(i < n) (l i) ^+ 2.
  rewrite /frob_sq.
  have Mhermt : M^t* = M by rewrite -(hermsym_eq herm).
  rewrite Mhermt Mdec.
  have e1 : (U *m diag_of l *m U^t*) *m (U *m diag_of l *m U^t*)
          = U *m (diag_of l *m diag_of l) *m U^t*.
    by rewrite spec_conj_mul.
  rewrite e1 diag_of_mul.
  rewrite mxtrace_mulC mulmxA (unitary_mulV hU) mul1mx.
  rewrite /mxtrace; apply: eq_bigr=> i _.
  by rewrite !mxE eqxx /= -expr2.
rewrite frob_sq_eq trM_eq.
(* Goal: \sum l_i^2 ≤ (\sum l_i)^2; expand RHS as sum of products. *)
rewrite expr2 mulr_suml.
apply: ler_sum=> i _.
rewrite expr2 mulr_sumr.
rewrite (bigD1 i) //= lerDl.
apply: sumr_ge0=> j _.
exact: mulr_ge0.
Qed.

(* ================================================================== *)
(* Контракция предсказывающего шага в Фробениусе:                     *)
(*   D \is hermsymmx ⇒                                                 *)
(*     frob_sq (Fm *m D *m Fmᶜ) ≤ (frob_sq Fm)^+2 * frob_sq D.          *)
(*                                                                    *)
(* Доказательство: Fm D Fmᶜ эрмитова (D эрмитова), значит               *)
(*   frob_sq (Fm D Fmᶜ) = \tr ((Fm D Fmᶜ)²).                            *)
(* Применяем `tr_conj_frob_le` (psd (D *m Fmᶜ *m Fm *m D)) и             *)
(* `tr_conj_frob_le` (psd (Fmᶜ *m Fm)) — каждое даёт коэффициент        *)
(* `frob_sq Fm`. Итого `(frob_sq Fm)^+2 * \tr (D²) = (frob_sq Fm)^+2 *  *)
(* frob_sq D` (D эрмитова ⇒ frob_sq D = \tr D²).                        *)
Lemma frob_sq_herm n (D : 'M[C]_n) :
  D \is hermsymmx -> frob_sq D = \tr (D *m D).
Proof.
move=> Dherm.
have hD : D^t* = D by rewrite -(hermsym_eq Dherm).
by rewrite /frob_sq hD.
Qed.

(* Эрмитовость произведения F D F^t* при эрмитовой D. *)
Lemma herm_conj n m (Fm : 'M[C]_(n, m)) (D : 'M[C]_m) :
  D \is hermsymmx -> (Fm *m D *m Fm^t*) \is hermsymmx.
Proof.
move=> Dherm.
apply/is_hermitianmxP; rewrite expr0 scale1r.
rewrite trmxC_mul trmxC_mul trmxCK mulmxA.
by rewrite -(hermsym_eq Dherm).
Qed.

(* PSD-ность D *m Fm^t* *m Fm *m D при эрмитовой D — частный случай *)
(* psd_congruence для PSD матрицы Fm^t* *m Fm = (psd_frob).            *)
Lemma psd_conj_herm_FtF n m (Fm : 'M[C]_(n, m)) (D : 'M[C]_m) :
  D \is hermsymmx -> psd (D *m Fm^t* *m Fm *m D).
Proof.
move=> Dherm.
have hD : D = D^t* by exact: hermsym_eq.
have eq1 : D *m Fm^t* *m Fm *m D = D^t* *m (Fm^t* *m Fm) *m D.
  by rewrite -hD !mulmxA.
rewrite eq1.
exact: psd_congruence (psd_frob Fm).
Qed.

Lemma predict_diff_frob_bound n m (Fm : 'M[C]_(n, m)) (D : 'M[C]_m) :
  D \is hermsymmx ->
  frob_sq (Fm *m D *m Fm^t*) <= (frob_sq Fm) ^+ 2 * frob_sq D.
Proof.
move=> Dherm.
have FDFherm : (Fm *m D *m Fm^t*) \is hermsymmx := herm_conj Fm Dherm.
rewrite (frob_sq_herm FDFherm).
(* Шаг 1: \tr ((F D Fᶜ) (F D Fᶜ)) = \tr (F (D Fᶜ F D) Fᶜ). *)
have step1 : (Fm *m D *m Fm^t*) *m (Fm *m D *m Fm^t*)
           = Fm *m (D *m Fm^t* *m Fm *m D) *m Fm^t*.
  by rewrite !mulmxA.
rewrite step1.
(* Шаг 2: tr_conj_frob_le с PSD-матрицей (D Fᶜ F D). *)
have psd_DFtFD : psd (D *m Fm^t* *m Fm *m D) := psd_conj_herm_FtF Fm Dherm.
apply: (le_trans (tr_conj_frob_le Fm psd_DFtFD)).
(* Цель: frob_sq Fm * \tr (D Fᶜ F D) ≤ (frob_sq Fm)^+2 * frob_sq D. *)
rewrite expr2 -mulrA.
apply: ler_pM; first by exact: frob_sq_ge0.
- by apply: psd_tr_ge0; exact: psd_DFtFD.
- exact: lexx.
- (* Цель: \tr (D Fᶜ F D) ≤ frob_sq Fm * frob_sq D. *)
  (* D Fᶜ F D = D *m (Fᶜ F) *m D, и D = Dᶜ (Hermitian);  *)
  (* применяем tr_conj_frob_le ещё раз с Fm := D, M := Fᶜ Fm. *)
  have hD : D = D^t* by exact: hermsym_eq.
  have rewriteDFtFD : D *m Fm^t* *m Fm *m D = D *m (Fm^t* *m Fm) *m D^t*.
    by rewrite -hD !mulmxA.
  rewrite rewriteDFtFD.
  apply: (le_trans (tr_conj_frob_le D (psd_frob Fm))).
  rewrite (frob_sq_herm Dherm).
  (* Цель: frob_sq D * \tr (Fmᶜ Fm) ≤ frob_sq Fm * \tr (D D). *)
  have e1 : \tr (Fm^t* *m Fm) = frob_sq Fm by [].
  rewrite e1 [_ * \tr _]mulrC; exact: lexx.
Qed.

End Frob.

(* ================================================================== *)
(* Удобные нотации                                                     *)
(* ================================================================== *)

Notation "\fnorm M ^+ 2" := (frob_sq M) (at level 2, format "\fnorm  M  ^+  2") : ring_scope.
