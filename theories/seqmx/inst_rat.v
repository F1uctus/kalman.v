(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Инстанцирование исполнимых программ на поле рациональных чисел `rat`.

  Поле `rat` служит эталоном для `vm_compute`: арифметика точна, а операции
  слоя CoqEAL совпадают с кольцевыми операциями MathComp, поэтому уточнение из
  `riccati.v` применяется напрямую, без промежуточного отношения.

  Здесь собраны скалярный пример решения ДАУР и проверки того, что таблицы
  значений шума прогона совпадают с четырёхточечной моделью из `noise.v`.
*)

From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx.
From Kalman Require Import mxnotation riccati_def noise.
From Kalman.seqmx Require Import support inverse riccati sim.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.

(* Скалярная система: конкретное исполнение при conj := idfun и p = 1. *)
Section ConcreteRat.

  Existing Instance Rseqmx_map_seqmx.

  (* Уточнение скалярной матрицы её singleton-литералом seqmx. *)
  Lemma rseqmx_11 (a : rat) :
    refines (Rseqmx (nat_Rxx 1) (nat_Rxx 1)) (a%:M : 'M[rat]_1) [:: [:: a]].
  Proof.
    rewrite refinesE; constructor.
    - by [].
    - by case=> [|?].
    - by move=> i j; rewrite !ord1 mxE eqxx mulr1n.
  Qed.

  (* Скалярная система: $F = 2, G = H = Q = R = P_0 = 1$. *)
  Definition exF : 'M[rat]_1 := (2%:R)%:M.
  Definition exG : 'M[rat]_1 := 1%:M.
  Definition exH : 'M[rat]_1 := 1%:M.
  Definition exQ : 'M[rat]_1 := 1%:M.
  Definition exR : 'M[rat]_1 := 1%:M.
  Definition exP_0 : 'M[rat]_1 := 1%:M.

  Definition sxF : @seqmx rat := [:: [:: 2%:R : rat]].
  Definition sxG : @seqmx rat := [:: [:: 1 : rat]].
  Definition sxH : @seqmx rat := [:: [:: 1 : rat]].
  Definition sxQ : @seqmx rat := [:: [:: 1 : rat]].
  Definition sxR : @seqmx rat := [:: [:: 1 : rat]].
  Definition sxP_0 : @seqmx rat := [:: [:: 1 : rat]].

  Definition ex_step : @seqmx rat -> @seqmx rat :=
    riccati_step_seqmx (idfun : rat -> rat) 1 1 1 sxF sxG sxH sxQ sxR (cinv_fl 1).

  (* Итерация исполнимого шага уточняет абстрактную итерацию над rat. *)
  Lemma ex_iter_correct (k : nat) :
    refines (Rseqmx (nat_Rxx 1) (nat_Rxx 1))
      (iter k (riccati_step idfun exF exG exH exQ exR) exP_0)
      (iter k ex_step sxP_0).
  Proof.
    apply: (@riccati_iter_seqmx_correct rat idfun 1 1 1
              exF exG exH exQ exR sxF sxG sxH sxQ sxR
              (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _)
              (cinv_fl 1) (@cinv_fl_correct1 rat) k exP_0 sxP_0).
    exact: rseqmx_11.
  Qed.

End ConcreteRat.

(*
  Два шага: скалярное ДАУР из $P_0 = 1$ даёт $5/6$, затем $13/16$. Значение
  проверено через `vm_compute` и связано со спецификацией через
  `ex_iter_correct`, поскольку отношение `Rseqmx` функционально.
*)
Definition ex_two : @seqmx rat := iter 2 ex_step sxP_0.

Lemma ex_two_val :
  (ex_two == [:: [:: (13%:R / 16%:R : rat)]] :> @seqmx rat) = true.
Proof.
  by vm_compute.
Qed.

(* Проверки над rat: тождества значений шума прогона. *)
Section ConcreteRatSim.

  (* Константы cfrac есть отношения натуральных чисел в поле rat. *)
  Lemma cfrac_ratE (a b : nat) : cfrac (C := rat) GRing.inv a b = a%:R / b%:R.
  Proof.
    by rewrite /cfrac !cnat_natr.
  Qed.

  (* Таблица значений шума управления совпадает с моделью noise.v. *)
  Lemma wvalE (i : 'I_16) :
    wval (C := rat) GRing.inv i = noise_val (1%:R / 10%:R) (1%:R / 2%:R) i.
  Proof.
    by rewrite /wval /val4 /noise_val !ltb_ltn !cfrac_ratE.
  Qed.

  (* Таблица значений шума измерения совпадает с моделью noise.v. *)
  Lemma vvalE (i : 'I_16) :
    vval (C := rat) GRing.inv i = noise_val (1%:R / 2%:R) (3%:R / 2%:R) i.
  Proof.
    by rewrite /vval /val4 /noise_val !ltb_ltn !cfrac_ratE.
  Qed.

  (* Второй момент шума управления равен Q = 1/10. *)
  Lemma wvar_eq_Q :
    (5%:R * (1%:R / 10%:R) ^+ 2 + 3%:R * (1%:R / 2%:R) ^+ 2) / 8%:R
      = 1%:R / 10%:R :> rat.
  Proof.
    by apply/eqP; vm_compute.
  Qed.

  (* Второй момент шума измерения равен R = 1. *)
  Lemma vvar_eq_R :
    (5%:R * (1%:R / 2%:R) ^+ 2 + 3%:R * (3%:R / 2%:R) ^+ 2) / 8%:R
      = 1%:R :> rat.
  Proof.
    by apply/eqP; vm_compute.
  Qed.

End ConcreteRatSim.
