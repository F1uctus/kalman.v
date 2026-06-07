(*
  Детектируемость, стабилизируемость, PBH-тест.

  Критерий Попова–Белевича–Хаутуса (PBH-тест):
  - https://en.wikipedia.org/wiki/Hautus_lemma
  - https://arxiv.org/abs/2402.03245

  - Управляемость (по состоянию): систему можно перевести из любого начального
    состояния в любое другое за конечное время допустимым управлением;
    критерий - матрица управляемости полного ранга.
  - Наблюдаемость: состояние полностью восстановимо по выходу; критерий -
    матрица наблюдаемости полного ранга.

  Здесь используется эквивалентный критерий Попова–Белевича–Хаутуса (PBH),
  проверяемый на собственных значениях матрицы $F$:

  - Критерий управляемости: пара $(F, G)$ управляема <=> $forall λ$
    (собственного значения $F$) выполнено условие максимального ранга
    $"rank" [F - λ E | G] = n$. Геометрический смысл: нет левого собственного
    вектора матрицы $F$, ортогонального всем столбцам матрицы управления $G$.

  - `stabilizable F G`: для каждого левого собственного вектора $w$ матрицы $F$
    с $|λ| >= 1$ выполнено $w G != 0$ (соответствующая мода управляема).

  - Критерий наблюдаемости: пара $(F, H)$ наблюдаема <=> $forall λ$
    (собственного значения $F$) выполнено условие: $"rank" [F† - λ E | H†] = n$.
    Геометрический смысл: ни один правый собственный вектор матрицы $F$ не лежит
    в ядре матрицы выхода $H$.

  - `detectable F H`: для каждого правого собственного вектора $v$ матрицы $F$ с
    $|λ| >= 1$ выполнено $H v != 0$ (соответствующая мода наблюдаема).

  unit_circle_controllable F G - условие управляемости на единичной окружности
  $|λ| >= 1$.

  - @kailath2000[App. C, § C.3];
  - @kailath2000[App. C, § C.4].
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite kalman spec_rad.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(*
  Устойчивость по Шуру (для дискретной системы - асимптотическая устойчивость):
  спектральный радиус строго меньше единицы, т.е. все собственные значения лежат
  строго внутри единичного круга.

  - @kailath2000[App. C, § C.3].
*)
Definition schur_stable
  (ℂ : numClosedFieldType) (n : nat) (A : 'M[ℂ]_n) : Prop :=
    spec_rad_lt1 A.

(* Детектируемость (правый PBH-тест). *)
Section Detectability.

  Variable (ℂ : numClosedFieldType).

  Variables (n p : nat).

  Variables (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)).

  (*
    Детектируемость (правый тест PBH).

    Каждый правый собственный вектор $v$ матрицы $F$ с $|λ| >= 1$ не лежит в
    ядре выхода: $H v != 0$.

    - @kailath2000[App. C, § C.4 "Observability"].
  *)
  Definition detectable : Prop :=
    forall (lam : ℂ) (v : 'cV[ℂ]_n),
      v != 0 -> F *m v = lam *: v -> 1 <= `|lam| -> H *m v != 0.

  (* Степень F на собственном векторе: F^i ⋅ v = lam^i * v. *)
  Lemma F_pow_eigvec i (lam : ℂ) (v : 'cV[ℂ]_n) :
    F *m v = lam *: v -> F^+i *m v = lam^+i *: v.
  Proof.
    move=> Fv.
    elim: i => [|i IH]; first by rewrite !expr0 mul1mx scale1r.
    by rewrite exprS -mulmxA IH -scalemxAr Fv scalerA exprSr.
  Qed.

  (*
    Наблюдаемость влечёт детектируемость (нет неустойчивых ненаблюдаемых мод).

    - @kailath2000[App. C, § C.4].
  *)
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

  (*
    Детектируемость через стабилизирующую коррекцию.

    Существует коррекция по выходу $K$, делающая замкнутый контур $F - K H$
    устойчивым по Шуру.

    - @kailath2000[App. C, § C.4 "Observability"]; @wonham1985[§ 2.2, Thm 2.2].
  *)
  Definition detectable_stabilizing : Prop :=
    exists K : 'M[ℂ]_(n, p), spec_rad_lt1 (F - K *m H).

  (*
    Стабилизирующая коррекция влечёт детектируемость.

    Если существует коррекция $K$ с устойчивой по Шуру $F - K H$, то пара
    $(F, H)$ детектируема: у устойчивого контура нет неустойчивых ненаблюдаемых
    мод.

    - @kailath2000[App. C, § C.4 "Observability"].
  *)
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

(* Стабилизируемость и UCC (двойственное, левый PBH-тест). *)
Section Stabilizability.

  Variable (ℂ : numClosedFieldType).

  Variables (m n : nat).

  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)).

  (*
    Стабилизируемость (левый тест PBH).

    Каждый левый собственный вектор $w$ матрицы $F$ с $|λ| >= 1$ возбуждается
    входом: $w G != 0$.

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)
  Definition stabilizable : Prop :=
    forall (lam : ℂ) (w : 'rV[ℂ]_n),
      w != 0 -> w *m F = lam *: w -> 1 <= `|lam| -> w *m G != 0.

  (*
    Управляемость на единичной окружности (левый PBH на |λ| = 1).

    - @kailath2000[App. C, § C.3].
  *)
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

  (*
    Управляемость => стабилизируемость.

    - @kailath2000[App. C, § C.3].
  *)
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

  (*
    UCC следует из стабилизируемости: на единичной окружности $|λ| = 1 >= 1$.
  *)
  Theorem stabilizable_ucc :
    stabilizable -> unit_circle_controllable.
  Proof.
    move=> Hstab lam w wNZ wF_eq lam_eq1.
    apply: (Hstab lam w wNZ wF_eq).
    by rewrite lam_eq1.
  Qed.

  (*
    Существует обратная связь по состоянию K, делающая замкнутый контур
    $F - G K$ устойчивым по Шуру.

    - @kailath2000[App. C, § C.3]; @wonham1985[§ 2.2, Thm 2.2].
  *)
  Definition stabilizable_stabilizing : Prop :=
    exists K : 'M[ℂ]_(m, n), spec_rad_lt1 (F - G *m K).

  (*
    Тривиальное направление (двойственно детектируемости, левый PBH): если
    $F - G K$ устойчива по Шуру и $w F = λ w$ с $|λ| >= 1$, то при $w G = 0$
    имеем $w (F - G K) = λ w$, противоречие с устойчивостью по Шуру.
  *)
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

  (* Стабилизируемость замыкания => управляемость на единичной окружности. *)
  Corollary stabilizable_stabilizing_ucc :
    stabilizable_stabilizing -> unit_circle_controllable.
  Proof.
    by move=> Hss; apply: stabilizable_ucc; exact: stabilizable_stabilizing_stabilizable.
  Qed.

End Stabilizability.

(*
  Положительно определённый вес делает пару $(F, M)$ стабилизируемой тривиально:
  нет левого собственного вектора $w != 0$ с $w M = 0$
  (иначе $w M w† = 0$ противоречит положительной определённости $M$).
*)
Lemma pd_stabilizable (ℂ : numClosedFieldType) (n : nat)
  (F M : 'M[ℂ]_n) : pd M -> stabilizable F M.
Proof.
  move=> Mpd lam w wNZ _ _; apply/negP=> /eqP wM0.
  have u0 : w^t* = 0.
    apply: (pd_qf0_col0 Mpd).
    by rewrite trmxCK wM0 mul0mx mxtrace0.
  have wzero : w = 0 by rewrite -(trmxCK w) u0 trmxC0.
  by rewrite wzero eqxx in wNZ.
Qed.

(*
  Если матрица устойчива по Шуру, то у неё нет собственных значений с
  $|λ| >= 1$. Поэтому условия detectable / stabilizable выполняются тривиально,
  т.к. нет неустойчивых мод.
*)
Section SchurStableTrivialDet.

  Variable (ℂ : numClosedFieldType).

  Variables (n p : nat).

  Variables (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)).

  (*
    Мост между устойчивостью по Шуру и PBH-условиями: при `schur_stable F` любая
    пара $(F, H)$ детектируема, потому что у $F$ нет неустойчивых мод.

    Устойчивость по Шуру `spec_rad_lt1 F` напрямую исключает собственные
    значения с $|λ| >= 1$: для любого правого собственного вектора $F v = λ v$
    ($v != 0$) по `spec_rad_lt1_eigval` имеем $|λ| < 1$.
  *)
  Theorem schur_stable_detectable : schur_stable F -> detectable F H.
  Proof.
    move=> Fc lam v vNZ Fv_eq lam_ge1.
    have hlt := spec_rad_lt1_eigval Fc vNZ Fv_eq.
    by move: (le_lt_trans lam_ge1 hlt); rewrite ltxx.
  Qed.

End SchurStableTrivialDet.

(*
  Назначение полюсов (детектируемость).

  Обратное направление: детектируемость пары $(F, H)$ влечёт существование
  стабилизирующей коррекции по выходу. Это теорема о назначении полюсов; её
  полное доказательство (через наблюдаемую форму) в mathcomp отсутствует,
  поэтому результат принят как аксиома.

  - @kailath2000[App. C, § C.4 "Observability"]; @wonham1985[§ 2.2, Thm 2.2].
*)
Axiom pole_placement_detect :
  forall (ℂ : numClosedFieldType) (n p : nat)
         (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)),
    detectable F H -> detectable_stabilizing F H.

(*
  Двойственное направление для стабилизируемости
  (назначение полюсов через обратную связь по состоянию).

  - @kailath2000[App. C, § C.3]; @wonham1985[§ 2.2, Thm 2.2].
*)
Axiom pole_placement_stab :
  forall (ℂ : numClosedFieldType) (m n : nat)
         (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)),
    stabilizable F G -> stabilizable_stabilizing F G.

