(*
  Детектируемость, стабилизируемость, PBH-тест.

  Определения (PBH — Popov–Belevitch–Hautus критерий):

  detectable F H —
    каждый правый собственный вектор `F` с |λ| ≥ 1 наблюдаем парой
    (F, H), т.е. `H v ≠ 0`.

  stabilizable F G —
    каждый левый собственный вектор `F` с |λ| ≥ 1 управляем парой
    (F, G), т.е. `w G ≠ 0`.

  unit_circle_controllable F G —
    условие УПРАВЛЯЕМОСТИ ровно на единичной окружности |λ| = 1.

  Schur-стабильность:

    schur_stable A := frob_sq A < 1

  (Это наш текущий аналог классической Шуровости — Фробениусова
  контракция строго меньше единицы.  Имплицирует, что все собственные
  значения внутри единичного круга, но строго сильнее: для матриц с
  спектральным радиусом < 1, но frob_sq ≥ 1, этого недостаточно.)

  Основные теоремы:
  * `observable_detectable`: observable F H => detectable F H.
  * `controllable_stabilizable`: controllable F G => stabilizable F G
  * `stabilizable_ucc`: stabilizable F G =>
     unit_circle_controllable F G (тривиально, т.к. |λ| = 1 => ≥ 1).

  Этот файл — инфраструктура для Sessions 16–18 (стабильность
  замкнутого контура `Fp`, замена `F_contract` на детектируемость +
  UCC в `dare.v`).
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite mxfrob kalman spec_rad.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(* ================================================================== *)
(*  Schur-стабильность через Фробениусовую контракцию                  *)
(* ================================================================== *)

Definition schur_stable
  (ℂ : numClosedFieldType) (n : nat) (A : 'M[ℂ]_n) : Prop :=
    frob_sq A < 1.

(* ================================================================== *)
(*  Детектируемость (правый PBH)                                       *)
(* ================================================================== *)

Section Detectability.
Variable (ℂ : numClosedFieldType).
Variables (n p : nat).
Variables (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)).

Definition detectable : Prop :=
  forall (lam : ℂ) (v : 'cV[ℂ]_n),
    v != 0 -> F *m v = lam *: v -> 1 <= `|lam| -> H *m v != 0.

(* Степень F на собственном векторе: F^+i ⋅ v = lam^+i *: v. *)
Lemma F_pow_eigvec i (lam : ℂ) (v : 'cV[ℂ]_n) :
  F *m v = lam *: v -> F^+i *m v = lam^+i *: v.
Proof.
move=> Fv.
elim: i => [|i IH]; first by rewrite !expr0 mul1mx scale1r.
by rewrite exprS -mulmxA IH -scalemxAr Fv scalerA exprSr.
Qed.

Theorem observable_detectable : observable F H -> detectable.
Proof.
move=> Hobs lam v vNZ Fv_eq _.
apply/negP=> /eqP Hv_eq0.
have Hblock : forall i : 'I_n, obsv_block F H i *m v = 0.
  move=> i.
  rewrite /obsv_block -mulmxA (F_pow_eigvec _ Fv_eq).
  by rewrite -scalemxAr Hv_eq0 scaler0.
have v0 := Hobs v Hblock.
by move: vNZ; rewrite v0 eqxx.
Qed.

(* ================================================================== *)
(*  Книжное определение: детектируемость = ∃ стабилизующий K           *)
(* ================================================================== *)

(* `detectable_stabilizing F H` — книжная формулировка (Kailath–Sayed– *)
(* Hassibi, App. C; Wonham 1985): существует выходная инъекция K,       *)
(* делающая замкнутый контур `F − K H` Schur-устойчивым.                *)
Definition detectable_stabilizing : Prop :=
  exists K : 'M[ℂ]_(n, p), spec_rad_lt1 (F - K *m H).

(* Тривиальное направление: стабилизуемость замыкания => PBH.           *)
(* Если `F − K H` Schur-устойчива и `F v = λ v` с `|λ| ≥ 1`, то при     *)
(* `H v = 0` имеем `(F − K H) v = λ v` — собственное значение замыкания *)
(* вне единичного круга, что противоречит Шуровости                     *)
(* (`spec_rad_lt1_eigval`).                                             *)
Theorem detectable_stabilizing_detectable :
  detectable_stabilizing -> detectable.
Proof.
move=> [K HK] lam v vNZ Fv lam_ge1.
apply/negP=> /eqP Hv0.
have eig : (F - K *m H) *m v = lam *: v.
  by rewrite mulmxBl Fv -mulmxA Hv0 mulmx0 subr0.
have hlt := spec_rad_lt1_eigval HK vNZ eig.
by move: (le_lt_trans lam_ge1 hlt); rewrite ltxx.
Qed.

End Detectability.

(* ================================================================== *)
(*  Стабилизируемость и UCC (двойственное, левый PBH)                  *)
(* ================================================================== *)

Section Stabilizability.
Variable (ℂ : numClosedFieldType).
Variables (m n : nat).
Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)).

Definition stabilizable : Prop :=
  forall (lam : ℂ) (w : 'rV[ℂ]_n),
    w != 0 -> w *m F = lam *: w -> 1 <= `|lam| -> w *m G != 0.

Definition unit_circle_controllable : Prop :=
  forall (lam : ℂ) (w : 'rV[ℂ]_n),
    w != 0 -> w *m F = lam *: w -> `|lam| = 1 -> w *m G != 0.

(* Степень F на левом собственном векторе. *)
Lemma F_pow_left_eigvec i (lam : ℂ) (w : 'rV[ℂ]_n) :
  w *m F = lam *: w -> w *m F^+i = lam^+i *: w.
Proof.
move=> wF.
elim: i => [|i IH]; first by rewrite !expr0 mulmx1 scale1r.
rewrite exprS [_ *m (_ *m _)]mulmxA wF -scalemxAl IH scalerA.
by rewrite mulrC exprSr.
Qed.

Theorem controllable_stabilizable :
  controllable F G -> stabilizable.
Proof.
move=> Hctrl lam w wNZ wF_eq _.
apply/negP=> /eqP wG_eq0.
have Hblock : forall i : 'I_n, w *m ctrl_block F G i = 0.
  move=> i.
  rewrite /ctrl_block mulmxA (F_pow_left_eigvec _ wF_eq).
  by rewrite -scalemxAl wG_eq0 scaler0.
have w0 := Hctrl w Hblock.
by move: wNZ; rewrite w0 eqxx.
Qed.

(* UCC слабее стабилизируемости: на единичной окружности |λ| = 1 ≥ 1. *)
Theorem stabilizable_ucc :
  stabilizable -> unit_circle_controllable.
Proof.
move=> Hstab lam w wNZ wF_eq lam_eq1.
apply: (Hstab lam w wNZ wF_eq).
by rewrite lam_eq1.
Qed.

(* ================================================================== *)
(*  Книжное определение: стабилизируемость = ∃ стабилизующий K         *)
(* ================================================================== *)

(* `stabilizable_stabilizing F G` — книжная формулировка: существует    *)
(* state-feedback K, делающий замкнутый контур `F − G K` Schur-         *)
(* устойчивым.                                                          *)
Definition stabilizable_stabilizing : Prop :=
  exists K : 'M[ℂ]_(m, n), spec_rad_lt1 (F - G *m K).

(* Тривиальное направление (двойственно детектируемости, левый PBH):    *)
(* если `F − G K` Schur-устойчива и `w F = λ w` с `|λ| ≥ 1`, то при     *)
(* `w G = 0` имеем `w (F − G K) = λ w`, противоречие со Шуровостью.      *)
Theorem stabilizable_stabilizing_stabilizable :
  stabilizable_stabilizing -> stabilizable.
Proof.
move=> [K HK] lam w wNZ wF lam_ge1.
apply/negP=> /eqP wG0.
have eig : w *m (F - G *m K) = lam *: w.
  by rewrite mulmxBr wF mulmxA wG0 mul0mx subr0.
have hlt := spec_rad_lt1_left_eigval HK wNZ eig.
by move: (le_lt_trans lam_ge1 hlt); rewrite ltxx.
Qed.

(* Стабилизуемость замыкания => управляемость на единичной окружности.  *)
Corollary stabilizable_stabilizing_ucc :
  stabilizable_stabilizing -> unit_circle_controllable.
Proof.
by move=> Hss; apply: stabilizable_ucc; exact: stabilizable_stabilizing_stabilizable.
Qed.

End Stabilizability.

(* ================================================================== *)
(*  Связь со Schur-стабильностью                                       *)
(* ================================================================== *)

(* Если матрица Schur-стабильна, то у неё нет собственных значений с    *)
(* |λ| ≥ 1.  Поэтому условия detectable / stabilizable выполняются      *)
(* тривиально (нет «неустойчивых» мод вообще).                          *)
Section SchurStableTrivialDet.
Variable (ℂ : numClosedFieldType).
Variables (n p : nat).
Variables (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)).

(* Frobenius-сжатие исключает собственные значения с |λ| ≥ 1: для      *)
(* любого собственного значения `lam` верно `|lam|^+2 ≤ frob_sq F < 1`.  *)
(* Доказательство: если F v = lam v с v ≠ 0, то                         *)
(*   |lam|^+2 * (v† v) = (lam v)† (lam v)                          *)
(*                     = (F v)† (F v)                              *)
(*                     = v† (F† F) v                             *)
(*                     ≤ frob_sq F * (v† v)                        *)
(* (последнее — `tr_conj_frob_le`).  Сокращая на `v† v > 0`,           *)
(* получаем `|lam|^+2 ≤ frob_sq F`.                                     *)

(* Эта лемма — мост между Шуровостью и PBH-условиями: при `schur_stable F` *)
(* любая пара `(F, H)` детектируема, потому что у F нет неустойчивых мод. *)
Theorem schur_stable_detectable : schur_stable F -> detectable F H.
Proof.
move=> Fc lam v vNZ Fv_eq lam_ge1.
(* Шаг 1: |lam|^+2 * (v† v) = v† (F† F) v. *)
have step1 :
   `|lam| ^+ 2 * \tr (v^t* *m v) = \tr (v^t* *m (F^t* *m F) *m v).
  have e1 : v^t* *m (F^t* *m F) *m v = (F *m v)^t* *m (F *m v).
    by rewrite trmxC_mul !mulmxA.
  rewrite e1 Fv_eq trmxC_scale.
  rewrite -scalemxAl -scalemxAr !mxtraceZ.
  by rewrite mulrA -normCKC.
(* Шаг 2: \tr (v† (F† F) v) ≤ frob_sq F * \tr (v† v).                      *)
(* Доказательство: LHS = \tr (F (v v†) F†) (cyclic trace + trmxC_mul),    *)
(* затем `tr_conj_frob_le F (psd (v v†))`.                                *)
have step2 :
   \tr (v^t* *m (F^t* *m F) *m v) <= frob_sq F * \tr (v^t* *m v).
  have e3 : v^t* *m (F^t* *m F) *m v = (F *m v)^t* *m (F *m v).
    by rewrite trmxC_mul !mulmxA.
  have e4 : \tr ((F *m v)^t* *m (F *m v)) = \tr (F *m (v *m v^t*) *m F^t*).
    rewrite mxtrace_mulC; congr (\tr _).
    by rewrite trmxC_mul !mulmxA.
  rewrite e3 e4.
  have vvtpsd : psd (v *m v^t*).
    have := psd_frob (v^t*); by rewrite trmxCK.
  apply: (le_trans (tr_conj_frob_le F vvtpsd)).
  by rewrite [\tr (v *m v^t*)]mxtrace_mulC.
(* Шаг 3: `v† ⋅ v` — strictly positive (v ≠ 0). *)
have vvpos : 0 < \tr (v^t* *m v).
  rewrite lt0r; apply/andP; split; last first.
    by have := frob_sq_ge0 v; rewrite /frob_sq.
  apply/negP=> /eqP /frob_sq_eq0 v0.
  by move: vNZ; rewrite v0 eqxx.
(* Шаг 4: |lam|^+2 ≤ frob_sq F. *)
have lam2_le : `|lam| ^+ 2 <= frob_sq F.
  rewrite -(ler_pM2r vvpos).
  by rewrite step1.
(* Шаг 5: но 1 ≤ |lam|, значит 1 ≤ |lam|^+2 ≤ frob_sq F < 1 — противоречие. *)
have one_le : (1 : ℂ) <= `|lam| ^+ 2.
  rewrite expr2 -[1]mul1r.
  apply: ler_pM => //; exact: ler01.
have : (1 : ℂ) < 1 by exact: (lt_le_trans (le_lt_trans one_le (le_lt_trans lam2_le Fc))).
by rewrite ltxx.
Qed.

End SchurStableTrivialDet.

(* ================================================================== *)
(*  Pole-placement (Tier-C debt): обратное направление эквивалентности  *)
(* ================================================================== *)

(* Обратное к `detectable_stabilizing_detectable` направление —         *)
(* «PBH-детектируемость => существование стабилизующего K» — это        *)
(* теорема о назначении полюсов (pole placement) для детектируемой      *)
(* пары.  Полное доказательство (через наблюдаемую каноническую форму / *)
(* форму Бруновского) — ~3000 LOC; в mathcomp/CoqQ отсутствует.  Книга  *)
(* Kailath–Sayed–Hassibi сама цитирует pole placement из стандартной    *)
(* литературы, а не доказывает его в App. E/C.  Поэтому постулируем как  *)
(* Tier-C debt с явной цитатой (см. план, Session 22 / Session 27).     *)
(*                                                                       *)
(* Цитаты:                                                               *)
(*   W. M. Wonham, "Linear Multivariable Control: A Geometric           *)
(*     Approach", 3rd ed., Springer 1985, Thm 2.2 (назначение полюсов). *)
(*   T. Kailath, A. H. Sayed, B. Hassibi, "Linear Estimation",          *)
(*     Prentice Hall 2000, App. C (Lem C.5.1) и гл. 14.5.               *)
Axiom pole_placement_detect :
  forall (ℂ : numClosedFieldType) (n p : nat)
         (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)),
    detectable F H -> detectable_stabilizing F H.

(* Двойственное направление для стабилизируемости (назначение полюсов   *)
(* через state-feedback).  Та же литература (Wonham 1985, Thm 2.1;      *)
(* Kailath et al., гл. 14.5).                                           *)
Axiom pole_placement_stab :
  forall (ℂ : numClosedFieldType) (m n : nat)
         (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)),
    stabilizable F G -> stabilizable_stabilizing F G.

(* ================================================================== *)
(*  Мост к АПОСТЕРИОРНОМУ замкнутому контуру `(I − K0 H) F`             *)
(* ================================================================== *)

(* Детектируемость переносится на пару `(F, H F)`: если каждый            *)
(* неустойчивый собственный вектор наблюдаем через `H`, то и через `H F`. *)
(* Для `F v = λ v` имеем `(H F) v = λ (H v)`; при `|λ| ≥ 1` и `H v ≠ 0`   *)
(* скаляр `λ ≠ 0`, поэтому `λ (H v) ≠ 0`.                                 *)
Lemma detectable_mulHF (ℂ : numClosedFieldType) (n p : nat)
    (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)) :
  detectable F H -> detectable F (H *m F).
Proof.
move=> Hdet lam v vNZ Fv lam_ge1.
have key : (H *m F) *m v = lam *: (H *m v).
  by rewrite -mulmxA Fv -scalemxAr.
rewrite key scaler_eq0 negb_or; apply/andP; split.
- by rewrite -normr_gt0; exact: lt_le_trans ltr01 lam_ge1.
- exact: Hdet lam v vNZ Fv lam_ge1.
Qed.

(* Книжная детектируемость пары `(F, H)` даёт стабилизирующее ФИЛЬТР-     *)
(* усиление `K0`, делающее АПОСТЕРИОРНЫЙ замкнутый контур                 *)
(* `Mc = (I − K0 H) F` Schur-устойчивым — ровно гипотеза `cl_contract`   *)
(* в `dare.v`.  Вывод без коспектральности и без обратимости `F`:        *)
(* `(I − K0 H) F = F − K0 (H F)`, поэтому достаточно стабилизировать      *)
(* ПРЕДСКАЗАТЕЛЬНЫЙ контур пары `(F, H F)` (которая детектируема по       *)
(* `detectable_mulHF`), что и даёт `pole_placement_detect`.              *)
Lemma detectable_stabilizing_filter (ℂ : numClosedFieldType) (n p : nat)
    (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)) :
  detectable F H ->
  exists K0 : 'M[ℂ]_(n, p), spec_rad_lt1 ((1%:M - K0 *m H) *m F).
Proof.
move=> Hdet.
have Hdet' : detectable F (H *m F) := detectable_mulHF Hdet.
have [K0 HK0] := pole_placement_detect Hdet'.
exists K0.
have ->: (1%:M - K0 *m H) *m F = F - K0 *m (H *m F).
  by rewrite mulmxBl mul1mx -mulmxA.
exact: HK0.
Qed.
