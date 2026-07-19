(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Общий слой исполнимых seqmx-программ, не зависящий от коэффициентного типа.

  Здесь собраны примитивы, которыми пользуются все остальные файлы каталога
  `seqmx`: операции коммутативного кольца как экземпляры слоя `Refinements.Op`
  библиотеки CoqEAL, скалярная матрица по `iota`, вложение натуральных чисел
  в коэффициентный тип, сопряжённое транспонирование и степень матрицы, а также
  базовые теоремы `refines`, связывающие эти программы с матрицами MathComp.

  Скалярная матрица по iota и eqn.

  CoqEAL строит диагональные матрицы через mkseqmx_ord с перечислением
  ординалов 'I_n; перечисление проходит через непрозрачные доказательства
  вида reflect (idP и подобные), которые CertiRocq оставляет аксиомами: reflect
  лежит в Set, но тела непрозрачных доказательств недоступны стиранию MetaRocq.
  Построение по iota вычислительно чище: замыкание не содержит структур eqType,
  и один и тот же терм лучше поддаётся извлечению в целевые языки без
  промежуточных слоёв. Совпадение с построением CoqEAL даёт iscalar_seqmxE.
*)

From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(*
  Операции коммутативного кольца с обратимыми как экземпляры над CoqEAL. Это
  позволяет seqmx-программам исполняться на конкретном кольце, например на `rat`
  или на `ℂ`. Для `bigQ`, который не является `comUnitRingType`, используются
  экземпляры из `CoqEAL.binrat`.
*)
#[export] Instance ring_zero (R : comUnitRingType) : zero_of R := 0%R.
#[export] Instance ring_one  (R : comUnitRingType) : one_of R  := 1%R.
#[export] Instance ring_opp  (R : comUnitRingType) : opp_of R  := -%R.
#[export] Instance ring_add  (R : comUnitRingType) : add_of R  := +%R.
#[export] Instance ring_mul  (R : comUnitRingType) : mul_of R  := *%R.
#[export] Instance ring_eq   (R : comUnitRingType) : eq_of R   := eqtype.eq_op.
#[export] Instance ring_inv  (R : comUnitRingType) : inv_of R  := GRing.inv.

Section IotaScalar.

  Context (C : Type) `{!zero_of C}.

  Definition iscalar_seqmx (n : nat) (x : C) : @seqmx C :=
    map (fun i => map (fun j => if eqn i j then x else 0%C) (iota 0 n))
        (iota 0 n).

  Definition iseqmx1 `{!one_of C} (n : nat) : @seqmx C := iscalar_seqmx n 1%C.

End IotaScalar.

Lemma iscalar_seqmxE (C : Type) `{!zero_of C} (n : nat) (x : C) :
  iscalar_seqmx n x = scalar_seqmx n x.
Proof.
  rewrite /iscalar_seqmx /scalar_seqmx /diag_seqmx /mkseqmx_ord /const_seqmx /=.
  rewrite ord_enum_eqE size_nseq -val_enum_ord -map_comp.
  apply: eq_map => i /=; rewrite -map_comp.
  apply: eq_map => j /=.
  by rewrite nth_nseq ltn_ord eqnE val_eqE.
Qed.

Lemma iseqmx1E (C : Type) `{!zero_of C, !one_of C} (n : nat) :
  iseqmx1 n = seqmx1 n :> @seqmx C.
Proof.
  by rewrite /iseqmx1 /seqmx1 iscalar_seqmxE.
Qed.

