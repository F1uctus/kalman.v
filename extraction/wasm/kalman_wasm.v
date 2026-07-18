(*
  Точки входа WebAssembly для сырых данных фигур фильтра Калмана.

  Компилируются замкнутые термы над Q из theories/seqmx/kalman_sim_q.v и
  одноимённых обобщённых программ riccati_seqmx.v. Выводятся только сырые
  матрицы документом JSON (десятичные дроби, show_json); производные
  величины фигур вычисляются на стороне Typst. Компиляция идёт через
  backend C конвейера CertiRocq, в котором есть сборщик мусора gc_stack;
  прямой backend Wasm без сборки мусора для этих термов непригоден.
*)
Set Warnings "-all".
From Stdlib Require Import BinNat QArith List Strings.String Strings.Byte.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Kalman.seqmx Require Import riccati_seqmx kalman_sim kalman_sim_q.
From KalmanC Require Import show show_json.
From CertiRocq.Plugin Require Import CertiRocq.

Set CertiRocq Build Directory "generated".
Local Open Scope string_scope.

Definition dare_pss : @seqmx Q := iter 200 q_dare_step q_dare_P0.

Definition dare_doc : string :=
  jobj [:: ("P_ss", jmat dare_pss)
         ; ("iterations", jarr (map jmat (q_dare_iters 36))) ].

Definition dare_json : list byte := bytes_of_string dare_doc.

CertiRocq Compile -O 1 -file "dare" dare_json.
CertiRocq Generate Glue -file "glue_dare" [ list, byte ].
