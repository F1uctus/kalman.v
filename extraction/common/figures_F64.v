(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Инстанцирование документов фигур на примитивных числах с плавающей точкой.

  Восемь документов из `figures.v` подставляются на тип float64. Это
  инстанцирование не является уточнением спецификации, что разобрано в заголовке
  `theories/seqmx/inst_Float64.v`; оно выбрано за постоянное время арифметики.
  Осмысленность значений закреплена леммами `f_run_close_q`, `f_run3_close_q` и
  `f_dare_close_q` того же файла, поэтому документы не соберутся, пока сверка с
  точным расчётом над Q не пройдёт.

  Печать коэффициента. Значение float64 переводится в точное рациональное число
  по представлению `Prim2SF`, то есть по знаку, мантиссе и двоичному порядку,
  после чего печатается той же десятичной записью `q_dec`, что и на пути через
  Q. Перевод точен: всякое конечное число двойной точности есть рациональное
  число со знаменателем, равным степени двойки.

  Устойчивость Шура выводится в виде `schur_pow_doc`, то есть вместе со
  степенями $A_(c l)^k$ и квадратами их норм Фробениуса: при постоянном времени
  арифметики они считаются мгновенно.
*)

Set Warnings "-all".
From Stdlib Require Import BinNat ZArith QArith Floats SpecFloat FloatOps.
From Stdlib Require Import List Strings.String Strings.Byte.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Kalman.seqmx Require Import
  support inverse riccati gramian closed_loop sim inst_Float64.
From KalmanShow Require Import show show_json figures.

Local Open Scope string_scope.

(*
  Точный перевод конечного числа двойной точности в рациональное: значение равно
  $(-1)^s m 2^e$, поэтому при неотрицательном порядке знаменатель равен единице,
  а при отрицательном равен $2^(-e)$.
*)
Definition q_of_float (x : float) : Q :=
  match Prim2SF x with
  | S754_finite s m e =>
      let n := if s then Zneg m else Zpos m in
      if (0 <=? e)%Z then Qmake (n * 2 ^ e) 1
      else Qmake n (Z.to_pos (2 ^ (- e)))
  | _ => 0%Q
  end.

(*
  Печать коэффициента. Бесконечность и нечисло выводятся словами, не
  являющимися числами JSON, поэтому их появление обнаруживается при разборе
  документа, а не превращается в правдоподобное значение.
*)
Definition fnum (x : float) : string :=
  match Prim2SF x with
  | S754_nan => "nan"
  | S754_infinity s => if s then "-inf" else "inf"
  | _ => q_dec 20 (q_of_float x)
  end.

(* Восемь документов как строки; их пишет генератор данных в extraction/data. *)
Definition d_dare     : string := dare_doc      float fnum.
Definition d_gramian  : string := gramian_doc   float fnum.
Definition d_schur    : string := schur_pow_doc float fnum.
Definition d_run      : string := run_doc       float fnum.
Definition d_run3     : string := run3_doc      float fnum.
Definition d_ortho    : string := ortho_doc     float fnum.
Definition d_lyap     : string := lyap_doc      float fnum.
Definition d_spectral : string := spectral_doc  float fnum.

(* Те же документы списком байтов; их компилирует CertiRocq в модуль WebAssembly. *)
Definition dare_json     : list byte := bytes_of_string d_dare.
Definition gramian_json  : list byte := bytes_of_string d_gramian.
Definition schur_json    : list byte := bytes_of_string d_schur.
Definition run_json      : list byte := bytes_of_string d_run.
Definition run3_json     : list byte := bytes_of_string d_run3.
Definition ortho_json    : list byte := bytes_of_string d_ortho.
Definition lyap_json     : list byte := bytes_of_string d_lyap.
Definition spectral_json : list byte := bytes_of_string d_spectral.
