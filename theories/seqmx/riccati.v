(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Вычислимое уточнение (refinement) шага Риккати через библиотеку CoqEAL.

  Доказательства живут на зависимых матрицах MathComp `'M[R]_(m, n)`, а
  исполнение на представлении `seqmx` (списки списков) из CoqEAL. Каждая
  `*_seqmx`-программа связана с абстрактным определением теоремой `refines`
  библиотеки CoqEAL, поэтому исполняемый код не переопределяет фильтр заново, а
  доказанно совпадает со спецификацией.

  Структура файла.

  - Абстрактные определения шага Риккати над произвольным коммутативным кольцом
    с единицами `R` и произвольной операцией сопряжения `conj : R -> R` вынесены
    в `riccati_def.v`. При `conj := conjC` над `numClosedFieldType` они
    совпадают с операторами `kalman.v`, при `conj := idfun` над `rat`/`bigQ`
    дают исполнимый эталон. Уточнение ниже формулируется на этих определениях.
  - `EffPrograms` - единственная исполнимая программа над слоем операций CoqEAL
    (`zero_of`, `add_of`, ...). Один и тот же терм запускается и на кольце `R`
    (для доказательств), и на быстром `bigQ` (для исполнения/извлечения).
  - `RefineRiccati` - теоремы `refines`, связывающие абстрактные определения с
    программой при подстановке `C := R`.
  - `BridgeC` - мост к `kalman.v`: при `conj := conjC` обобщённые определения
    совпадают с `kalman.riccati_step` по определению, откуда следствие
    `kalman_riccati_step_seqmx_correct`, то есть исполнимый шаг уточняет именно
    спецификацию из `kalman.v`.

  Обращение матрицы. CoqEAL не уточняет `invmx` над произвольным полем, поэтому
  обращение инновационной ковариации вынесено в параметр `cinv` с обязательством
  `cinv_correct`. Оно снимается для любого `p` программой `cinv_fl` из
  `inverse.v`.

  Поле исполнения. Уточнение доказано над абстрактным `R`, но исполняется на
  вычислимом поле: `rat` для эталона `vm_compute` в `inst_rat.v` и `bigQ` для
  быстрой двоичной арифметики в `inst_bigQ.v`.
*)

From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx.
From Kalman Require Import mxnotation riccati_def.
From Kalman.seqmx Require Import support.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(*
  Исполнимая программа над слоем операций CoqEAL.

  Программа параметризована типом `C` и операциями `zero_of`, ..., `eq_of`,
  поэтому один и тот же терм исполняется на любом `C` с такими операциями,
  например на `rat` или на `bigQ`.
*)
Section EffPrograms.

  Context (C : Type).
  Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C, !eq_of C}.
  Variable conj : C -> C.
  Variables (m n p : nat).
  Variables (sF sG sH sQ sR_m : @seqmx C).
  Variable cinv : @seqmx C -> @seqmx C.

  Definition predict_cov_seqmx (sP : @seqmx C) : @seqmx C :=
    add_seqmx
      (@hmul_op _ _ _ n n n (@hmul_op _ _ _ n n n sF sP) (ctr_seqmx conj n n sF))
      (@hmul_op _ _ _ n m n (@hmul_op _ _ _ n m m sG sQ) (ctr_seqmx conj n m sG)).

  Definition innov_cov_seqmx (sP : @seqmx C) : @seqmx C :=
    add_seqmx
      (@hmul_op _ _ _ p n p (@hmul_op _ _ _ p n n sH sP) (ctr_seqmx conj p n sH))
      sR_m.

  Definition filter_gain_seqmx (sP : @seqmx C) : @seqmx C :=
    @hmul_op _ _ _ n p p
      (@hmul_op _ _ _ n n p sP (ctr_seqmx conj p n sH))
      (cinv (innov_cov_seqmx sP)).

  Definition update_cov_seqmx (sP : @seqmx C) : @seqmx C :=
    let K := filter_gain_seqmx sP in
    @hmul_op _ _ _ n n n
      (sub_seqmx (iseqmx1 n) (@hmul_op _ _ _ n p n K sH)) sP.

  (*
    Альтернативный шаг обновления с заданным усилением `sKp` в форме Джозефа:
    $(E_n - K_p H) P (E_n - K_p H)† + K_p R K_p†$. Исполнимый аналог
    `alt_update_cov`.
  *)
  Definition alt_update_cov_seqmx (sKp sP : @seqmx C) : @seqmx C :=
    let EmKH := sub_seqmx (iseqmx1 n) (@hmul_op _ _ _ n p n sKp sH) in
    add_seqmx
      (@hmul_op _ _ _ n n n (@hmul_op _ _ _ n n n EmKH sP)
        (ctr_seqmx conj n n EmKH))
      (@hmul_op _ _ _ n p n (@hmul_op _ _ _ n p p sKp sR_m)
        (ctr_seqmx conj n p sKp)).

  (*
    Исполнимый шаг Риккати.

    Композиция исполнимых полушагов предсказания и обновления; дословный аналог
    оператора `riccati_step` из `riccati_def.v`.
  *)
  Definition riccati_step_seqmx (sP : @seqmx C) : @seqmx C :=
    update_cov_seqmx (predict_cov_seqmx sP).

