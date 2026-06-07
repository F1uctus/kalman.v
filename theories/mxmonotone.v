(*
  Монотонная сходимость последовательностей неотрицательно определённых матриц.

  Главный результат: если `S : nat -> 'M[ℂ]_n` монотонна по порядку Лёвнера
  ($S_k <= S_(k+1)$) и ограничена сверху матрицей $B$ ($S_k <= B$), то $S$
  сходится в матричной топологии к неотрицательно определённому пределу $L$,
  который удовлетворяет $L <= B$. Сходимость подразумевается в стандартной
  топологии комплексной плоскости.

  numClosedFieldType сам по себе не полон; секция параметризована мостом
  `r2c : ℝ -> ℂ`, `c2r : ℂ -> ℝ` (см. `extNumType` в CoqQ). Скалярная монотонная
  сходимость поднимается из ℝ (mathcomp-analysis), а элементы вне диагонали
  восстанавливаются через эрмитовы формы с тестовыми векторами
  $delta_i + delta_j$ и $delta_i + i delta_j$.
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import mxnotation mxherm mxhermform mxdefinite mxloewner mxfrob mxtopo.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* Поднятие монотонной сходимости на матрицы. *)
Section MxSeqMonotoneCvg.
  
  Variables (ℝ : realType) (ℂ : numClosedFieldType).
  Variable r2c : {rmorphism ℝ -> ℂ}.
  Variable c2r : ℂ -> ℝ.

  Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
  Hypothesis r2cK : cancel r2c c2r.
  Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
  Hypothesis c2r_continuous : continuous (c2r : ℂ -> ℝ).
  Hypothesis r2c_continuous : continuous (r2c : ℝ -> ℂ).

  (* Инъективность вложения вещественной прямой в комплексную плоскость. *)
  Lemma r2c_inj : injective r2c.
  Proof.
    exact: (can_inj r2cK).
  Qed.

  Lemma ler_c2r (x y : ℂ) :
    x \is Num.real -> y \is Num.real -> (c2r x <= c2r y) = (x <= y).
  Proof.
    by move=> Rx Ry; rewrite -[in RHS](c2rK Rx) -[in RHS](c2rK Ry) ler_r2c.
  Qed.

  Lemma r2c_real (x : ℝ) : r2c x \is Num.real.
  Proof.
    have [hx0|hx0] := lerP 0 x.
    - by rewrite ger0_real // -(rmorph0 r2c) ler_r2c.
    - by rewrite ler0_real // -(rmorph0 r2c) ler_r2c ltW.
  Qed.

  (*
    Поднятие теоремы о сходимости монотонно неубывающих последовательностей на
    подполе вещественных чисел в поле ℂ.
  *)
  Lemma nondecreasing_real_is_cvgn (u : nat -> ℂ) (Mu : ℂ) :
    (forall n, u n \is Num.real) -> Mu \is Num.real ->
    {homo u : i j / (i <= j)%N >-> i <= j} ->
    (forall n, u n <= Mu) ->
    cvgn u.
  Proof.
    move=> Hreal HMreal Hmono Hub.
    pose v : nat -> ℝ := c2r \o u.
    have Hv_mono : nondecreasing_seq v.
      by move=> i j leij; rewrite /v /= ler_c2r//; exact: Hmono.
    have Hv_ub : has_ubound (range v).
      exists (c2r Mu)=> _ /= [k _ <-].
      by rewrite /v /= ler_c2r//; exact: Hub.
    have Hv_cvg : cvgn v := nondecreasing_is_cvgn Hv_mono Hv_ub.
    have Hu_eq : u = r2c \o v :> (nat -> ℂ).
      by apply/funext=> k; rewrite /v /= c2rK.
    apply/cvg_ex; exists (r2c (limn v)).
    rewrite Hu_eq.
    apply: cvg_comp; first exact: Hv_cvg.
    exact: r2c_continuous.
  Qed.

  (*
    Замкнутость подполя вещественных чисел в ℂ относительно предельного
    перехода.
  *)
  Lemma cvgn_real_closed (u : nat -> ℂ) (l : ℂ) :
    (forall n, u n \is Num.real) ->
    u @ \oo --> l -> l \is Num.real.
  Proof.
    move=> Hreal Hcvg.
    have Hu_eq : u = r2c \o (c2r \o u) :> (nat -> ℂ).
      by apply/funext=> n; rewrite /= c2rK.
    have Hc2r : (c2r \o u) @ \oo --> c2r l.
      apply: cvg_comp; first exact: Hcvg.
      exact: c2r_continuous.
    have Hcvgr2c : (r2c \o (c2r \o u)) @ \oo --> r2c (c2r l).
      apply: cvg_comp; first exact: Hc2r.
      exact: r2c_continuous.
    have HausC : hausdorff_space (ℂ^o : pseudoMetricNormedZmodType _).
      exact: norm_hausdorff.
    have Hcvgr2c_o : (r2c \o (c2r \o u) : nat -> ℂ^o) @ \oo --> (r2c (c2r l) : ℂ^o).
      exact: Hcvgr2c.
    have Hcvg_o : (r2c \o (c2r \o u) : nat -> ℂ^o) @ \oo --> (l : ℂ^o).
      by rewrite -Hu_eq; exact: Hcvg.
    have hEq : (l : ℂ^o) = (r2c (c2r l) : ℂ^o).
      exact: cvg_unique Hcvg_o Hcvgr2c_o.
    by rewrite (hEq : l = _); exact: r2c_real.
  Qed.

  (* Переход к пределу в неравенствах для вещественных посл-тей в ℂ. *)

  (* Ограниченность предела вещественной посл-ти сверху. *)
  Lemma cvgn_real_le_C (u : nat -> ℂ) (Mu l : ℂ) :
    (forall n, u n \is Num.real) -> Mu \is Num.real ->
    u @ \oo --> l ->
    (forall n, u n <= Mu) ->
    l <= Mu.
  Proof.
    move=> Hreal HMreal Hcvg Hub.
    have Hlreal := cvgn_real_closed Hreal Hcvg.
    pose v : nat -> ℝ := c2r \o u.
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
    Unshelve.
    all: by end_near.
  Qed.

  (* Ограниченность предела вещественной посл-ти снизу. *)
  Lemma cvgn_real_ge_C (u : nat -> ℂ) (m l : ℂ) :
    (forall n, u n \is Num.real) -> m \is Num.real ->
    u @ \oo --> l ->
    (forall n, m <= u n) ->
    m <= l.
  Proof.
    move=> Hreal Hmreal Hcvg Hlb.
    have Hcvg_o : (u : nat -> ℂ^o) @ \oo --> (l : ℂ^o) by exact: Hcvg.
    have Hcvg' : ((fun k => - u k) : nat -> ℂ^o) @ \oo --> (- l : ℂ^o).
      exact: cvgN Hcvg_o.
    have Hcvg'' : (fun k => - u k) @ \oo --> - l by exact: Hcvg'.
    have HnegReal : forall n, - u n \is Num.real by move=> n; rewrite rpredN.
    have HmReal : - m \is Num.real by rewrite rpredN.
    have Hub : forall n, - u n <= - m by move=> n; rewrite lerN2.
    have := cvgn_real_le_C HnegReal HmReal Hcvg'' Hub.
    by rewrite lerN2.
  Qed.

  (*
    Сходимость монотонно возрастающей посл-ти неотрицательно определённых
    матриц.
  *)

  Variable n : nat.

  Variable S : nat -> 'M[ℂ]_n.
  Variable B : 'M[ℂ]_n.

  Hypothesis S_psd : forall k, psd (S k).
  Hypothesis S_mono : forall k, psd_le (S k) (S k.+1).
  Hypothesis S_bnd : forall k, psd_le (S k) B.

  Lemma B_psd :
    psd B.
  Proof.
    apply/psd_le0_psd; apply: (psd_le_trans (B := S 0%N)).
    - by rewrite psd_le0_psd; exact: S_psd.
    - exact: S_bnd.
  Qed.

  (*
    Сохранение свойства монотонности относительно порядка Лёвнера для элементов
    посл-ти с произвольными индексами.
  *)
  Lemma S_mono_le (i j : nat) :
    (i <= j)%N -> psd_le (S i) (S j).
  Proof.
    elim: j i => [|j IHj] i; first by rewrite leqn0=> /eqP->; apply: psd_le_refl; exact: S_psd.
    rewrite leq_eqVlt=> /orP[/eqP->|]; first by apply: psd_le_refl; exact: S_psd.
    by rewrite ltnS=> Hij; apply: (psd_le_trans (IHj _ Hij)); exact: S_mono.
  Qed.

  (* Поточечная сходимость посл-ти матриц на квадратичных формах. *)
  Lemma qf_seq_cvgn (v : 'cV[ℂ]_n) :
    cvgn (fun k => \tr (v^t* *m S k *m v)).
  Proof.
    apply: (nondecreasing_real_is_cvgn (Mu := \tr (v^t* *m B *m v))).
    - by move=> k; apply: qf_psd_real; exact: S_psd.
    - by apply: qf_psd_real; exact: B_psd.
    - by move=> i j leij; apply: qf_psd_le; exact: S_mono_le.
    - by move=> k; apply: qf_psd_le; exact: S_bnd.
  Qed.

  (* Покомпонентная сходимость диагональных элементов посл-ти матриц. *)
  Lemma S_diag_cvgn (i : 'I_n) :
    cvgn (fun k => (S k) i i).
  Proof.
    suff : cvgn (fun k => \tr ((delta_mx i ord0 : 'cV[ℂ]_n)^t* *m S k *m delta_mx i ord0)).
      by under eq_is_cvg=> k do rewrite qf_delta.
    exact: qf_seq_cvgn.
  Qed.

  (* Покомпонентная сходимость матричной посл-ти. *)
  Lemma S_entry_cvgn (i j : 'I_n) :
    cvgn (fun k => (S k) i j).
  Proof.
    have HDi : (fun k => (S k) i i) @ \oo --> limn (fun k => (S k) i i).
      exact: (@S_diag_cvgn i).
    have HDj : (fun k => (S k) j j) @ \oo --> limn (fun k => (S k) j j).
      exact: (@S_diag_cvgn j).
    pose vp : 'cV[ℂ]_n := delta_mx i ord0 + delta_mx j ord0.
    pose vi : 'cV[ℂ]_n := delta_mx i ord0 + 'i *: delta_mx j ord0.
    have HQ1 : (fun k => \tr (vp^t* *m S k *m vp)) @ \oo -->
              limn (fun k => \tr (vp^t* *m S k *m vp)).
      exact: (@qf_seq_cvgn vp).
    have HQ2 : (fun k => \tr (vi^t* *m S k *m vi)) @ \oo -->
              limn (fun k => \tr (vi^t* *m S k *m vi)).
      exact: (@qf_seq_cvgn vi).
    (*
      В каждом k: 2 * S k i j = (qf1 - S k i i - S k j j) - 'i *
      (qf2 - S k i i - S k j j)
    *)
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
    (* Сходимость (2 * S k i j) через cvgC_D/cvgC_M в ℂ *)
    pose target : ℂ := (limn (fun k => \tr (vp^t* *m S k *m vp))
                        - limn (fun k => (S k) i i)
                        - limn (fun k => (S k) j j))
                      - 'i * (limn (fun k => \tr (vi^t* *m S k *m vi))
                              - limn (fun k => (S k) i i)
                              - limn (fun k => (S k) j j)).
    have HBR1 := cvgC_B (cvgC_B HQ1 HDi) HDj.
    have HBR2 := cvgC_B (cvgC_B HQ2 HDi) HDj.
    have FF : Filter (\oo : set_system nat) by typeclasses eauto.
    have Hi_const : (fun _ : nat => ('i : ℂ)) @ \oo --> ('i : ℂ).
      exact: cvg_cst.
    have HiBR2 := cvgC_M Hi_const HBR2.
    have Htwosij : (fun k => 2%:R * (S k) i j) @ \oo --> target.
      have := cvgC_B HBR1 HiBR2.
      by under eq_cvg=> k do rewrite -(Hentry_eq k).
    (* Делим на 2: (S k) i j = (2 * (S k) i j) / 2. *)
    have H2neq : (2%:R : ℂ) != 0 by rewrite pnatr_eq0.
    have Hsij : (fun k => (S k) i j) @ \oo --> target / 2%:R.
      have Hinv : (fun _ : nat => (2%:R : ℂ)^-1) @ \oo --> (2%:R : ℂ)^-1.
        exact: cvg_cst.
      have := cvgC_M Htwosij Hinv.
      by under eq_cvg=> k do rewrite mulrAC mulfV // mul1r.
    by apply/cvg_ex; exists (target / 2%:R).
  Qed.

  (* Покомпонентный предел монотонной посл-ти матриц S_k. *)
  Definition mx_mono_lim : 'M[ℂ]_n :=
    \matrix_(i, j) limn (fun k => (S k) i j).

  (*
    Покомпонентный предел монотонной посл-ти матриц существует, и посл-ть
    сходится к нему.
  *)
  Theorem mx_mono_cvgn :
    (S : nat -> 'M[ℂ]_n) @ \oo --> mx_mono_lim.
  Proof.
    apply/mxcvgn_to_cvgn=> i j.
    by rewrite mxE; exact: (@S_entry_cvgn i j).
  Qed.

  (* Монотонная ограниченная посл-ть эрмитовых матриц покомпонентно сходится. *)
  Lemma mx_mono_is_cvgn :
    cvgn (S : nat -> 'M[ℂ]_n).
  Proof.
    by apply/cvg_ex; exists mx_mono_lim; exact: mx_mono_cvgn.
  Qed.

  (* Эрмитова форма от предельной матрицы есть предел посл-ти эрмитовых форм. *)
  Lemma qf_lim (v : 'cV[ℂ]_n) :
    ((fun k => \tr (v^t* *m S k *m v)) : nat -> ℂ^o) @ \oo -->
    \tr (v^t* *m mx_mono_lim *m v).
  Proof.
    have Hcvg : ((fun k => v^t* *m S k *m v) : nat -> 'M[ℂ]_1) @ \oo -->
                v^t* *m mx_mono_lim *m v.
      apply: cvgn_mulmx; last exact: cvg_cst.
      apply: cvgn_mulmx; first exact: cvg_cst.
      exact: mx_mono_cvgn.
    exact: cvgn_mxtrace.
  Qed.

  (* Предел монотонной посл-ти эрмитовых матриц эрмитов. *)
  Lemma mx_mono_lim_herm :
    mx_mono_lim = mx_mono_lim^t*.
  Proof.
    have HSL : (S : nat -> 'M[ℂ]_n) @ \oo --> mx_mono_lim := mx_mono_cvgn.
    have HSLt : ((fun k => (S k)^t*) : nat -> 'M[ℂ]_n) @ \oo --> mx_mono_lim^t*.
      exact: cvgn_trmxC HSL.
    have HSLs : (fun k => (S k)^t*) = S.
      by apply/funext=> k; case: (S_psd k)=> H _; rewrite -H.
    rewrite HSLs in HSLt.
    have HausM : hausdorff_space ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ).
      exact: norm_hausdorff.
    have HSL_n : (S : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)) @ \oo
                --> (mx_mono_lim : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)).
      exact: HSL.
    have HSLt_n : (S : nat -> ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)) @ \oo
                  --> (mx_mono_lim^t* : ('M[ℂ]_n : pseudoMetricNormedZmodType ℂ)).
      exact: HSLt.
    by apply: (cvg_unique HausM HSL_n HSLt_n).
  Qed.

  (* Предел монотонной посл-ти эрмитовых матриц неотрицательно определён. *)
  Lemma mx_mono_lim_psd :
    psd mx_mono_lim.
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

  (* Матрица `B` мажорирует предел матричной последовательности. *)
  Lemma mx_mono_lim_le :
    psd_le mx_mono_lim B.
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

  (*
    Предел монотонно возрастающей последовательности является её супремумом.
    Доказательство: для фиксированного $k_0$ сдвиг $j |-> S_(k_0 + j)$ сходится
    к той же матрице `mx_mono_lim`. Так как последовательность монотонна, все её
    члены мажорируют S k0 относительно порядка Лёвнера. Утверждение следует из
    сохранения нестрогого неравенства при предельном переходе для эрмитовых форм
    (`cvgn_real_ge_C`).
  *)
  Lemma mx_mono_lim_ge_term (k0 : nat) :
    psd_le (S k0) mx_mono_lim.
  Proof.
    rewrite /psd_le.
    have HSk_herm : S k0 = (S k0)^t* by case: (S_psd k0).
    split; first by rewrite trmxCB -mx_mono_lim_herm -HSk_herm.
    move=> v.
    rewrite mulmxBr mulmxBl linearB /= subr_ge0.
    (* Сдвинутая последовательность матриц сходится к `mx_mono_lim`. *)
    have Hshift_mx :
        ((fun j => S (k0 + j)%N) : nat -> 'M[ℂ]_n) @ \oo --> mx_mono_lim.
      have HSL : (S : nat -> 'M[ℂ]_n) @ \oo --> mx_mono_lim := mx_mono_cvgn.
      have Hsh : addn k0 @ \oo --> (\oo : set_system nat) := cvg_addnl k0.
      have Hcomp : (S \o addn k0) @ \oo --> mx_mono_lim
        := cvg_comp (addn k0) S Hsh HSL.
      have Heq : S \o (addn k0) = (fun j => S (k0 + j)%N)
        by apply/funext=> j.
      by rewrite -Heq.
    (* Сходимость соответствующей сдвинутой эрмитовой формы. *)
    have Hshift_qf :
        (fun j => \tr (v^t* *m S (k0 + j)%N *m v))
          @ \oo --> \tr (v^t* *m mx_mono_lim *m v).
      have Hmul :
          ((fun j => v^t* *m S (k0 + j)%N *m v) : nat -> 'M[ℂ]_1) @ \oo -->
            v^t* *m mx_mono_lim *m v.
        apply: cvgn_mulmx; last exact: cvg_cst.
        apply: cvgn_mulmx; first exact: cvg_cst.
        exact: Hshift_mx.
      exact: cvgn_mxtrace.
    apply: (cvgn_real_ge_C
            (u := fun j => \tr (v^t* *m S (k0 + j)%N *m v))
            (m := \tr (v^t* *m S k0 *m v))).
    - by move=> j; apply: qf_psd_real; exact: S_psd.
    - by apply: qf_psd_real; exact: S_psd.
    - exact: Hshift_qf.
    - move=> j; apply: qf_psd_le.
      exact: S_mono_le (leq_addr j k0).
  Qed.

End MxSeqMonotoneCvg.

(*
  Монотонно убывающая сходимость неотрицательно определённых матриц.

  Двойственно к `MxSeqMonotoneCvg`: для убывающей посл-ти $S_(k+1) <= S_k$
  доказываем сходимость через подстановку $T_k := S_0 - S_k$
  (возрастающая, ограниченная сверху `S 0`). Затем переносим результаты обратно
  на `S`.
*)
Section MxSeqMonotoneCvgDec.

  Variables (ℝ : realType) (ℂ : numClosedFieldType).
  Variable r2c : {rmorphism ℝ -> ℂ}.
  Variable c2r : ℂ -> ℝ.
  
  Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
  Hypothesis r2cK : cancel r2c c2r.
  Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
  Hypothesis c2r_continuous : continuous (c2r : ℂ -> ℝ).
  Hypothesis r2c_continuous : continuous (r2c : ℝ -> ℂ).

  Variable n : nat.

  Variable S : nat -> 'M[ℂ]_n.

  Hypothesis S_psd : forall k, psd (S k).
  Hypothesis S_anti : forall k, psd_le (S k.+1) (S k).

  (* Последовательность матриц монотонно не возрастает. *)
  Lemma S_anti_le (i j : nat) :
    (i <= j)%N -> psd_le (S j) (S i).
  Proof.
    elim: j i => [|j IHj] i; first by rewrite leqn0=> /eqP->; apply: psd_le_refl; exact: S_psd.
    rewrite leq_eqVlt=> /orP[/eqP->|].
      by apply: psd_le_refl; exact: S_psd.
    by rewrite ltnS=> Hij; apply: (psd_le_trans (S_anti j)); exact: IHj.
  Qed.

  (*
    `S 0` мажорирует невозрастающую посл-ть неотрицательно определённых матриц.
  *)
  Lemma S_le_S0 (k : nat) :
    psd_le (S k) (S 0%N).
  Proof.
    exact: S_anti_le (leq0n k).
  Qed.

  (* Подстановка делает посл-ть возрастающей и ограниченной сверху S 0. *)
  Definition T (k : nat) : 'M[ℂ]_n :=
    S 0%N - S k.

  Lemma T_psd (k : nat) :
    psd (T k).
  Proof.
    exact: S_le_S0.
  Qed.

  Lemma T_mono (k : nat) :
    psd_le (T k) (T k.+1).
  Proof.
    rewrite /psd_le /T.
    have ->: S 0%N - S k.+1 - (S 0%N - S k) = S k - S k.+1.
      rewrite opprB [S k - S 0%N]addrC addrACA addrN add0r addrC.
      by [].
    exact: S_anti.
  Qed.

  Lemma T_bnd (k : nat) :
    psd_le (T k) (S 0%N).
  Proof.
    rewrite /psd_le /T.
    have ->: S 0%N - (S 0%N - S k) = S k.
      by rewrite opprB [S k - S 0%N]addrC addrA addrN add0r.
    exact: S_psd.
  Qed.

  (* Применяем существующую mx_mono_cvgn к T. *)
  Definition mx_mono_dec_lim : 'M[ℂ]_n :=
    S 0%N - mx_mono_lim T.

  Theorem mx_mono_dec_cvgn :
    (S : nat -> 'M[ℂ]_n) @ \oo --> mx_mono_dec_lim.
  Proof.
    have HT : (T : nat -> 'M[ℂ]_n) @ \oo --> mx_mono_lim T.
      exact: (@mx_mono_cvgn ℝ ℂ r2c c2r
                ler_r2c c2rK r2c_continuous
                n T (S 0%N) T_psd T_mono T_bnd).
    (* S k = S 0 - T k *)
    have eq_S : S = (fun k => S 0%N - T k).
      apply/funext=> k.
      rewrite /T.
      by rewrite opprB [S k - S 0%N]addrC addrA addrN add0r.
    rewrite eq_S.
    have Hcst : ((fun _ : nat => S 0%N) : nat -> 'M[ℂ]_n) @ \oo --> S 0%N
      by exact: cvg_cst.
    rewrite /mx_mono_dec_lim.
    exact: cvgn_submx Hcst HT.
  Qed.

  Lemma mx_mono_dec_is_cvgn :
    cvgn (S : nat -> 'M[ℂ]_n).
  Proof.
    by apply/cvg_ex; exists mx_mono_dec_lim; exact: mx_mono_dec_cvgn.
  Qed.

  Lemma mx_mono_dec_lim_psd :
    psd mx_mono_dec_lim.
  (*
    $"mx_mono_dec_lim" = S_0 - "mx_mono_lim" T$. Поскольку $lim T <= S_0$
    (через `mx_mono_lim_le`), $"psd"(S_0 - lim T)$.
  *)
  Proof.
    rewrite /mx_mono_dec_lim.
    have HT_le : psd_le (mx_mono_lim T) (S 0%N).
      exact: (@mx_mono_lim_le ℝ ℂ r2c c2r
                ler_r2c c2rK c2r_continuous r2c_continuous
                n T (S 0%N) T_psd T_mono T_bnd).
    exact: HT_le.
  Qed.

  (* Любой член убывающей последовательности >= её предела. *)
  Lemma mx_mono_dec_lim_le_term (k0 : nat) :
    psd_le mx_mono_dec_lim (S k0).
  Proof.
    (* Через возрастание T: T k0 <= lim T. *)
    have HT_term : psd_le (T k0) (mx_mono_lim T).
      exact: (@mx_mono_lim_ge_term ℝ ℂ r2c c2r
                ler_r2c c2rK c2r_continuous r2c_continuous
                n T (S 0%N) T_psd T_mono T_bnd k0).
    (*
      Перепишем: $"lim_dec" = S_0 - lim T, S_(k_0) = S_0 - T_(k_0)$. Тогда
      $S_(k_0) - "lim_dec" = lim T - T_(k_0) >= 0$ (`HT_term`).
    *)
    rewrite /psd_le /mx_mono_dec_lim /T.
    have ->: S k0 - (S 0%N - mx_mono_lim T)
          = mx_mono_lim T - (S 0%N - S k0).
      by rewrite !opprB addrCA.
    exact: HT_term.
  Qed.

  (* Убывающая посл-ть эрмитовых матриц имеет предел, и он эрмитов. *)
  Lemma mx_mono_dec_lim_herm :
    mx_mono_dec_lim = mx_mono_dec_lim^t*.
  Proof.
    have HT_herm : mx_mono_lim T = (mx_mono_lim T)^t*.
      exact: (@mx_mono_lim_herm ℝ ℂ r2c c2r
                ler_r2c c2rK r2c_continuous
                n T (S 0%N) T_psd T_mono T_bnd).
    have S0_herm : S 0%N = (S 0%N)^t* by case: (S_psd 0%N).
    rewrite /mx_mono_dec_lim.
    by rewrite trmxCB -HT_herm -S0_herm.
  Qed.

End MxSeqMonotoneCvgDec.
