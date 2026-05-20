(*  Топология на матрицах + сходимость по элементам.                    *)
(*                                                                       *)
(*  В этом файле:                                                        *)
(*    - определяем сходимость последовательности матриц через            *)
(*      сходимость по каждому элементу;                                  *)
(*    - доказываем эквивалентность с матричной топологией из             *)
(*      mathcomp-analysis (matrix_normedZmodType);                       *)
(*    - устанавливаем непрерывность сложения, умножения, сопряжённого    *)
(*      транспонирования и следа.                                        *)
(*                                                                       *)
(*  Фробениусова норма (mxfrob.v) используется как мост между            *)
(*  скалярной и матричной топологией: frob_sq (M_k - L) → 0  ⇒          *)
(*  M_k → L.  Это пригодится для монотонной сходимости PSD-              *)
(*  последовательностей (Session 3).                                     *)

Set Warnings "-notation-overridden,-coercions,-default".

From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype.
From Kalman Require Import psd_base mxfrob.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.
Import numFieldTopology.Exports.

Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* ================================================================== *)
(*  Поэлементная сходимость и её эквивалентность с матричной          *)
(*  топологией.                                                       *)
(* ================================================================== *)

Section Entrywise.
Variable (C : numClosedFieldType) (m n : nat).
Implicit Types (M : nat -> 'M[C]_(m, n)) (L : 'M[C]_(m, n)).

(* Поэлементная сходимость: каждый элемент сходится в C. *)
Definition mxcvgn M L : Prop :=
  forall i j, (fun k => M k i j) @ \oo --> L i j.

(* Из сходимости матричной последовательности следует сходимость
   каждого элемента (непрерывность проекции). *)
