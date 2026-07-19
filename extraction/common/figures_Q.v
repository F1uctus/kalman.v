(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Инстанцирование документов фигур на точных рациональных числах Q.

  Восемь документов из `figures.v` подставляются на коэффициентный тип Q из
  Stdlib и переводятся в список байтов, который печатает скомпилированная
  CertiRocq программа. Каталог `extraction/c` берёт отсюда готовые термы и
  содержит только команды компиляции, поэтому печать документа определена в
  проекте единственный раз.

  Устойчивость Шура выводится в виде `schur_doc`, то есть одной матрицей
  $A_(c l)$ без её степеней: на точных рациональных числах знаменатели
  $A_(c l)$ велики уже после двухсот итераций ДАУР, и возведение в тридцатую
  степень неисполнимо. Степени и квадраты их норм даёт путь через float64, что
  разобрано в `figures.v`.
*)

Set Warnings "-all".
From Stdlib Require Import BinNat QArith List Strings.String Strings.Byte.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Kalman.seqmx Require Import
  support inverse riccati gramian closed_loop sim inst_Q.
From KalmanShow Require Import show show_json figures.

Local Open Scope string_scope.

Definition dare_json     : list byte := bytes_of_string (dare_doc     Q jnum).
Definition gramian_json  : list byte := bytes_of_string (gramian_doc  Q jnum).
Definition schur_json    : list byte := bytes_of_string (schur_doc    Q jnum).
Definition run_json      : list byte := bytes_of_string (run_doc      Q jnum).
Definition run3_json     : list byte := bytes_of_string (run3_doc     Q jnum).
Definition ortho_json    : list byte := bytes_of_string (ortho_doc    Q jnum).
Definition lyap_json     : list byte := bytes_of_string (lyap_doc     Q jnum).
Definition spectral_json : list byte := bytes_of_string (spectral_doc Q jnum).
