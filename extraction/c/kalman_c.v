(*
  Точки входа CertiRocq для фильтра Калмана.

  Компилируются замкнутые термы над Q из theories/seqmx/kalman_sim_q.v:
  итерации ДАУР q_dare_iters (37 значений, как в dare_convergence.json),
  прогон q_run в сорок шагов и трёхмерный прогон q_run3 в тридцать
  шагов с посевом sim3_seed. Их значения совпадают с доказанными
  термами над bigQ (леммы q_run_eq_bigq, q_run3_eq_bigq,
  q_dare_iters_eq_bigq), которые удовлетворяют проверкам коридора
  (sim_run_in_band, sim3_run_in_band) и уточнению из riccati_seqmx.v
  (riccati_iter_seqmxC). Конвейер по умолчанию: все проходы стирания
  верифицированы.

  Вывод: текст, одна строка на шаг; элементы матрицы через пробел,
  строки матрицы через " ; ", части строки прогона через " | ".
*)

Set Warnings "-all".
From Stdlib Require Import BinNat QArith List Strings.String Strings.Byte.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Bignums Require Import BigQ.
From Kalman.seqmx Require Import kalman_sim kalman_sim_q.
From KalmanShow Require Import show.
From CertiRocq.Plugin Require Import CertiRocq.

Set CertiRocq Build Directory "generated".

(* Строка матрицы: элементы через пробел, строки через " ; ". *)
Definition row_str (r : seq Q) : string :=
  String.concat " " (map string_of_Q r).

Definition mx_str (m : @seqmx Q) : string :=
  String.concat " ; " (map row_str m).

(* Строка прогона: истинное состояние, измерение, оценка, ковариация. *)
Definition simrow_str (r : sim_row Q) : string :=
  let: (xt, z, xe, P) := r in
  String.concat " | " [:: mx_str xt; mx_str z; mx_str xe; mx_str P].

Definition lines (l : seq string) : string := String.concat nl l.

Definition c_text : string :=
  lines
    [:: "== dare =="%string
      ; lines (map mx_str (q_dare_iters 36))
      ; "== sim =="%string
      ; lines (map simrow_str (q_run 40))
      ; "== sim3 =="%string
      ; lines (map simrow_str (q_run3 sim3_seed 30)) ].

Definition c_all_out : list byte := bytes_of_string (append c_text nl).

CertiRocq Compile -O 1 -file "kalman_c" c_all_out.
CertiRocq Generate Glue -file "glue_kalman" [ list, byte ].
