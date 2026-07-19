(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Инстанцирование исполнимых программ на примитивных числах с плавающей точкой
  Rocq (двоичный формат двойной точности, float64).

  Это инстанцирование не является уточнением спецификации.

  Тип `float` не несёт структур `comRingType` или `fieldType`, поэтому ни одна
  теорема `refines` из `riccati.v`, `gramian.v` и `closed_loop.v` к нему не
  применяется, и совпадение с оператором `riccati_step` здесь не доказывается.
  Каждая операция округляет результат к ближайшему представимому числу, так что
  даже кольцевые тождества выполняются лишь приближённо. Доказанная линия
  уточнения проходит по `rat` и `bigQ`: `inst_rat.v` связывает программу со
  спецификацией напрямую, `inst_bigQ.v` через гетерогенное отношение
  `RseqmxC r_ratBigQ`, а `inst_Q.v` сверяет с ними значения над Q.

  Назначение этого файла иное: быстро получать числовые значения для
  иллюстраций. Арифметика float64 выполняется за постоянное время, тогда как
  точные рациональные вычисления растут сверхлинейно по числу итераций, и на
  двухстах итерациях ДАУР разница составляет несколько порядков.

  Чтобы такое исполнение оставалось осмысленным, значения сверяются с точными:
  леммы `f_run_close_q`, `f_run3_close_q` и `f_dare_close_q` устанавливают через
  `vm_compute`, что наибольшее поэлементное отклонение от точных значений над Q
  не превосходит 1e-12. Сами значения над Q, в свою очередь, сверены с
  доказанными термами над bigQ в `inst_Q.v`.

  Отрицание задано как $0 - x$, а не примитивной операцией `PrimFloat.opp`: на
  нулевом аргументе `opp` даёт минус ноль, который попадал бы в числовой вывод
  отдельным представлением нуля.
*)

From Stdlib Require Import BinNat QArith Qreduction Floats.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Kalman.seqmx Require Import support inverse riccati sim inst_Q.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Refinements.Op.

(* Операции CoqEAL на float64. *)
#[export] Instance zero_F : zero_of float := 0%float.
#[export] Instance one_F  : one_of float  := 1%float.
#[export] Instance opp_F  : opp_of float  := fun x => (0 - x)%float.
#[export] Instance add_F  : add_of float  := PrimFloat.add.
#[export] Instance sub_F  : sub_of float  := PrimFloat.sub.
#[export] Instance mul_F  : mul_of float  := PrimFloat.mul.
#[export] Instance inv_F  : inv_of float  := fun x => (1 / x)%float.
#[export] Instance eq_F   : eq_of float   := PrimFloat.eqb.

(* Обратный элемент; отдельное имя нужно как аргумент программ прогона. *)
Definition finv (x : float) : float := (1 / x)%float.

Section FloatRun.

(* Обращение матриц 1 x 1 и 3 x 3 методом Фаддеева-Леверье. *)
Definition f_cinv  : @seqmx float -> @seqmx float := cinv_fl (C := float) 1.
Definition f_cinv3 : @seqmx float -> @seqmx float := cinv_fl (C := float) 3.

(* Прогон и трёхмерный прогон из sim.v при $C := "float"$. *)
Definition f_run (T : nat) : seq (sim_row float) :=
  kalman_sim_run finv (fun x : float => x) f_cinv T.

Definition f_run3 (seed : BinNums.N) (T : nat) : seq (sim_row float) :=
  kalman_sim3_run finv (fun x : float => x) f_cinv3 seed T.

(* Итерации ДАУР на системе прогона с нулевым начальным условием. *)
Definition f_dare_P0 : @seqmx float := [:: [:: 0%C; 0%C]; [:: 0%C; 0%C]].

Definition f_dare_step (sP : @seqmx float) : @seqmx float :=
  riccati_step_seqmx (fun x : float => x) 1 2 1
    (sim_F (C := float)) (sim_G (C := float) finv) (sim_H (C := float))
    (sim_Q (C := float) finv) (sim_R (C := float)) f_cinv sP.

Definition f_dare_iters (kmax : nat) : seq (@seqmx float) :=
  map (fun k => iter k f_dare_step f_dare_P0) (iota 0 kmax.+1).

End FloatRun.

(*
  Сверка с точными значениями над Q.

  Перевод рационального числа в float64 идёт по двоичной записи числителя и
  знаменателя, после чего выполняется одно деление. Наибольшее поэлементное
  отклонение сравнивается с допуском.
*)
Section CompareQ.

(* Двоичная запись положительного числа как значение float64. *)
Fixpoint f_of_pos (p : positive) : float :=
  match p with
  | xH => 1%float
  | xO p' => (2 * f_of_pos p')%float
  | xI p' => (2 * f_of_pos p' + 1)%float
  end.

Definition f_of_Z (z : Z) : float :=
  match z with
  | Z0 => 0%float
  | Zpos p => f_of_pos p
  | Zneg p => (0 - f_of_pos p)%float
  end.

Definition f_of_Q (q : Q) : float := (f_of_Z (Qnum q) / f_of_pos (Qden q))%float.

Definition fabs (x : float) : float :=
  if PrimFloat.ltb x 0%float then (0 - x)%float else x.

Definition fmax (x y : float) : float := if PrimFloat.ltb x y then y else x.

(* Наибольшее отклонение матрицы float64 от образа точной матрицы над Q. *)
Definition mx_dev (fm : @seqmx float) (qm : @seqmx Q) : float :=
  foldr fmax 0%float
    (flatten (map (fun rs => map (fun p => fabs (fst p - f_of_Q (snd p))%float)
                                 (zip rs.1 rs.2))
                  (zip fm qm))).

Definition row_dev (fr : sim_row float) (qr : sim_row Q) : float :=
  let: (a1, b1, c1, d1) := fr in
  let: (a2, b2, c2, d2) := qr in
  fmax (fmax (mx_dev a1 a2) (mx_dev b1 b2)) (fmax (mx_dev c1 c2) (mx_dev d1 d2)).

Definition run_dev (T : nat) : float :=
  foldr fmax 0%float (map (fun p => row_dev p.1 p.2) (zip (f_run T) (q_run T))).

Definition run3_dev (seed : BinNums.N) (T : nat) : float :=
  foldr fmax 0%float
    (map (fun p => row_dev p.1 p.2) (zip (f_run3 seed T) (q_run3 seed T))).

Definition dare_dev (kmax : nat) : float :=
  foldr fmax 0%float
    (map (fun p => mx_dev p.1 p.2) (zip (f_dare_iters kmax) (q_dare_iters kmax))).

(*
  Допуск сверки: $2^(-40)$, то есть примерно 9.1e-13. Степень двойки берётся
  затем, чтобы значение было представимо точно и не округлялось при разборе.
  Наблюдаемые отклонения не превосходят 1.6e-14, то есть допуск выше их примерно
  в шестьдесят раз.
*)
Definition f_tol : float := 0x1p-40%float.

(* Прогон в сорок шагов отклоняется от точного не более чем на допуск. *)
Lemma f_run_close_q : PrimFloat.leb (run_dev 40) f_tol = true.
Proof. by vm_compute. Qed.

(* Трёхмерный прогон в тридцать шагов отклоняется не более чем на допуск. *)
Lemma f_run3_close_q : PrimFloat.leb (run3_dev sim3_seed 30) f_tol = true.
Proof. by vm_compute. Qed.

(* Итерации ДАУР отклоняются от точных не более чем на допуск. *)
Lemma f_dare_close_q : PrimFloat.leb (dare_dev 36) f_tol = true.
Proof. by vm_compute. Qed.

End CompareQ.
