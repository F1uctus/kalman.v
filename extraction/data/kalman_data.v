(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Генерация сырых данных фигур внутри dune.

  Документы из `extraction/common/figures.v` инстанцируются на примитивных
  числах с плавающей точкой. Такое исполнение не является уточнением
  спецификации, что подробно разобрано в заголовке `theories/seqmx/inst_Float64.v`;
  оно выбрано за постоянное время арифметики. Осмысленность значений закреплена
  леммами `f_run_close_q`, `f_run3_close_q` и `f_dare_close_q` того же файла:
  наибольшее поэлементное отклонение от точных значений над Q не превосходит
  $2^(-40)$. Поскольку этот файл зависит от `inst_Float64.v`, данные не будут
  собраны, пока сверка не пройдёт.

  Печать коэффициента. Значение float64 переводится в точное рациональное число
  по представлению `Prim2SF`, то есть по знаку, мантиссе и двоичному порядку,
  после чего печатается той же десятичной записью `q_dec`, что и на пути через
  Q. Перевод точен: всякое конечное число двойной точности есть рациональное
  число со знаменателем, равным степени двойки.

  Запись файла. У Rocq нет ввода и вывода, поэтому файл пишет команда elpi
  `WriteJson`: она приводит терм типа `string` к нормальной форме машиной
  `vm_compute`, обходит конструкторы `String` и `EmptyString`, собирая строку
  elpi, и записывает её в указанный путь. Правило dune вызывает `gen_data.v`,
  который состоит из восьми обращений к этой команде.
*)

Set Warnings "-all".
From Stdlib Require Import BinNat ZArith QArith Floats SpecFloat FloatOps.
From Stdlib Require Import List Strings.String.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From elpi Require Import elpi.
From Kalman.seqmx Require Import support inverse riccati gramian closed_loop sim.
From Kalman.seqmx Require Import inst_Float64.
From KalmanShow Require Import show show_json figures.

Local Open Scope string_scope.

Import Refinements.Op.

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

(* Инстанцирование восьми документов на float64. *)
Definition d_dare     : string := dare_doc     float fnum.
Definition d_gramian  : string := gramian_doc  float fnum.
Definition d_schur    : string := schur_pow_doc float fnum.
Definition d_run      : string := run_doc      float fnum.
Definition d_run3     : string := run3_doc     float fnum.
Definition d_ortho    : string := ortho_doc    float fnum.
Definition d_lyap     : string := lyap_doc     float fnum.
Definition d_spectral : string := spectral_doc float fnum.

(*
  Команда записи строки Rocq в файл.

  Терм приводится к нормальной форме машиной vm_compute, после чего дерево
  конструкторов String и Ascii разбирается в строку elpi: восемь булевых
  аргументов Ascii дают код символа, младший бит идёт первым.
*)
Elpi Command WriteJson.
Elpi Accumulate lp:{{

pred bit i:term, o:int.
bit (global (indc C)) N :- !,
  coq.gref->id (indc C) Id,
  ( Id = "true", !, N = 1
  ; Id = "false", !, N = 0
  ; coq.error "WriteJson: ожидался конструктор bool, получено" Id ).
bit T _ :- coq.error "WriteJson: ожидался bool, получено" {coq.term->string T}.

pred ascii->char i:term, o:string.
ascii->char (app [_, B0, B1, B2, B3, B4, B5, B6, B7]) S :- !,
  bit B0 N0, bit B1 N1, bit B2 N2, bit B3 N3,
  bit B4 N4, bit B5 N5, bit B6 N6, bit B7 N7,
  N is N0 + 2 * (N1 + 2 * (N2 + 2 * (N3 + 2 * (N4 + 2 * (N5 + 2 * (N6 + 2 * N7)))))),
  S is chr N.
ascii->char T _ :-
  coq.error "WriteJson: ожидался ascii, получено" {coq.term->string T}.

pred str->chars i:term, o:list string.
str->chars (app [_, A, R]) [C | L] :- !, ascii->char A C, str->chars R L.
str->chars (global _) [] :- !.
str->chars T _ :-
  coq.error "WriteJson: ожидалась string, получено" {coq.term->string T}.

main [str Path, trm T] :- !,
  coq.reduction.vm.norm T _ TV,
  str->chars TV L,
  std.string.concat "" L Json,
  open_out Path OC, output OC Json, close_out OC,
  coq.say "kalman-data: wrote" Path.
main _ :- coq.error "использование: Elpi WriteJson \"путь\" (терм)".

}}.