End EffPrograms.

(* Корректность: подстановка $C := R$ и уточнения. *)
Section RefineRiccati.

  Variable R : comUnitRingType.

  Existing Instance Rseqmx_add.
  Existing Instance Rseqmx_opp.
  Existing Instance Rseqmx_mul.
  Existing Instance Rseqmx_1.
  Existing Instance Rseqmx_trseqmx.
  Existing Instance Rseqmx_map_seqmx.

  Variable conj : R -> R.

  Section System.

    Variables (m n p : nat).
    Variables (F : 'M[R]_n) (G : 'M[R]_(n, m)) (H : 'M[R]_(p, n)).
    Variables (Q : 'M[R]_m) (R_m : 'M[R]_p).

    Variables (sF sG sH sQ sR_m : @seqmx R).
    Hypothesis rF : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) F sF.
    Hypothesis rG : refines (Rseqmx (nat_Rxx n) (nat_Rxx m)) G sG.
    Hypothesis rH : refines (Rseqmx (nat_Rxx p) (nat_Rxx n)) H sH.
    Hypothesis rQ : refines (Rseqmx (nat_Rxx m) (nat_Rxx m)) Q sQ.
    Hypothesis rR_m : refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) R_m sR_m.

    (* Обращение $p times p$-матрицы; см. заголовок файла. *)
    Variable cinv : @seqmx R -> @seqmx R.

    Hypothesis cinv_correct : forall (S : 'M[R]_p) (sS : @seqmx R),
      refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) S sS ->
      refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) (invmx S) (cinv sS).

    Lemma predict_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
        (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
      refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (predict_cov conj F G Q P) (predict_cov_seqmx conj m n sF sG sQ sP).
    Proof.
      rewrite /predict_cov /predict_cov_seqmx.
      have rX := refines_mulmx (refines_mulmx rF rP) (refines_ctr_seqmx conj rF).
      have rY := refines_mulmx (refines_mulmx rG rQ) (refines_ctr_seqmx conj rG).
      exact: refines_apply.
    Qed.

    Lemma innov_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
        (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
      refines (Rseqmx (nat_Rxx p) (nat_Rxx p))
        (innov_cov conj H R_m P) (innov_cov_seqmx conj n p sH sR_m sP).
    Proof.
      rewrite /innov_cov /innov_cov_seqmx.
      have rX := refines_mulmx (refines_mulmx rH rP) (refines_ctr_seqmx conj rH).
      exact: refines_apply.
    Qed.

    Lemma filter_gain_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
        (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
      refines (Rseqmx (nat_Rxx n) (nat_Rxx p))
        (filter_gain conj H R_m P)
        (filter_gain_seqmx conj n p sH sR_m cinv sP).
    Proof.
      rewrite /filter_gain /filter_gain_seqmx.
      have rinv := cinv_correct (innov_cov_seqmx_correct rP).
      exact: (refines_mulmx (refines_mulmx rP (refines_ctr_seqmx conj rH)) rinv).
    Qed.

    Lemma update_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
        (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
      refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (update_cov conj H R_m P)
        (update_cov_seqmx conj n p sH sR_m cinv sP).
    Proof.
      rewrite /update_cov /update_cov_seqmx.
      have rK := filter_gain_seqmx_correct rP.
      have rKH := refines_mulmx rK rH.
      have r1 : refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
                  (1%:M : 'M[R]_n) (iseqmx1 n).
        by rewrite iseqmx1E; exact: Rseqmx_1.
      have rsub := refines_addmx r1 (refines_oppmx rKH).
      exact: (refines_mulmx rsub rP).
    Qed.

    Lemma alt_update_cov_seqmx_correct (K_p : 'M[R]_(n, p)) (sKp : @seqmx R)
        (rKp : refines (Rseqmx (nat_Rxx n) (nat_Rxx p)) K_p sKp)
        (P : 'M[R]_n) (sP : @seqmx R)
        (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
      refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (alt_update_cov conj H R_m K_p P)
        (alt_update_cov_seqmx conj n p sH sR_m sKp sP).
    Proof.
      rewrite /alt_update_cov /alt_update_cov_seqmx.
      have rKpH := refines_mulmx rKp rH.
      have r1 : refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
                  (1%:M : 'M[R]_n) (iseqmx1 n).
        by rewrite iseqmx1E; exact: Rseqmx_1.
      have rEmKH := refines_addmx r1 (refines_oppmx rKpH).
      have rT1 := refines_mulmx (refines_mulmx rEmKH rP)
                    (refines_ctr_seqmx conj rEmKH).
      have rT2 := refines_mulmx (refines_mulmx rKp rR_m)
                    (refines_ctr_seqmx conj rKp).
      exact: (refines_addmx rT1 rT2).
    Qed.

    Lemma riccati_step_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
        (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
      refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (riccati_step conj F G H Q R_m P)
        (riccati_step_seqmx conj m n p sF sG sH sQ sR_m cinv sP).
    Proof.
      rewrite /riccati_step /riccati_step_seqmx.
      exact: (update_cov_seqmx_correct (predict_cov_seqmx_correct rP)).
    Qed.

    (*
      Корректность итерации исполнимого шага.

      Программа `iter k riccati_step_seqmx sP_0` уточняет абстрактную итерацию
      `iter k riccati_step P_0`, что позволяет вычислять конечные приближения к
      установившейся ковариации $P_ss$ без обращения к пределу `mx_mono_lim`.
    *)
    Lemma riccati_iter_seqmx_correct (k : nat) (P_0 : 'M[R]_n) (sP_0 : @seqmx R)
        (rP_0 : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P_0 sP_0) :
      refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (iter k (riccati_step conj F G H Q R_m) P_0)
        (iter k (riccati_step_seqmx conj m n p sF sG sH sQ sR_m cinv) sP_0).
    Proof.
      elim: k => [|k IHk] /=; first exact: rP_0.
      exact: (riccati_step_seqmx_correct IHk).
    Qed.

  End System.

End RefineRiccati.

(*
  Мост к kalman.v: при $"conj" := "conjC"$ возвращаемся к спецификации над $ℂ$.
*)
Section BridgeC.

  Variable ℂ : numClosedFieldType.

  Variables (m n p : nat).
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variables (Q : 'M[ℂ]_m) (R_m : 'M[ℂ]_p).

  Variables (sF sG sH sQ sR_m : @seqmx ℂ).

  Hypothesis rF : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) F sF.
  Hypothesis rG : refines (Rseqmx (nat_Rxx n) (nat_Rxx m)) G sG.
  Hypothesis rH : refines (Rseqmx (nat_Rxx p) (nat_Rxx n)) H sH.
  Hypothesis rQ : refines (Rseqmx (nat_Rxx m) (nat_Rxx m)) Q sQ.
  Hypothesis rR_m : refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) R_m sR_m.

  Variable cinv : @seqmx ℂ -> @seqmx ℂ.

  Hypothesis cinv_correct : forall (S : 'M[ℂ]_p) (sS : @seqmx ℂ),
    refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) S sS ->
    refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) (invmx S) (cinv sS).

  (*
    Исполнимый шаг seqmx уточняет `riccati_step conjC`, то есть оператор
    `kalman.riccati_step` по определению.
  *)
  Corollary kalman_riccati_step_seqmx_correct (P : 'M[ℂ]_n) (sP : @seqmx ℂ)
      (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
    refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
      (riccati_step conjC F G H Q R_m P)
      (riccati_step_seqmx conjC m n p sF sG sH sQ sR_m cinv sP).
  Proof.
    apply: riccati_step_seqmx_correct; assumption.
  Qed.

End BridgeC.
