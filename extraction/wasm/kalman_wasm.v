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
From Kalman.seqmx Require Import riccati_seqmx experiments kalman_sim kalman_sim_q.
From KalmanC Require Import show show_json.
From CertiRocq.Plugin Require Import CertiRocq.

Set CertiRocq Build Directory "generated".
Local Open Scope string_scope.

Definition dare_pss : @seqmx Q := iter 200 q_dare_step q_dare_P0.

Definition dare_doc : string :=
  jobj [:: ("P_ss", jmat dare_pss)
         ; ("iterations", jarr (map jmat (q_dare_iters 36))) ].

Definition dare_json : list byte := bytes_of_string dare_doc.

Import Refinements.Op.

Definition q_cinv2 : @seqmx Q -> @seqmx Q := cinv_fl (C := Q) 2.

Definition q_id (n : nat) : @seqmx Q :=
  map (fun i => map (fun j => if eqn i j then (1%C : Q) else (0%C : Q)) (iota 0 n)) (iota 0 n).

Definition sys_F : @seqmx Q := [:: [:: 1; 1]; [:: 0; 1]].
Definition sys_G : @seqmx Q := [:: [:: 1#2]; [:: 1]].
Definition sys_H : @seqmx Q := [:: [:: 1; 0]].
Definition sys_Q : @seqmx Q := [:: [:: 1#10]].
Definition sys_R : @seqmx Q := [:: [:: 1]].

Definition gram_F : @seqmx Q := [:: [:: 4#5; 3#10]; [:: 0; 1#2]].
Definition gram_W : @seqmx Q := [:: [:: 1]].
Definition gram_Q : @seqmx Q := [:: [:: 1]].

Definition spec_A : @seqmx Q := [:: [:: 5#2; 3#2]; [:: 3#2; 5#2]].
Definition spec_B : @seqmx Q := [:: [:: 13#2; 5#2]; [:: 5#2; 13#2]].
Definition q3 : Q := 3#1.

(* грамианы *)
Definition obsv (view : @seqmx Q) (k : nat) : @seqmx Q :=
  obsv_gram_seqmx (fun x : Q => x) 2 1 gram_F view gram_W k.
Definition ctrl (view : @seqmx Q) (k : nat) : @seqmx Q :=
  ctrl_gram_seqmx (fun x : Q => x) 2 1 gram_F view gram_Q k.
Definition gram_case (kind : string) (pos isctrl : bool) (view weight : @seqmx Q) : string :=
  let at_k := if isctrl then ctrl view else obsv view in
  jobj [:: ("kind", """" ++ kind ++ """"); ("positive", if pos then "true" else "false")
         ; ("F", jmat gram_F); ("view", jmat view); ("weight", jmat weight)
         ; ("frames", jarr (map (fun k => jmat (at_k k)) (iota 1 5))) ].
Definition gramian_json : list byte := bytes_of_string (jobj [:: ("cases", jarr
  [:: gram_case "obsv" true  false [:: [:: 1; 0]] gram_W
    ; gram_case "obsv" false false [:: [:: 0; 1]] gram_W
    ; gram_case "ctrl" true  true  [:: [:: 0]; [:: 1]] gram_Q
    ; gram_case "ctrl" false true  [:: [:: 1]; [:: 0]] gram_Q ]) ]).

(* устойчивость Шура *)
Definition schur_pss : @seqmx Q := iter 200 q_dare_step q_dare_P0.
Definition schur_Acl : @seqmx Q :=
  closed_loop_seqmx (fun x : Q => x) 1 2 1 sys_F sys_G sys_H sys_Q sys_R q_cinv schur_pss.
(* Выводится только A_cl. Степени A_cl^k и их нормы для фигуры вычисляет Typst. *)
Definition schur_json : list byte := bytes_of_string (jobj
  [:: ("A_cl", jmat schur_Acl) ]).

(* прогоны Калмана *)
Definition simrow_doc (r : sim_row Q) : string :=
  let: (xt, z, xe, P) := r in
  jobj [:: ("x_true", jmat xt); ("meas", jmat z)
         ; ("x_est", jmat xe); ("P", jmat P) ].
Definition run_json : list byte :=
  bytes_of_string (jobj [:: ("steps", jarr (map simrow_doc (q_run 40))) ]).
Definition run3_json : list byte :=
  bytes_of_string (jobj [:: ("steps", jarr (map simrow_doc (q_run3 sim3_seed 30))) ]).

(* ортогональность *)
Definition o_pss : @seqmx Q := iter 200 q_dare_step q_dare_P0.
Definition o_ppred : @seqmx Q := predict_cov_seqmx (fun x : Q => x) 1 2 sys_F sys_G sys_Q o_pss.
Definition o_K : @seqmx Q := filter_gain_seqmx (fun x : Q => x) 2 1 sys_H sys_R q_cinv o_ppred.
Definition o_S : @seqmx Q := innov_cov_seqmx (fun x : Q => x) 2 1 sys_H sys_R o_ppred.
Definition o_Popt : @seqmx Q := update_cov_seqmx (fun x : Q => x) 2 1 sys_H sys_R q_cinv o_ppred.
Definition o_alt (label : string) (kp : @seqmx Q) : string :=
  jobj [:: ("label", """" ++ label ++ """"); ("K", jmat kp)
         ; ("P_alt", jmat (alt_update_cov_seqmx (fun x : Q => x) 2 1 sys_H sys_R kp o_ppred)) ].
Definition ortho_json : list byte := bytes_of_string (jobj
  [:: ("P_pred", jmat o_ppred); ("S", jmat o_S); ("K", jmat o_K); ("P_opt", jmat o_Popt)
    ; ("alternatives", jarr
        [:: o_alt "K' = 0" [:: [:: 0]; [:: 0]]
          ; o_alt "K' = 3K" (map (map (fun x => (q3 * x)%C)) o_K) ]) ]).

(* частичные суммы Ляпунова *)
Definition lyap_step (k : nat) : @seqmx Q :=
  ctrl_gram_seqmx (fun x : Q => x) 2 2 gram_F (q_id 2) (q_id 2) k.
Definition lyap_json : list byte := bytes_of_string (jobj
  [:: ("lyap_sol", jmat (lyap_step 200))
    ; ("iterations", jarr (map (fun n => jmat (lyap_step n)) (iota 0 37))) ]).

(* антитонность обращения *)
Definition spectral_json : list byte := bytes_of_string (jobj
  [:: ("A", jmat spec_A); ("B", jmat spec_B)
    ; ("A_inv", jmat (q_cinv2 spec_A)); ("B_inv", jmat (q_cinv2 spec_B)) ]).

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
