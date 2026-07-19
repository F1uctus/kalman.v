(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Генерация сырых данных фигур внутри dune.

  Документы берутся готовыми из `extraction/common/figures_F64.v`, где они
  инстанцированы на примитивных числах с плавающей точкой и снабжены сверкой с
  точным расчётом над Q.

  Запись файла. У Rocq нет ввода и вывода, поэтому файл пишет команда elpi
  `WriteJson`: она приводит терм типа `string` к нормальной форме машиной
  `vm_compute`, обходит конструкторы `String` и `EmptyString`, собирая строку
  elpi, и записывает её в указанный путь. Правило dune вызывает `gen_data.v`,
  который состоит из восьми обращений к этой команде.
*)

Set Warnings "-all".
From elpi Require Import elpi.
From KalmanShow Require Export figures_F64.

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
