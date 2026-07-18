(*
  Дымовые тесты конвейера CertiRocq

  Замкнутые выражения форматируются в строки и компилируются в C;
  эталонные строки закреплены доказательством через vm_compute, вывод
  скомпилированных программ сверяется с ними побайтно.

  Первый тест (Q, конвейер по умолчанию) покрывает арифметику Z и Q с
  сокращением дробей, путь Decimal и String и обход списка байтов из C;
  это рабочий конвейер каталога. Второй тест (bigQ, ключ
  -unsafe-erasure) фиксирует поддержку коиндуктивных типов: замыкание
  bigQ содержит поток из StreamMemo (память операций BigN), конвейер
  по умолчанию такой программы не переводит.
*)

Set Warnings "-all".
From Stdlib Require Import ZArith QArith Qreduction List Strings.String Strings.Byte.
From Bignums Require Import BigQ.
From KalmanC Require Import show.
From CertiRocq.Plugin Require Import CertiRocq.

Set CertiRocq Build Directory "generated".

(* (2/7)^2 + (3)^(-1) = 4/49 + 1/3 = 61/147, затем глубокая арифметика. *)
Definition smoke_q : Q := Qred ((2 # 7) * (2 # 7) + / 3)%Q.
Definition smoke_deep : Q :=
  Qred (Qpower (44 # 14) 17 + Qpower (3 # 9) 23 - 1)%Q.

Definition smoke_out : list byte :=
  bytes_of_string
    (append (string_of_Q smoke_q) (append nl (string_of_Q smoke_deep))).

Example smoke_expected :
  string_of_Q smoke_q = "61/147"%string /\
  string_of_Q smoke_deep =
    "6236981143076424064767066702984442/21900576078914553391266189"%string.
Proof. vm_compute. split; reflexivity. Qed.

CertiRocq Compile -O 1 -file "smoke" smoke_out.
CertiRocq Generate Glue -file "glue_smoke" [ list, byte ].

(* Та же проверка над bigQ с многословным целым уровня zn2z. *)
Local Open Scope bigQ_scope.

Definition smoke_bq : bigQ :=
  BigQ.add_norm (BigQ.mul_norm (2 # 7) (2 # 7)) (BigQ.inv_norm (3 # 1)).
Definition smoke_bq_big : bigQ :=
  BigQ.mul_norm (123456789123456789 # 1) (123456789123456789 # 1).

Definition smoke_bq_out : list byte :=
  bytes_of_string
    (append (string_of_bigQ smoke_bq)
       (append nl (string_of_bigQ smoke_bq_big))).

Example smoke_bq_expected :
  string_of_bigQ smoke_bq = "61/147"%string /\
  string_of_bigQ smoke_bq_big =
    "15241578780673678515622620750190521/1"%string.
Proof. vm_compute. split; reflexivity. Qed.

CertiRocq Compile -unsafe-erasure -O 1 -file "smoke_bq" smoke_bq_out.
