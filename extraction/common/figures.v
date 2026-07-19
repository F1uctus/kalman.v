(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Документы JSON с сырыми данными фигур.

  Восемь документов собираются из тех же обобщённых программ слоя CoqEAL, что
  доказанно уточняют спецификацию: полушаги и шаг Риккати из `riccati.v`,
  грамианы из `gramian.v`, матрица замкнутого контура из `closed_loop.v` и
  прогоны из `sim.v`. Выводятся только сырые матрицы; производные величины
  фигур, то есть собственные значения, эллипсы, нормы Фробениуса и спектральный
  радиус, вычисляются на стороне Typst в `paper/viz/wire.typ`.

  Раздел параметризован коэффициентным типом и печатью коэффициента, поэтому
  один и тот же набор документов инстанцируется и на Q для компиляции через
  CertiRocq, и на float64 для быстрой генерации данных внутри dune.
*)

Set Warnings "-all".
From Stdlib Require Import BinNat QArith List Strings.String.
From mathcomp.boot Require Import all_boot.
From CoqEAL Require Import refinements seqmx.
From Kalman.seqmx Require Import support inverse riccati gramian closed_loop sim.
From KalmanShow Require Import show_json.

Local Open Scope string_scope.

Import Refinements.Op.

Section Figures.

Context (C : Type).
Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C, !inv_of C,
          !eq_of C}.

(* Печать коэффициента; печать матрицы строится из неё. *)
Variable jnm : C -> string.

(*
  Обратный элемент берётся из экземпляра `inv_of`, а сопряжение тождественно:
  данные фигур рациональны, и сопряжение на них ничего не меняет. Оба остаются
  явными аргументами обобщённых программ, поэтому подставляются здесь.
*)
Local Notation cinv1 := (fun x : C => (x^-1)%C).
Local Notation cconj := (fun x : C => x).

Definition jmx (m : @seqmx C) : string := jarr (map (fun r => jarr (map jnm r)) m).

(* Дробная константа a / b. *)
Definition frac (a b : nat) : C := cfrac cinv1 a b.

(* Обращение матриц порядков 1, 2 и 3 методом Фаддеева-Леверье. *)
Definition fig_cinv  : @seqmx C -> @seqmx C := cinv_fl (C := C) 1.
Definition fig_cinv2 : @seqmx C -> @seqmx C := cinv_fl (C := C) 2.
Definition fig_cinv3 : @seqmx C -> @seqmx C := cinv_fl (C := C) 3.

(*
  Система фигур совпадает с системой прогона из `sim.v`: модель постоянной
  скорости с n = 2 и m = p = 1.
*)
Local Notation sysF := (sim_F (C := C)).
Local Notation sysG := (sim_G (C := C) cinv1).
Local Notation sysH := (sim_H (C := C)).
Local Notation sysQ := (sim_Q (C := C) cinv1).
Local Notation sysR := (sim_R (C := C)).

(* Шаг ДАУР на системе прогона и его итерации из нулевого начального условия. *)
Definition fig_dare_P0 : @seqmx C := [:: [:: 0%C; 0%C]; [:: 0%C; 0%C]].

Definition fig_dare_step (sP : @seqmx C) : @seqmx C :=
  riccati_step_seqmx cconj 1 2 1 sysF sysG sysH sysQ sysR fig_cinv sP.

Definition fig_dare_iters (kmax : nat) : seq (@seqmx C) :=
  map (fun k => iter k fig_dare_step fig_dare_P0) (iota 0 kmax.+1).

(*
  Установившаяся ковариация как двухсотая итерация. Двухсот итераций хватает,
  чтобы значение перестало меняться в пределах выводимой точности.
*)
Definition fig_pss : @seqmx C := iter 200 fig_dare_step fig_dare_P0.

(* Сходимость ДАУР: установившееся значение и первые тридцать семь итераций. *)
Definition dare_doc : string :=
  jobj [:: ("P_ss", jmx fig_pss)
         ; ("iterations", jarr (map jmx (fig_dare_iters 36))) ].

(* Система для грамианов: устойчивая матрица с ненулевой связью координат. *)
Definition gram_F : @seqmx C := [:: [:: frac 4 5; frac 3 10]; [:: 0%C; frac 1 2]].
(* Вес наблюдаемости gram_W равен обращению R при R равном единичной матрице. *)
Definition gram_W : @seqmx C := [:: [:: 1%C]].
Definition gram_Q : @seqmx C := [:: [:: 1%C]].

Definition obsv (view : @seqmx C) (k : nat) : @seqmx C :=
  obsv_gram_seqmx cconj 2 1 gram_F view gram_W k.
Definition ctrl (view : @seqmx C) (k : nat) : @seqmx C :=
  ctrl_gram_seqmx cconj 2 1 gram_F view gram_Q k.

