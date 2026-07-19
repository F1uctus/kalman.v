(*
  Точки входа WebAssembly для сырых данных фигур фильтра Калмана.

  Компилируются те же восемь документов из extraction/common/figures.v, что
  собирает генератор данных в extraction/data, но инстанцированные на точных
  рациональных числах Q из theories/seqmx/inst_Q.v. Это даёт независимую
  проверку: путь через dune считает на float64 и округляет, путь через
  CertiRocq считает точно, и значения должны совпадать в пределах округления
  двойной точности.

  Выводятся только сырые матрицы документом JSON (десятичные дроби,
  show_json); производные величины фигур вычисляются на стороне Typst.
  Компиляция идёт через backend C конвейера CertiRocq, в котором есть сборщик
  мусора gc_stack; прямой backend Wasm без сборки мусора для этих термов
  непригоден.
*)
Set Warnings "-all".
From Stdlib Require Import BinNat QArith List Strings.String Strings.Byte.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Kalman.seqmx Require Import
  support inverse riccati gramian closed_loop sim inst_Q.
From KalmanShow Require Import show show_json figures.
From CertiRocq.Plugin Require Import CertiRocq.

Set CertiRocq Build Directory "generated".
Local Open Scope string_scope.

(* Инстанцирование восьми документов на Q. *)
Definition dare_json     : list byte := bytes_of_string (dare_doc     Q jnum).
Definition gramian_json  : list byte := bytes_of_string (gramian_doc  Q jnum).
Definition schur_json    : list byte := bytes_of_string (schur_doc    Q jnum).
Definition run_json      : list byte := bytes_of_string (run_doc      Q jnum).
Definition run3_json     : list byte := bytes_of_string (run3_doc     Q jnum).
Definition ortho_json    : list byte := bytes_of_string (ortho_doc    Q jnum).
Definition lyap_json     : list byte := bytes_of_string (lyap_doc     Q jnum).
Definition spectral_json : list byte := bytes_of_string (spectral_doc Q jnum).

CertiRocq Compile -O 1 -file "dare" dare_json.
CertiRocq Generate Glue -file "glue_dare" [ list, byte ].
CertiRocq Compile -O 1 -file "gramian" gramian_json.
CertiRocq Generate Glue -file "glue_gramian" [ list, byte ].
CertiRocq Compile -O 1 -file "schur" schur_json.
CertiRocq Generate Glue -file "glue_schur" [ list, byte ].
CertiRocq Compile -O 1 -file "run" run_json.
CertiRocq Generate Glue -file "glue_run" [ list, byte ].
CertiRocq Compile -O 1 -file "run3" run3_json.
CertiRocq Generate Glue -file "glue_run3" [ list, byte ].
CertiRocq Compile -O 1 -file "orthogonality" ortho_json.
CertiRocq Generate Glue -file "glue_orthogonality" [ list, byte ].
CertiRocq Compile -O 1 -file "lyapunov" lyap_json.
CertiRocq Generate Glue -file "glue_lyapunov" [ list, byte ].
CertiRocq Compile -O 1 -file "spectral" spectral_json.
CertiRocq Generate Glue -file "glue_spectral" [ list, byte ].