(* Вложение натуральных чисел в коэффициентный тип как j-кратная сумма единиц. *)
Section CNat.

  Context (C : Type) `{!zero_of C, !one_of C, !add_of C}.

  (* j-кратная сумма единиц как элемент C, то есть образ j%:R. *)
  Definition cnat (j : nat) : C := iter j (fun x => (1 + x)%C) 0%C.

End CNat.

(* Эрмитово сопряжение: транспонируем и применяем `conj` поэлементно. *)
Section EffConjTranspose.

  Context (C : Type).
  Variable conj : C -> C.

  Definition ctr_seqmx (a b : nat) (A : @seqmx C) : @seqmx C :=
    map_seqmx conj (@trseqmx C a b A).

End EffConjTranspose.

(* Степень матрицы $A^k$ правым домножением, причём $A^0 = E$. *)
Section EffPow.

  Context (C : Type).
  Context `{!zero_of C, !one_of C, !add_of C, !mul_of C}.

  Definition mpow_seqmx (n : nat) (sA : @seqmx C) (k : nat) : @seqmx C :=
    iter k (fun acc => @hmul_op _ _ _ n n n acc sA) (iseqmx1 n).

End EffPow.

(* Базовые теоремы refines для примитивов выше. *)
Section RefineSupport.

  Variable R : comUnitRingType.

  Existing Instance Rseqmx_add.
  Existing Instance Rseqmx_opp.
  Existing Instance Rseqmx_mul.
  Existing Instance Rseqmx_1.
  Existing Instance Rseqmx_0.
  Existing Instance Rseqmx_trseqmx.
  Existing Instance Rseqmx_map_seqmx.

  Lemma refines_mulmx (a b c : nat) (X : 'M[R]_(a, b)) (Y : 'M[R]_(b, c))
      (sX sY : @seqmx R)
      (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX)
      (rY : refines (Rseqmx (nat_Rxx b) (nat_Rxx c)) Y sY) :
    refines (Rseqmx (nat_Rxx a) (nat_Rxx c)) (X *m Y)
      (@hmul_op _ _ _ a b c sX sY).
  Proof.
    exact: refines_apply.
  Qed.

  Lemma refines_addmx (a b : nat) (X Y : 'M[R]_(a, b)) (sX sY : @seqmx R)
      (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX)
      (rY : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) Y sY) :
    refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) (X + Y) (add_seqmx sX sY).
  Proof.
    exact: refines_apply.
  Qed.

  Lemma refines_oppmx (a b : nat) (X : 'M[R]_(a, b)) (sX : @seqmx R)
      (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX) :
    refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) (- X) (opp_seqmx sX).
  Proof.
    exact: refines_apply.
  Qed.

  (* Степень: `A^k` уточняется `mpow_seqmx`. *)
  Lemma rmpow (n : nat) (A : 'M[R]_n) (sA : @seqmx R)
      (rA : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) A sA) (k : nat) :
    refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) (A ^+ k) (mpow_seqmx n sA k).
  Proof.
    elim: k => [|k IHk].
    - rewrite expr0 /mpow_seqmx /= iseqmx1E; exact: Rseqmx_1.
    - rewrite exprSr /mpow_seqmx /= -/(mpow_seqmx n sA k) -mulmxE.
      exact: (refines_mulmx IHk rA).
  Qed.

  Variable conj : R -> R.

  #[local] Instance refines_conj :
    refines (@eq (R -> R)) conj conj := trivial_refines erefl.

  #[export] Instance refines_ctr_seqmx (a b : nat) (A : 'M[R]_(a, b))
      (sA : @seqmx R)
      (rA : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) A sA) :
    refines (Rseqmx (nat_Rxx b) (nat_Rxx a)) (map_mx conj A^T)
      (ctr_seqmx conj a b sA).
  Proof.
    rewrite /ctr_seqmx.
    exact: (refines_apply
              (refines_apply (Rseqmx_map_seqmx _ _) refines_conj)
              (refines_apply (Rseqmx_trseqmx _ _) rA)).
  Qed.

End RefineSupport.

(* Вложение cnat совпадает с натуральным умножением единицы поля. *)
Lemma cnat_natr (F : numFieldType) (j : nat) : (cnat j : F) = j%:R.
Proof.
  elim: j => [//|j IH]; rewrite /cnat /= -/(cnat j).
  by rewrite IH mulrSr addrC.
Qed.