Lemma cvgn_to_mxcvgn M L : M @ \oo --> L -> mxcvgn M L.
Proof.
move=> HM i j.
have Hcont : {for L, continuous (fun N : 'M[C]_(m, n) => N i j)}.
  exact: coord_continuous.
exact: (continuous_cvg _ Hcont HM).
Qed.

(* Обратное: поэлементная сходимость даёт матричную (через окружения). *)
Lemma mxcvgn_to_cvgn M L : mxcvgn M L -> M @ \oo --> L.
Proof.
move=> HE; apply/cvg_mx_entourageP=> A entA.
have HE' : forall ij : 'I_m * 'I_n,
    \forall k \near \oo, A (L ij.1 ij.2, M k ij.1 ij.2).
  by move=> [i j]; move/cvg_app_entourageP: (HE i j) => /(_ A entA).
have hF : Filter (\oo : set_system nat) by typeclasses eauto.
have := @filter_forall _ _ _ _ hF HE'.
apply: filterS=> k Hk i j; rewrite in_setE.
exact: (Hk (i, j)).
Qed.

Lemma mxcvgnP M L : mxcvgn M L <-> M @ \oo --> L.
Proof. by split; [exact: mxcvgn_to_cvgn | exact: cvgn_to_mxcvgn]. Qed.

End Entrywise.

(* ================================================================== *)
(*  Мост к Фробениусовой норме.                                        *)
(* ================================================================== *)

Section FrobeniusBridge.
Variable (C : numClosedFieldType) (r c : nat).
Implicit Types (M N : 'M[C]_(r, c)).

(* Для каждого элемента: |M_{ij}|^2 ≤ frob_sq M. *)
Lemma frob_sq_entry_ge M (i : 'I_r) (j : 'I_c) :
  `|M i j| ^+ 2 <= frob_sq M.
Proof.
rewrite frob_sqE.
have hge0 : forall (i' : 'I_r) (j' : 'I_c), 0 <= (M i' j')^* * M i' j'.
  by move=> i' j'; rewrite mulrC; exact: mul_conjC_ge0.
have step_inner : (M i j)^* * M i j <= \sum_i (M i j)^* * M i j.
  rewrite (bigD1 i)//= lerDl; apply: sumr_ge0=> i' _; exact: hge0.
have step_outer : \sum_i (M i j)^* * M i j
                  <= \sum_j \sum_i (M i j)^* * M i j.
  rewrite (bigD1 j)//= lerDl; apply: sumr_ge0=> j' _.
  by apply: sumr_ge0=> i' _; exact: hge0.
apply: (le_trans _ (le_trans step_inner step_outer)).
by rewrite normCK mulrC.
Qed.

End FrobeniusBridge.

(* ================================================================== *)
(*  Обратное направление: frob_sq (Pf k - L) → 0  ⇒  Pf @ \oo --> L.    *)
(*                                                                     *)
(*  Достаточно показать поэлементную сходимость P_k i j → L i j        *)
(*  (через `mxcvgn_to_cvgn`).  Из `|M i j|^+2 ≤ frob_sq M`              *)
(*  (`frob_sq_entry_ge` выше) и `frob_sq → 0` (вместе с                  *)
(*  `0 ≤ |Pf k i j - L i j|^+2 ≤ frob_sq (Pf k - L)`)                   *)
(*  получаем `|Pf k i j - L i j|^+2 → 0`, откуда `|·| → 0` и           *)
(*  `(Pf k - L) i j → 0` поэлементно — что и даёт `Pf k i j → L i j`.   *)
Section FrobToMxCvg.
Variable (C : numClosedFieldType) (r c : nat).
Implicit Types (Pf : nat -> 'M[C]_(r, c)) (L : 'M[C]_(r, c)).

(* Технический шаг: для C-значной последовательности s ≥ 0, если       *)
(* s ≤ t и t → 0 в C^o, то s → 0 в C^o.                                 *)
Lemma cvgC_le0_squeeze (s t : nat -> C) :
  (forall k, 0 <= s k) -> (forall k, s k <= t k) ->
  t @ \oo --> (0 : C) -> s @ \oo --> (0 : C).
Proof.
move=> s_ge0 s_le_t Hcvgt.
have Ht_o : (t : nat -> C^o) @ \oo --> (0 : C^o) by exact: Hcvgt.
have Hs_o : (s : nat -> C^o) @ \oo --> (0 : C^o).
  apply/cvgrPdistC_lt=> eps eps_pos.
  have /cvgrPdistC_lt /(_ eps eps_pos) Ht_pdist := Ht_o.
  near=> k.
  have Hk : `|t k - 0| < eps by near: k; exact: Ht_pdist.
  rewrite subr0 in Hk.
  rewrite /= subr0.
  have abs_t : `|t k| = t k.
    apply: ger0_norm.
    exact: (le_trans (s_ge0 k) (s_le_t k)).
  have abs_s : `|s k| = s k by exact: ger0_norm (s_ge0 k).
  rewrite abs_s.
  rewrite abs_t in Hk.
  exact: le_lt_trans (s_le_t k) Hk.
exact: Hs_o.
Unshelve. all: by end_near.
Qed.

(* Поэлементная сходимость `(Pf k - L) i j → 0` из `frob_sq → 0`. *)
Lemma frob_sq_to_entry_cvg0 Pf L (i : 'I_r) (j : 'I_c) :
  (fun k => frob_sq (Pf k - L)) @ \oo --> (0 : C) ->
  (fun k => (Pf k - L) i j) @ \oo --> (0 : C).
Proof.
move=> Hfrob.
(* Шаг 1: `|·|^+2 ≤ frob_sq`, и frob_sq → 0 ⇒ `|·|^+2 → 0`. *)
have Habs_sq_cvg :
    (fun k => `|(Pf k - L) i j| ^+ 2) @ \oo --> (0 : C).
  apply: (cvgC_le0_squeeze (t := fun k => frob_sq (Pf k - L))).
  - by move=> k; rewrite exprn_ge0 // normr_ge0.
  - by move=> k; exact: frob_sq_entry_ge.
  - exact: Hfrob.
(* Шаг 2: `|·|^+2 → 0` ⇒ `|·| → 0`.  Доказательство: для любого ε > 0  *)
(* достаточно подойти к `|·|^+2 < ε^+2`.                                *)
have Habs_sq_o :
    ((fun k => `|(Pf k - L) i j| ^+ 2) : nat -> C^o) @ \oo --> (0 : C^o)
  := Habs_sq_cvg.
have Habs_o :
    ((fun k => `|(Pf k - L) i j|) : nat -> C^o) @ \oo --> (0 : C^o).
  apply/cvgrPdistC_lt=> eps eps_pos.
  have eps_sq_pos : 0 < eps ^+ 2 by rewrite exprn_gt0.
  have /cvgrPdistC_lt /(_ (eps ^+ 2) eps_sq_pos) Hsq_near := Habs_sq_o.
  near=> k.
  have Hsq_k : (`| (`|(Pf k - L) i j| ^+ 2) - 0| < eps ^+ 2).
    by near: k; exact: Hsq_near.
  rewrite /= subr0 in Hsq_k.
  have abs_sq_ge0 : 0 <= `|(Pf k - L) i j| ^+ 2 by rewrite exprn_ge0 // normr_ge0.
  rewrite (ger0_norm abs_sq_ge0) in Hsq_k.
  rewrite /= subr0.
  rewrite ger0_norm; last exact: normr_ge0.
  have nneg : 0 <= `|(Pf k - L) i j| by exact: normr_ge0.
  have eps_ge0 : 0 <= eps by exact: ltW eps_pos.
  (* `|·|^+2 < eps^+2`  and  0 ≤ |·|, 0 ≤ eps  ⇒  `|·| < eps`.        *)
  (* Через mono-форму `ltr_pXn2r`: (x^+2 < y^+2) = (x < y) на Num.nneg. *)
  have abs_in : `|(Pf k - L) i j| \is Num.nneg by rewrite nnegrE.
  have eps_in : eps \is Num.nneg by rewrite nnegrE.
  by rewrite -(ltr_pXn2r (n:=2) _ abs_in eps_in).
have Habs_cvg : (fun k => `|(Pf k - L) i j|) @ \oo --> (0 : C)
  by exact: Habs_o.
(* Шаг 3: `|·| → 0` ⇒ `· → 0`. *)
have Hentry_o :
    ((fun k => (Pf k - L) i j) : nat -> C^o) @ \oo --> (0 : C^o).
  apply/cvgrPdistC_lt=> eps eps_pos.
  have /cvgrPdistC_lt /(_ eps eps_pos) Habs_near := Habs_o.
  near=> k.
  have Habs_k : (`| `|(Pf k - L) i j| - 0| < eps) by near: k; exact: Habs_near.
  rewrite /= subr0 in Habs_k.
  rewrite (ger0_norm (@normr_ge0 _ _ _)) in Habs_k.
  by rewrite /= subr0.
exact: Hentry_o.
Unshelve. all: by end_near.
Qed.

Lemma frob_sq_cvgn0_to_mxcvgn Pf L :
  (fun k => frob_sq (Pf k - L)) @ \oo --> (0 : C) ->
  (Pf : nat -> 'M[C]_(r, c)) @ \oo --> L.
Proof.
move=> Hfrob.
apply/mxcvgn_to_cvgn=> i j.
have Hdiff : (fun k => (Pf k - L) i j) @ \oo --> (0 : C)
  := frob_sq_to_entry_cvg0 i j Hfrob.
(* `Pf k i j = (Pf k - L) i j + L i j` — добавляем константу `L i j`. *)
have Heq_decomp : (fun k => Pf k i j) = (fun k => (Pf k - L) i j + L i j).
  apply/funext=> k.
  by rewrite !mxE subrK.
rewrite Heq_decomp.
have Hdiff_o : ((fun k => (Pf k - L) i j) : nat -> C^o) @ \oo --> (0 : C^o)
  by exact: Hdiff.
have Hcst_o : ((fun _ : nat => L i j) : nat -> C^o) @ \oo --> (L i j : C^o)
  by exact: cvg_cst.
have HSum_o : ((fun k => (Pf k - L) i j + L i j) : nat -> C^o) @ \oo -->
              (0 + L i j : C^o)
  := cvgD Hdiff_o Hcst_o.
have HSum : (fun k => (Pf k - L) i j + L i j) @ \oo --> (0 + L i j : C)
  by exact: HSum_o.
by rewrite add0r in HSum.
Qed.

End FrobToMxCvg.

(* ================================================================== *)
(*  Вспомогательный факт: изометрия непрерывна.                        *)
(*                                                                     *)
(*  Доказывается в абстрактном контексте — иначе тайп-классы           *)
(*  автоматически не находят фильтр `nbhs x` для конкретного           *)
(*  `C^o` (это известная боль при работе с `regular_topology`).        *)
(* ================================================================== *)

Section IsometryContinuous.
Context {K : numFieldType} {V : pseudoMetricNormedZmodType K}.

Lemma isometry_continuous_ (f : V -> V) :
    (forall x y : V, `|f x - f y| = `|x - y|) -> continuous f.
Proof.
move=> Hball x; apply/cvgrPdist_lt=> e e0; near do rewrite Hball.
exact: cvgr_dist_lt.
Unshelve. all: by end_near. Qed.

End IsometryContinuous.

(* ================================================================== *)
(*  Непрерывность матричных операций.                                  *)
(*                                                                     *)
(*  Сложение и вычитание берём напрямую через                          *)
(*  `pseudoMetricNormedZmodType`-инстанс для `'M[C]_(r, c)`.            *)
(*                                                                     *)
(*  Для произведения, следа и сопряжённого транспонирования сводимся   *)
(*  к поэлементной сходимости (через `mxcvgnP`).  На скалярном уровне  *)
(*  arithmетика над `C : numClosedFieldType` требует обёртки `^o`,      *)
(*  чтобы получить структуру `pseudoMetricNormedZmodType`.              *)
(* ================================================================== *)

Section Continuity.
Variable (C : numClosedFieldType).

(* Помощник: сходимость суммы скалярных последовательностей.        *)
(*                                                                  *)
(* C : numClosedFieldType не является автоматически                 *)
(* `pseudoMetricNormedZmodType` (это структура есть только у обёртки *)
(* C^o), поэтому идём через явное приведение к C^o.                 *)
Lemma cvgC_D (f g : nat -> C) (a b : C) :
  f @ \oo --> a -> g @ \oo --> b -> (fun k => f k + g k) @ \oo --> a + b.
Proof.
move=> Hf Hg t Ht /=.
have Hf' : (f : nat -> C^o) @ \oo --> (a : C^o) by exact: Hf.
have Hg' : (g : nat -> C^o) @ \oo --> (b : C^o) by exact: Hg.
exact: (cvgD Hf' Hg' Ht).
Qed.

(* Сходимость скалярного произведения. *)
Lemma cvgC_M (f g : nat -> C) (a b : C) :
  f @ \oo --> a -> g @ \oo --> b -> (fun k => f k * g k) @ \oo --> a * b.
Proof.
move=> Hf Hg t Ht /=.
have Hf' : (f : nat -> C^o) @ \oo --> (a : C^o) by exact: Hf.
have Hg' : (g : nat -> C^o) @ \oo --> (b : C^o) by exact: Hg.
exact: (cvgM Hf' Hg' Ht).
Qed.

(* Конечная сумма сходящихся скалярных последовательностей. *)
Lemma cvgC_sum (I : Type) (P : pred I) (r : seq I)
    (F : I -> nat -> C) (a : I -> C) :
  (forall i, P i -> F i @ \oo --> a i) ->
  (fun k => \sum_(i <- r | P i) F i k) @ \oo -->
    \sum_(i <- r | P i) a i.
Proof.
move=> HF; elim: r => [|i r IHr].
  rewrite big_nil; under eq_cvg do rewrite big_nil; exact: cvg_cst.
rewrite big_cons; under eq_cvg do rewrite big_cons; case: ifPn => Pi //.
exact: cvgC_D (HF _ Pi) IHr.
Qed.

(* Сложение матриц. *)
Lemma cvgn_addmx r c (M N : nat -> 'M[C]_(r, c)) (L L' : 'M[C]_(r, c)) :
  M @ \oo --> L -> N @ \oo --> L' ->
  (fun k => M k + N k) @ \oo --> L + L'.
Proof. by move=> HM HN; exact: cvgD. Qed.

Lemma cvgn_oppmx r c (M : nat -> 'M[C]_(r, c)) (L : 'M[C]_(r, c)) :
  M @ \oo --> L -> (fun k => - M k) @ \oo --> - L.
Proof. by move=> HM; exact: cvgN. Qed.

Lemma cvgn_submx r c (M N : nat -> 'M[C]_(r, c)) (L L' : 'M[C]_(r, c)) :
  M @ \oo --> L -> N @ \oo --> L' ->
  (fun k => M k - N k) @ \oo --> L - L'.
Proof. by move=> HM HN; exact: cvgB. Qed.

(* Умножение матриц: поэлементно. *)
Lemma cvgn_mulmx p q r
    (M : nat -> 'M[C]_(p, q)) (N : nat -> 'M[C]_(q, r))
    (L : 'M[C]_(p, q)) (L' : 'M[C]_(q, r)) :
  M @ \oo --> L -> N @ \oo --> L' ->
  (fun k => M k *m N k) @ \oo --> L *m L'.
Proof.
move=> HM HN; apply/mxcvgn_to_cvgn=> i j.
have HMe := cvgn_to_mxcvgn HM.
have HNe := cvgn_to_mxcvgn HN.
rewrite (_ : (L *m L') i j = \sum_s L i s * L' s j); last by rewrite mxE.
under eq_cvg=> k do rewrite mxE.
apply: cvgC_sum=> s _; exact: cvgC_M (HMe i s) (HNe s j).
Qed.

(* След: сумма диагональных элементов. *)
Lemma cvgn_mxtrace n (M : nat -> 'M[C]_n) (L : 'M[C]_n) :
  M @ \oo --> L -> (fun k => \tr (M k)) @ \oo --> \tr L.
Proof.
move=> HM; have HMe := cvgn_to_mxcvgn HM.
rewrite /mxtrace; apply: cvgC_sum=> i _; exact: HMe.
Qed.

(* Непрерывность скалярного сопряжения над `numClosedFieldType`.    *)
(* Используем `|x^* - y^*| = |(x - y)^*| = |x - y|`; формально       *)
(* достаточно факта об изометрии.                                    *)
Lemma conjC_cont_o : continuous (fun x : C^o => (x^* : C^o)).
Proof.
apply: isometry_continuous_ => x y.
by rewrite -rmorphB norm_conjC.
Qed.

Lemma conjC_continuous : continuous (fun x : C => x^*).
Proof. exact: conjC_cont_o. Qed.

(* Сопряжённое транспонирование непрерывно: каждый элемент          *)
(* получается через перестановку индексов и комплексное сопряжение. *)
Lemma cvgn_trmxC r c (M : nat -> 'M[C]_(r, c)) (L : 'M[C]_(r, c)) :
  M @ \oo --> L -> (fun k => (M k)^t*) @ \oo --> L^t*.
Proof.
move=> HM; apply/mxcvgn_to_cvgn=> i j.
have HMe : (fun k => M k j i) @ \oo --> L j i.
  exact: cvgn_to_mxcvgn HM j i.
have Hcont : {for L j i, continuous (fun x : C => x^*)}.
  exact: conjC_continuous.
have hF : Filter (\oo : set_system nat) by typeclasses eauto.
have Hconv := continuous_cvg hF Hcont HMe.
under eq_cvg=> k do rewrite !mxE.
by rewrite !mxE; exact: Hconv.
Qed.

End Continuity.
