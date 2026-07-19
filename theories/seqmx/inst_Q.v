(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Инстанцирование исполнимых программ фильтра Калмана на рациональных числах Q
  из Stdlib для компиляции в C через CertiRocq.

  Термы те же обобщённые программы из riccati.v и sim.v; меняется только
  коэффициентный тип. Компилировать прогон прямо на bigQ нельзя: конвейер
  CertiRocq по умолчанию не переводит коиндуктивные типы, поскольку замыкание
  bigQ содержит поток из StreamMemo, то есть память операций BigN, а
  необязательный перевод по ключу -unsafe-erasure делает арифметику Bignums
  непригодно медленной: ленивые вызовы переводятся простыми замыканиями без
  запоминания результата. Двоичная арифметика Q компилируется конвейером по
  умолчанию, в котором верифицированы все проходы стирания. Сложение, вычитание
  и умножение на Q сокращают дробь через Qred, поэтому размеры числителей и
  знаменателей растут так же, как над bigQ.

  Совпадение значений с доказанными термами над bigQ закреплено через
  vm_compute: прогоны сверены леммами q_run_eq_bigq и q_run3_eq_bigq с bigq_run
  и bigq_run3, которые удовлетворяют проверкам коридора sim_run_in_band и
  sim3_run_in_band, а итерации ДАУР леммой q_dare_iters_eq_bigq с итерациями
  riccati_step_seqmx на bigQ, уточнение которой доказано в inst_bigQ.v
  (riccati_iter_seqmxC).
*)

From Stdlib Require Import BinNat QArith Qreduction.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx binrat.
From Bignums Require Import BigQ.
From Kalman.seqmx Require Import support inverse riccati sim inst_bigQ.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Refinements.Op.

(* Операции CoqEAL на Q; сложение, вычитание и умножение сокращают дробь. *)
#[export] Instance zero_Q : zero_of Q := 0%Q.
#[export] Instance one_Q  : one_of Q  := 1%Q.
#[export] Instance opp_Q  : opp_of Q  := Qopp.
#[export] Instance add_Q  : add_of Q  := Qplus'.
#[export] Instance sub_Q  : sub_of Q  := Qminus'.
#[export] Instance mul_Q  : mul_of Q  := Qmult'.
#[export] Instance inv_Q  : inv_of Q  := Qinv.
#[export] Instance eq_Q   : eq_of Q   := Qeq_bool.

Section QRun.

(* Обращение матриц 1 x 1 и 3 x 3 над Q методом Фаддеева-Леверье. *)
Definition q_cinv  : @seqmx Q -> @seqmx Q := cinv_fl (C := Q) 1.
Definition q_cinv3 : @seqmx Q -> @seqmx Q := cinv_fl (C := Q) 3.

(* Прогон и трёхмерный прогон из sim.v при C := Q. *)
Definition q_run (T : nat) : seq (sim_row Q) :=
  kalman_sim_run Qinv (fun x : Q => x) q_cinv T.

Definition q_run3 (seed : BinNums.N) (T : nat) : seq (sim_row Q) :=
  kalman_sim3_run Qinv (fun x : Q => x) q_cinv3 seed T.

(*
  Итерации ДАУР на системе прогона с нулевым начальным условием; тот же расчёт
  питает фигуру сходимости.
*)
Definition q_dare_P0 : @seqmx Q := [:: [:: 0%C; 0%C]; [:: 0%C; 0%C]].

Definition q_dare_step (sP : @seqmx Q) : @seqmx Q :=
  riccati_step_seqmx (fun x : Q => x) 1 2 1
    (sim_F (C := Q)) (sim_G (C := Q) Qinv) (sim_H (C := Q))
    (sim_Q (C := Q) Qinv) (sim_R (C := Q)) q_cinv sP.

Definition q_dare_iters (kmax : nat) : seq (@seqmx Q) :=
  map (fun k => iter k q_dare_step q_dare_P0) (iota 0 kmax.+1).

End QRun.

Section BridgeBigQ.

(*
  Совпадение значений с доказанными термами над bigQ.

  Оба вычисления держат дроби в сокращённом виде со знаком в числителе, поэтому
  перевод BigQ.to_Q даёт совпадение представлений, проверяемое vm_compute.
*)

(* Перевод матрицы bigQ в матрицу Q. *)
Definition qmx_of_bigq (s : @seqmx bigQ) : @seqmx Q :=
  map (map BigQ.to_Q) s.

(* Перевод строки прогона bigQ в строку прогона Q. *)
Definition qrow_of_bigq (r : sim_row bigQ) : sim_row Q :=
  let: (xt, z, xe, P) := r in
  (qmx_of_bigq xt, qmx_of_bigq z, qmx_of_bigq xe, qmx_of_bigq P).

(* Прогон над Q равен образу прогона над bigQ. *)
Lemma q_run_eq_bigq : q_run 40 = map qrow_of_bigq (bigq_run 40).
Proof. by vm_compute. Qed.

(* Трёхмерный прогон над Q равен образу трёхмерного прогона над bigQ. *)
Lemma q_run3_eq_bigq :
  q_run3 sim3_seed 30 = map qrow_of_bigq (bigq_run3 sim3_seed 30).
Proof. by vm_compute. Qed.

(*
  Итерации ДАУР исходной программы riccati_step_seqmx на bigQ; их уточнение
  доказано в inst_bigQ.v (riccati_iter_seqmxC).
*)
Definition bigq_dare_P0 : @seqmx bigQ := [:: [:: 0%C; 0%C]; [:: 0%C; 0%C]].

Definition bigq_dare_step (sP : @seqmx bigQ) : @seqmx bigQ :=
  riccati_step_seqmx (fun x : bigQ => x) 1 2 1
    (sim_F (C := bigQ)) (sim_G (C := bigQ) BigQ.inv_norm)
    (sim_H (C := bigQ)) (sim_Q (C := bigQ) BigQ.inv_norm)
    (sim_R (C := bigQ)) bigq_cinv sP.

Definition bigq_dare_iters (kmax : nat) : seq (@seqmx bigQ) :=
  map (fun k => iter k bigq_dare_step bigq_dare_P0) (iota 0 kmax.+1).

(* Итерации ДАУР над Q равны образу итераций над bigQ. *)
Lemma q_dare_iters_eq_bigq :
  q_dare_iters 36 = map qmx_of_bigq (bigq_dare_iters 36).
Proof. by vm_compute. Qed.

End BridgeBigQ.