Definition gram_case (kind : string) (pos isctrl : bool)
    (view weight : @seqmx C) : string :=
  let at_k := if isctrl then ctrl view else obsv view in
  jobj [:: ("kind", """" ++ kind ++ """")
         ; ("positive", if pos then "true" else "false")
         ; ("F", jmx gram_F); ("view", jmx view); ("weight", jmx weight)
         ; ("frames", jarr (map (fun k => jmx (at_k k)) (iota 1 5))) ].

(* Грамианы наблюдаемости и управляемости в наблюдаемом и слепом направлении. *)
Definition gramian_doc : string :=
  jobj [:: ("cases", jarr
    [:: gram_case "obsv" true  false [:: [:: 1%C; 0%C]] gram_W
      ; gram_case "obsv" false false [:: [:: 0%C; 1%C]] gram_W
      ; gram_case "ctrl" true  true  [:: [:: 0%C]; [:: 1%C]] gram_Q
      ; gram_case "ctrl" false true  [:: [:: 1%C]; [:: 0%C]] gram_Q ]) ].

(* Устойчивость Шура: матрица замкнутого контура и её степени. *)
Definition fig_Acl : @seqmx C :=
  closed_loop_seqmx cconj 1 2 1 sysF sysG sysH sysQ sysR fig_cinv fig_pss.

(*
  Квадрат нормы Фробениуса матрицы порядка 2, то есть $tr (M† M)$.

  Выводится именно квадрат, а не сама норма: извлечение корня не определено на
  точных рациональных числах, поэтому документ остаётся одним и тем же на Q и
  на float64, и сверка двух путей вычисления сохраняет смысл. Фигура строит
  логарифмическую ось, на которой переход к норме есть деление порядка пополам.
*)
Definition frob_sq2 (M : @seqmx C) : C :=
  trace_seqmx (m := 2%N)
    (@hmul_op _ _ _ 2%N 2%N 2%N (ctr_seqmx cconj 2%N 2%N M) M).

(*
  Документ устойчивости Шура в двух видах.

  `schur_doc` выводит только $A_(c l)$ и годится на любом коэффициентном типе.
  `schur_pow_doc` добавляет степени $A_(c l)^k$ и квадраты их норм Фробениуса;
  его следует брать лишь там, где арифметика выполняется за постоянное время.
  На точных рациональных числах знаменатели $A_(c l)$ уже велики после двухсот
  итераций ДАУР, и возведение в тридцатую степень растёт настолько, что расчёт
  становится неисполнимым. Фигура строится по `schur_pow_doc`, а точный путь
  через CertiRocq сверяет `schur_doc`, то есть саму матрицу $A_(c l)$, из
  которой степени определены однозначно.
*)
Definition schur_doc : string := jobj [:: ("A_cl", jmx fig_Acl) ].

Definition schur_pow_doc : string :=
  jobj [:: ("A_cl", jmx fig_Acl)
         ; ("powers", jarr (map (fun k =>
             let Ak := mpow_seqmx 2%N fig_Acl k in
             jobj [:: ("k", jnat k); ("A_cl_k", jmx Ak)
                    ; ("frob_sq", jnm (frob_sq2 Ak)) ])
             (iota 0 31))) ].

(* Прогоны фильтра. *)
Definition simrow_doc (r : sim_row C) : string :=
  let: (xt, z, xe, P) := r in
  jobj [:: ("x_true", jmx xt); ("meas", jmx z)
         ; ("x_est", jmx xe); ("P", jmx P) ].

Definition run_doc : string :=
  jobj [:: ("steps", jarr (map simrow_doc
    (kalman_sim_run cinv1 cconj fig_cinv 40))) ].

Definition run3_doc : string :=
  jobj [:: ("steps", jarr (map simrow_doc
    (kalman_sim3_run cinv1 cconj fig_cinv3 sim3_seed 30))) ].

(*
  Ортогональность. Оптимальное обновление сравнивается с обновлением при
  других усилениях в форме Джозефа.
*)
Definition o_ppred : @seqmx C :=
  predict_cov_seqmx cconj 1 2 sysF sysG sysQ fig_pss.
Definition o_K : @seqmx C :=
  filter_gain_seqmx cconj 2 1 sysH sysR fig_cinv o_ppred.
Definition o_S : @seqmx C := innov_cov_seqmx cconj 2 1 sysH sysR o_ppred.
Definition o_Popt : @seqmx C :=
  update_cov_seqmx cconj 2 1 sysH sysR fig_cinv o_ppred.

Definition o_alt (label : string) (kp : @seqmx C) : string :=
  jobj [:: ("label", """" ++ label ++ """"); ("K", jmx kp)
         ; ("P_alt", jmx
             (alt_update_cov_seqmx cconj 2 1 sysH sysR kp o_ppred)) ].

Definition ortho_doc : string :=
  jobj [:: ("P_pred", jmx o_ppred); ("S", jmx o_S)
         ; ("K", jmx o_K); ("P_opt", jmx o_Popt)
         ; ("alternatives", jarr
             [:: o_alt "K' = 0" [:: [:: 0%C]; [:: 0%C]]
               ; o_alt "K' = 3K"
                   (map (map (fun x => (frac 3 1 * x)%C)) o_K) ]) ].

(*
  Частичные суммы уравнения Ляпунова. Грамиан управляемости с единичными
  весами сходится к решению уравнения Ляпунова для gram_F.
*)
Definition lyap_step (k : nat) : @seqmx C :=
  ctrl_gram_seqmx cconj 2 2 gram_F (iseqmx1 2) (iseqmx1 2) k.

Definition lyap_doc : string :=
  jobj [:: ("lyap_sol", jmx (lyap_step 200))
         ; ("iterations", jarr (map (fun n => jmx (lyap_step n)) (iota 0 37))) ].

(* Антитонность обращения на паре неотрицательно определённых матриц. *)
Definition spec_A : @seqmx C :=
  [:: [:: frac 5 2; frac 3 2]; [:: frac 3 2; frac 5 2]].
Definition spec_B : @seqmx C :=
  [:: [:: frac 13 2; frac 5 2]; [:: frac 5 2; frac 13 2]].

Definition spectral_doc : string :=
  jobj [:: ("A", jmx spec_A); ("B", jmx spec_B)
         ; ("A_inv", jmx (fig_cinv2 spec_A))
         ; ("B_inv", jmx (fig_cinv2 spec_B)) ].

End Figures.