(* Детектируемость переносится на пару $(F, H F)$. *)
Lemma detectable_mulHF (ℂ : numClosedFieldType) (n p : nat)
    (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)) :
  detectable F H -> detectable F (H *m F).
(*
  Схема: если каждый неустойчивый собственный вектор наблюдаем через $H$, то и
  через $H F$. Для $F v = λ v$ имеем $(H F) v = λ (H v)$; при $|λ| >= 1$ и
  $H v != 0$ скаляр $λ != 0$, поэтому $λ (H v) != 0$.
*)
Proof.
  move=> Hdet lam v vNZ Fv lam_ge1.
  have key : (H *m F) *m v = lam *: (H *m v).
    by rewrite -mulmxA Fv -scalemxAr.
  rewrite key scaler_eq0 negb_or; apply/andP; split.
  - by rewrite -normr_gt0; exact: lt_le_trans ltr01 lam_ge1.
  - exact: Hdet lam v vNZ Fv lam_ge1.
Qed.

(*
  Стабилизирующее усиление фильтра.

  Детектируемость пары $(F, H)$ даёт усиление $K_0$, делающее апостериорный
  замкнутый контур $(E - K_0 H) F$ устойчивым по Шуру.

  - @kailath2000[App. C, § C.4 "Observability"]; @wonham1985[§ 2.2, Thm 2.2].
*)
Lemma detectable_stabilizing_filter (ℂ : numClosedFieldType) (n p : nat)
    (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)) :
  detectable F H ->
  exists K0 : 'M[ℂ]_(n, p), spec_rad_lt1 ((1%:M - K0 *m H) *m F).
(*
  Так как $(E - K_0 H) F = F - K_0 (H F)$, достаточно стабилизировать
  предсказательный контур пары $(F, H F)$, которая детектируема по
  $"detectable_mulHF"$; стабилизирующее усиление доставляет
  $"pole_placement_detect"$.
*)
Proof.
  move=> Hdet.
  have Hdet' : detectable F (H *m F) := detectable_mulHF Hdet.
  have [K0 HK0] := pole_placement_detect Hdet'.
  exists K0.
  have ->: (1%:M - K0 *m H) *m F = F - K0 *m (H *m F).
    by rewrite mulmxBl mul1mx -mulmxA.
  exact: HK0.
Qed.
