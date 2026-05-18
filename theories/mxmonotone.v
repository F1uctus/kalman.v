(*  Монотонная сходимость PSD-последовательностей матриц.                *)
(*                                                                       *)
(*  Главный результат: если S : nat -> 'M[C]_n монотонна по порядку      *)
(*  Лёвнера (S k ≤ S k.+1) и ограничена сверху матрицей B (S k ≤ B),     *)
(*  то S сходится в матричной топологии к пределу L, который PSD и       *)
(*  удовлетворяет L ≤ B.                                                  *)
(*                                                                       *)
(*  numClosedFieldType сам по себе не полон; секция параметризована      *)
(*  "вещественным мостом" r2c : R -> C, c2r : C -> R (CoqQ-стиль          *)
(*  extNumType).  Скалярная монотонная сходимость лифтуется из R          *)
(*  (mathcomp-analysis), а off-diagonal восстанавливается через           *)
(*  квадратичные формы с тестовыми векторами δ_i + δ_j и δ_i + 'i δ_j.   *)
(*  Хипотезы моста будут разряжены позже специализацией C.                *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import psd_base psd_order mxfrob mxtopo.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* ================================================================== *)
(*  Квадратичные формы на PSD-матрицах                                 *)
(* ================================================================== *)

Section QfPsd.
Variable (C : numClosedFieldType) (n : nat).
Implicit Types (M : 'M[C]_n) (v : 'cV[C]_n).

Lemma qf_psd_real M v : psd M -> \tr (v^t* *m M *m v) \is Num.real.
Proof. by case=> _ HM; exact: ger0_real (HM v). Qed.

Lemma qf_psd_ge0 M v : psd M -> 0 <= \tr (v^t* *m M *m v).
Proof. by case=> _ HM; exact: HM. Qed.

Lemma qf_psd_le (A B : 'M[C]_n) v :
  psd_le A B ->
  \tr (v^t* *m A *m v) <= \tr (v^t* *m B *m v).
Proof.
rewrite /psd_le=> [[Hsym HBA]].
have := HBA v.
by rewrite mulmxBr mulmxBl linearB /= subr_ge0.
Qed.

(* "Перекрёстная" qf-форма с разными векторами слева/справа. *)
Lemma qf_delta_cross M (i j : 'I_n) :
  \tr ((delta_mx i ord0 : 'cV[C]_n)^t* *m M *m delta_mx j ord0) = M i j.
Proof.
have del_eq : (delta_mx i ord0 : 'cV[C]_n)^t* = (delta_mx ord0 i : 'rV[C]_n).
  by rewrite trmx_delta map_delta_mx.
rewrite del_eq -rowE trace_mx11 mxE (bigD1 j)//= big1; last first.
  by move=> k nekj; rewrite !mxE eqxx andbT (negbTE nekj) mulr0.
by rewrite !mxE !eqxx /= mulr1 addr0.
Qed.

(* Раскладка qf-формы по сумме векторов. *)
Lemma qf_decomp M (v1 v2 : 'cV[C]_n) :
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

(* Раскладка для скалярного сдвига во второй компоненте. *)
Lemma qf_decomp_scaleZ M (v1 v2 : 'cV[C]_n) (a : C) :
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
  \tr ((delta_mx i ord0 + delta_mx j ord0 : 'cV[C]_n)^t*
        *m M *m (delta_mx i ord0 + delta_mx j ord0)) =
  M i i + M i j + M j i + M j j.
Proof. by rewrite qf_decomp !qf_delta !qf_delta_cross. Qed.

Lemma qf_delta_pairi M (i j : 'I_n) :
  \tr ((delta_mx i ord0 + 'i *: delta_mx j ord0 : 'cV[C]_n)^t*
        *m M *m (delta_mx i ord0 + 'i *: delta_mx j ord0)) =
  M i i + M j j + 'i * (M i j - M j i).
Proof.
rewrite qf_decomp_scaleZ !qf_delta !qf_delta_cross.
have conji : ('i : C)^* = - 'i by exact: conjCi.
rewrite conji.
have miE : (- ('i : C)) * 'i = 1.
  by rewrite mulNr -expr2 sqrCi opprK.
rewrite miE mul1r mulNr.
(* Goal: M i i + 'i * M i j + - ('i * M j i) + M j j
       = M i i + M j j + 'i * (M i j - M j i) *)
rewrite mulrBr -!addrA; congr (M i i + _).
rewrite [- _ + M j j]addrC addrA [_ + M j j]addrC.
by rewrite -addrA.
Qed.

End QfPsd.

(* ================================================================== *)
(*  Вещественный мост R / C и лифт монотонной сходимости               *)
(* ================================================================== *)

Section MxBridge.
Variables (R : realType) (C : numClosedFieldType).
Variable r2c : {rmorphism R -> C}.
Variable c2r : C -> R.
Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
Hypothesis r2cK : cancel r2c c2r.
Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
Hypothesis c2r_continuous : continuous (c2r : C -> R).
Hypothesis r2c_continuous : continuous (r2c : R -> C).

(* Скалярные помощники: сходимость суммы / произведения / отрицания /
   разности для C-значных последовательностей (через C^o). *)
Lemma cvgC_D (f g : nat -> C) (a b : C) :
  f @ \oo --> a -> g @ \oo --> b -> (fun k => f k + g k) @ \oo --> a + b.
Proof.
move=> Hf Hg t Ht /=.
have Hf' : (f : nat -> C^o) @ \oo --> (a : C^o) by exact: Hf.
have Hg' : (g : nat -> C^o) @ \oo --> (b : C^o) by exact: Hg.
exact: (cvgD Hf' Hg' Ht).
Qed.

Lemma cvgC_M (f g : nat -> C) (a b : C) :
  f @ \oo --> a -> g @ \oo --> b -> (fun k => f k * g k) @ \oo --> a * b.
Proof.
move=> Hf Hg t Ht /=.
have Hf' : (f : nat -> C^o) @ \oo --> (a : C^o) by exact: Hf.
have Hg' : (g : nat -> C^o) @ \oo --> (b : C^o) by exact: Hg.
exact: (cvgM Hf' Hg' Ht).
Qed.

Lemma cvgC_N (f : nat -> C) (a : C) :
  f @ \oo --> a -> (fun k => - f k) @ \oo --> - a.
Proof.
move=> Hf.
have H : (fun k => -1 * f k) @ \oo --> -1 * a := cvgC_M (cvg_cst _) Hf.
have eq_f : (fun k => - f k) = (fun k => -1 * f k).
  by apply/funext=> k; rewrite mulN1r.
rewrite eq_f -[- a]mulN1r.
exact: H.
Qed.

Lemma cvgC_B (f g : nat -> C) (a b : C) :
  f @ \oo --> a -> g @ \oo --> b -> (fun k => f k - g k) @ \oo --> a - b.
Proof. by move=> Hf Hg; apply: cvgC_D=> //; exact: cvgC_N. Qed.

Lemma r2c_inj : injective r2c.
Proof. exact: (can_inj r2cK). Qed.

Lemma ler_c2r (x y : C) :
  x \is Num.real -> y \is Num.real -> (c2r x <= c2r y) = (x <= y).
Proof. by move=> Rx Ry; rewrite -[in RHS](c2rK Rx) -[in RHS](c2rK Ry) ler_r2c. Qed.

Lemma r2c_real (x : R) : r2c x \is Num.real.
Proof.
have [hx0|hx0] := lerP 0 x.
- by rewrite ger0_real // -(rmorph0 r2c) ler_r2c.
- by rewrite ler0_real // -(rmorph0 r2c) ler_r2c ltW.
Qed.

(* Лифт mathcomp's `nondecreasing_is_cvgn` на C-значные вещественные
   последовательности.  Сходимость трактуется в C^o-топологии. *)
Lemma nondecreasing_real_is_cvgn (u : nat -> C) (Mu : C) :
  (forall n, u n \is Num.real) -> Mu \is Num.real ->
  {homo u : i j / (i <= j)%N >-> i <= j} ->
  (forall n, u n <= Mu) ->
  cvgn u.
Proof.
move=> Hreal HMreal Hmono Hub.
pose v : nat -> R := c2r \o u.
have Hv_mono : nondecreasing_seq v.
  by move=> i j leij; rewrite /v /= ler_c2r//; exact: Hmono.
have Hv_ub : has_ubound (range v).
  exists (c2r Mu)=> _ /= [k _ <-].
  by rewrite /v /= ler_c2r//; exact: Hub.
have Hv_cvg : cvgn v := nondecreasing_is_cvgn Hv_mono Hv_ub.
have Hu_eq : u = r2c \o v :> (nat -> C).
  by apply/funext=> k; rewrite /v /= c2rK.
apply/cvg_ex; exists (r2c (limn v)).
rewrite Hu_eq.
apply: cvg_comp; first exact: Hv_cvg.
exact: r2c_continuous.
Qed.

Lemma cvgn_real_closed (u : nat -> C) (l : C) :
  (forall n, u n \is Num.real) ->
  u @ \oo --> l -> l \is Num.real.
Proof.
move=> Hreal Hcvg.
have Hu_eq : u = r2c \o (c2r \o u) :> (nat -> C).
  by apply/funext=> n; rewrite /= c2rK.
have Hc2r : (c2r \o u) @ \oo --> c2r l.
  apply: cvg_comp; first exact: Hcvg.
  exact: c2r_continuous.
have Hcvgr2c : (r2c \o (c2r \o u)) @ \oo --> r2c (c2r l).
  apply: cvg_comp; first exact: Hc2r.
  exact: r2c_continuous.
have HausC : hausdorff_space (C^o : pseudoMetricNormedZmodType _).
  exact: norm_hausdorff.
have Hcvgr2c_o : (r2c \o (c2r \o u) : nat -> C^o) @ \oo --> (r2c (c2r l) : C^o).
  exact: Hcvgr2c.
have Hcvg_o : (r2c \o (c2r \o u) : nat -> C^o) @ \oo --> (l : C^o).
  by rewrite -Hu_eq; exact: Hcvg.
have hEq : (l : C^o) = (r2c (c2r l) : C^o).
  exact: cvg_unique Hcvg_o Hcvgr2c_o.
by rewrite (hEq : l = _); exact: r2c_real.
Qed.

Lemma cvgn_real_le_C (u : nat -> C) (Mu l : C) :
  (forall n, u n \is Num.real) -> Mu \is Num.real ->
  u @ \oo --> l ->
  (forall n, u n <= Mu) ->
  l <= Mu.
Proof.
move=> Hreal HMreal Hcvg Hub.
have Hlreal := cvgn_real_closed Hreal Hcvg.
pose v : nat -> R := c2r \o u.
have Hv : v @ \oo --> c2r l.
  apply: cvg_comp; first exact: Hcvg.
  exact: c2r_continuous.
have Hv_ub : forall n, v n <= c2r Mu.
  by move=> n; rewrite /v /= ler_c2r//; exact: Hub.
have Hv_cvg : cvg (v @ \oo) by apply/cvg_ex; exists (c2r l); exact: Hv.
have Hlimv : limn v = c2r l.
  by apply: cvg_lim; [exact: Rhausdorff | exact: Hv].
have Hlimr : limn v <= c2r Mu.
  by apply: limr_le=> //; near=> n; exact: Hv_ub.
by rewrite -ler_c2r // -Hlimv.
Unshelve. all: by end_near. Qed.

Lemma cvgn_real_ge_C (u : nat -> C) (m l : C) :
  (forall n, u n \is Num.real) -> m \is Num.real ->
  u @ \oo --> l ->
  (forall n, m <= u n) ->
  m <= l.
Proof.
move=> Hreal Hmreal Hcvg Hlb.
have Hcvg_o : (u : nat -> C^o) @ \oo --> (l : C^o) by exact: Hcvg.
have Hcvg' : ((fun k => - u k) : nat -> C^o) @ \oo --> (- l : C^o).
  exact: cvgN Hcvg_o.
have Hcvg'' : (fun k => - u k) @ \oo --> - l by exact: Hcvg'.
have HnegReal : forall n, - u n \is Num.real by move=> n; rewrite rpredN.
have HmReal : - m \is Num.real by rewrite rpredN.
have Hub : forall n, - u n <= - m by move=> n; rewrite lerN2.
have := cvgn_real_le_C HnegReal HmReal Hcvg'' Hub.
by rewrite lerN2.
Qed.

(* ================================================================== *)
(*  Сходимость PSD-монотонной матричной последовательности             *)
(* ================================================================== *)

Variable n : nat.
Variable Smx : nat -> 'M[C]_n.
Variable Bmx : 'M[C]_n.
Hypothesis S_psd : forall k, psd (Smx k).
Hypothesis S_mono : forall k, psd_le (Smx k) (Smx k.+1).
Hypothesis S_bnd : forall k, psd_le (Smx k) Bmx.
Local Notation S := Smx.
Local Notation B := Bmx.

Lemma B_psd : psd B.
Proof.
apply/psd_le0_psd; apply: (psd_le_trans (B := S 0%N)).
- by rewrite psd_le0_psd; exact: S_psd.
- exact: S_bnd.
Qed.

Lemma S_mono_le (i j : nat) : (i <= j)%N -> psd_le (S i) (S j).
Proof.
elim: j i => [|j IHj] i; first by rewrite leqn0=> /eqP->; apply: psd_le_refl; exact: S_psd.
rewrite leq_eqVlt=> /orP[/eqP->|]; first by apply: psd_le_refl; exact: S_psd.
by rewrite ltnS=> Hij; apply: (psd_le_trans (IHj _ Hij)); exact: S_mono.
Qed.

Lemma qf_seq_cvgn (v : 'cV[C]_n) :
  cvgn (fun k => \tr (v^t* *m S k *m v)).
Proof.
apply: (nondecreasing_real_is_cvgn (Mu := \tr (v^t* *m B *m v))).
- by move=> k; apply: qf_psd_real; exact: S_psd.
- by apply: qf_psd_real; exact: B_psd.
- by move=> i j leij; apply: qf_psd_le; exact: S_mono_le.
- by move=> k; apply: qf_psd_le; exact: S_bnd.
Qed.

Lemma S_diag_cvgn (i : 'I_n) :
  cvgn (fun k => (S k) i i).
Proof.
suff : cvgn (fun k => \tr ((delta_mx i ord0 : 'cV[C]_n)^t* *m S k *m delta_mx i ord0)).
  by under eq_is_cvg=> k do rewrite qf_delta.
exact: qf_seq_cvgn.
Qed.

Lemma S_entry_cvgn (i j : 'I_n) :
  cvgn (fun k => (S k) i j).
Proof.
have HDi : (fun k => (S k) i i) @ \oo --> limn (fun k => (S k) i i).
  exact: (@S_diag_cvgn i).
have HDj : (fun k => (S k) j j) @ \oo --> limn (fun k => (S k) j j).
  exact: (@S_diag_cvgn j).
pose vp : 'cV[C]_n := delta_mx i ord0 + delta_mx j ord0.
pose vi : 'cV[C]_n := delta_mx i ord0 + 'i *: delta_mx j ord0.
have HQ1 : (fun k => \tr (vp^t* *m S k *m vp)) @ \oo -->
           limn (fun k => \tr (vp^t* *m S k *m vp)).
  exact: (@qf_seq_cvgn vp).
have HQ2 : (fun k => \tr (vi^t* *m S k *m vi)) @ \oo -->
           limn (fun k => \tr (vi^t* *m S k *m vi)).
  exact: (@qf_seq_cvgn vi).
(* В каждом k:
   2 * S k i j = (qf1 - S k i i - S k j j) - 'i * (qf2 - S k i i - S k j j) *)
have Hentry_eq : forall k,
  2%:R * (S k) i j =
  (\tr (vp^t* *m S k *m vp) - (S k) i i - (S k) j j)
  - 'i * (\tr (vi^t* *m S k *m vi) - (S k) i i - (S k) j j).
  move=> k; rewrite /vp /vi qf_delta_pair qf_delta_pairi.
  set a := (S k) i i; set b := (S k) j j.
  set c := (S k) i j; set d := (S k) j i.
  have step1 : a + c + d + b - a - b = c + d.
    by rewrite [_ + b - a]addrAC [_ + d - a]addrAC [a + c - a]addrAC
                subrr add0r addrK.
  have step2 : a + b + 'i * (c - d) - a - b = 'i * (c - d).
    by rewrite [_ - a]addrAC [a + b - a]addrAC subrr add0r
                [_ + 'i * _]addrC addrK.
  rewrite (_ : a + c + d + b - a - b = c + d); last by exact: step1.
  rewrite (_ : a + b + 'i * (c - d) - a - b = 'i * (c - d)); last by exact: step2.
  rewrite mulrA -expr2 sqrCi mulN1r opprK.
  rewrite addrACA subrr addr0.
  by rewrite -mulr2n mulr_natl.
(* Сходимость (2 * S k i j) через cvgC_D/cvgC_M в C topology *)
pose target : C := (limn (fun k => \tr (vp^t* *m S k *m vp))
                    - limn (fun k => (S k) i i)
                    - limn (fun k => (S k) j j))
                   - 'i * (limn (fun k => \tr (vi^t* *m S k *m vi))
                           - limn (fun k => (S k) i i)
                           - limn (fun k => (S k) j j)).
have HBR1 := cvgC_B (cvgC_B HQ1 HDi) HDj.
have HBR2 := cvgC_B (cvgC_B HQ2 HDi) HDj.
have FF : Filter (\oo : set_system nat) by typeclasses eauto.
have Hi_const : (fun _ : nat => ('i : C)) @ \oo --> ('i : C).
  exact: cvg_cst.
have HiBR2 := cvgC_M Hi_const HBR2.
have Htwosij : (fun k => 2%:R * (S k) i j) @ \oo --> target.
  have := cvgC_B HBR1 HiBR2.
  by under eq_cvg=> k do rewrite -(Hentry_eq k).
(* Делим на 2: (S k) i j = (2 * (S k) i j) / 2. *)
have H2neq : (2%:R : C) != 0 by rewrite pnatr_eq0.
have Hsij : (fun k => (S k) i j) @ \oo --> target / 2%:R.
  have Hinv : (fun _ : nat => (2%:R : C)^-1) @ \oo --> (2%:R : C)^-1.
    exact: cvg_cst.
  have := cvgC_M Htwosij Hinv.
  by under eq_cvg=> k do rewrite mulrAC mulfV // mul1r.
by apply/cvg_ex; exists (target / 2%:R).
Qed.

Definition mx_mono_lim : 'M[C]_n :=
  \matrix_(i, j) limn (fun k => (S k) i j).

Theorem mx_mono_cvgn : (S : nat -> 'M[C]_n) @ \oo --> mx_mono_lim.
Proof.
apply/mxcvgn_to_cvgn=> i j.
by rewrite mxE; exact: (@S_entry_cvgn i j).
Qed.

Lemma mx_mono_is_cvgn : cvgn (S : nat -> 'M[C]_n).
Proof. by apply/cvg_ex; exists mx_mono_lim; exact: mx_mono_cvgn. Qed.

(* qf-форма от предельной матрицы — предел qf-форм. *)
Lemma qf_lim (v : 'cV[C]_n) :
  ((fun k => \tr (v^t* *m S k *m v)) : nat -> C^o) @ \oo -->
   \tr (v^t* *m mx_mono_lim *m v).
Proof.
have Hcvg : ((fun k => v^t* *m S k *m v) : nat -> 'M[C]_1) @ \oo -->
            v^t* *m mx_mono_lim *m v.
  apply: cvgn_mulmx; last exact: cvg_cst.
  apply: cvgn_mulmx; first exact: cvg_cst.
  exact: mx_mono_cvgn.
exact: cvgn_mxtrace.
Qed.

(* Предел эрмитов: транспозиция-сопряжение сохраняется при пределе. *)
Lemma mx_mono_lim_herm : mx_mono_lim = mx_mono_lim^t*.
Proof.
have HSL : (S : nat -> 'M[C]_n) @ \oo --> mx_mono_lim := mx_mono_cvgn.
have HSLt : ((fun k => (S k)^t*) : nat -> 'M[C]_n) @ \oo --> mx_mono_lim^t*.
  exact: cvgn_trmxC HSL.
have HSLs : (fun k => (S k)^t*) = S.
  by apply/funext=> k; case: (S_psd k)=> H _; rewrite -H.
rewrite HSLs in HSLt.
have HausM : hausdorff_space ('M[C]_n : pseudoMetricNormedZmodType C).
  exact: norm_hausdorff.
have HSL_n : (S : nat -> ('M[C]_n : pseudoMetricNormedZmodType C)) @ \oo
             --> (mx_mono_lim : ('M[C]_n : pseudoMetricNormedZmodType C)).
  exact: HSL.
have HSLt_n : (S : nat -> ('M[C]_n : pseudoMetricNormedZmodType C)) @ \oo
              --> (mx_mono_lim^t* : ('M[C]_n : pseudoMetricNormedZmodType C)).
  exact: HSLt.
by apply: (cvg_unique HausM HSL_n HSLt_n).
Qed.

Lemma mx_mono_lim_psd : psd mx_mono_lim.
Proof.
split; first by rewrite -mx_mono_lim_herm.
move=> v.
apply: (cvgn_real_ge_C
        (u := fun k => \tr (v^t* *m S k *m v)) (m := 0)).
- by move=> k; apply: qf_psd_real; exact: S_psd.
- exact: real0.
- exact: qf_lim.
- by move=> k; apply: qf_psd_ge0; exact: S_psd.
Qed.

Lemma mx_mono_lim_le : psd_le mx_mono_lim B.
Proof.
rewrite /psd_le.
have HB_herm : B = B^t* by case: B_psd.
split; first by rewrite trmxCB -mx_mono_lim_herm -HB_herm.
move=> v.
rewrite mulmxBr mulmxBl linearB /= subr_ge0.
apply: (cvgn_real_le_C
        (u := fun k => \tr (v^t* *m S k *m v))).
- by move=> k; apply: qf_psd_real; exact: S_psd.
- by apply: qf_psd_real; exact: B_psd.
- exact: qf_lim.
- by move=> k; apply: qf_psd_le; exact: S_bnd.
Qed.

(* Любой член монотонной последовательности оценивается сверху пределом.
   Доказательство: фиксируем k0; сдвиг последовательности `j ↦ S (k0+j)`
   тоже сходится к `mx_mono_lim` (через `cvg_addnl` + `cvg_comp`), и каждый
   его член ≥ Smx k0 в порядке qf. Тогда qf(Smx k0, v) ≤ lim qf(.) по
   `cvgn_real_ge_C`. *)
Lemma mx_mono_lim_ge_term (k0 : nat) : psd_le (Smx k0) mx_mono_lim.
Proof.
rewrite /psd_le.
have HSk_herm : Smx k0 = (Smx k0)^t* by case: (S_psd k0).
split; first by rewrite trmxCB -mx_mono_lim_herm -HSk_herm.
move=> v.
rewrite mulmxBr mulmxBl linearB /= subr_ge0.
(* Сдвинутая последовательность матриц сходится к mx_mono_lim. *)
have Hshift_mx :
    ((fun j => Smx (k0 + j)%N) : nat -> 'M[C]_n) @ \oo --> mx_mono_lim.
  have HSL : (Smx : nat -> 'M[C]_n) @ \oo --> mx_mono_lim := mx_mono_cvgn.
  have Hsh : addn k0 @ \oo --> (\oo : set_system nat) := cvg_addnl k0.
  have Hcomp : (Smx \o addn k0) @ \oo --> mx_mono_lim
    := cvg_comp (addn k0) Smx Hsh HSL.
  have Heq : Smx \o (addn k0) = (fun j => Smx (k0 + j)%N)
    by apply/funext=> j.
  by rewrite -Heq.
(* Сходимость соответствующей сдвинутой qf-формы. *)
have Hshift_qf :
    (fun j => \tr (v^t* *m Smx (k0 + j)%N *m v))
      @ \oo --> \tr (v^t* *m mx_mono_lim *m v).
  have Hmul :
      ((fun j => v^t* *m Smx (k0 + j)%N *m v) : nat -> 'M[C]_1) @ \oo -->
        v^t* *m mx_mono_lim *m v.
    apply: cvgn_mulmx; last exact: cvg_cst.
    apply: cvgn_mulmx; first exact: cvg_cst.
    exact: Hshift_mx.
  exact: cvgn_mxtrace.
apply: (cvgn_real_ge_C
        (u := fun j => \tr (v^t* *m Smx (k0 + j)%N *m v))
        (m := \tr (v^t* *m Smx k0 *m v))).
- by move=> j; apply: qf_psd_real; exact: S_psd.
- by apply: qf_psd_real; exact: S_psd.
- exact: Hshift_qf.
- move=> j; apply: qf_psd_le.
  exact: S_mono_le (leq_addr j k0).
Qed.

End MxBridge.
