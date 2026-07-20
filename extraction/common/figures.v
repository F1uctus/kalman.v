(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  The generic figure documents, parameterized by the coefficient ring and
  the coefficient printer
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

(* Printing a coefficient; printing a matrix is built from it. *)
Variable jnm : C -> string.

(*
  The inverse element is taken from the `inv_of` instance, and conjugation is
  the identity: the figure data is rational, and conjugation changes nothing on
  it. Both stay explicit arguments of the generic programs, so they are supplied
  here.
*)
Local Notation cinv1 := (fun x : C => (x^-1)%C).
Local Notation cconj := (fun x : C => x).

Definition jmx (m : @seqmx C) : string := jarr (map (fun r => jarr (map jnm r)) m).

(* The fractional constant a / b. *)
Definition frac (a b : nat) : C := cfrac cinv1 a b.

(* Inversion of matrices of order 1, 2 and 3 by the Faddeev-LeVerrier method. *)
Definition fig_cinv  : @seqmx C -> @seqmx C := cinv_fl (C := C) 1.
Definition fig_cinv2 : @seqmx C -> @seqmx C := cinv_fl (C := C) 2.
Definition fig_cinv3 : @seqmx C -> @seqmx C := cinv_fl (C := C) 3.

(*
  The figure system coincides with the run system of `sim.v`: the constant
  velocity model with n = 2 and m = p = 1.
*)
Local Notation sysF := (sim_F (C := C)).
Local Notation sysG := (sim_G (C := C) cinv1).
Local Notation sysH := (sim_H (C := C)).
Local Notation sysQ := (sim_Q (C := C) cinv1).
Local Notation sysR := (sim_R (C := C)).

(* The DARE step on the run system and its iterations from the zero initial condition. *)
Definition fig_dare_P0 : @seqmx C := [:: [:: 0%C; 0%C]; [:: 0%C; 0%C]].

Definition fig_dare_step (sP : @seqmx C) : @seqmx C :=
  riccati_step_seqmx cconj 1 2 1 sysF sysG sysH sysQ sysR fig_cinv sP.

Definition fig_dare_iters (kmax : nat) : seq (@seqmx C) :=
  map (fun k => iter k fig_dare_step fig_dare_P0) (iota 0 kmax.+1).

(*
  The steady-state covariance as the two-hundredth iteration. Two hundred
  iterations are enough for the value to stop changing within the printed
  precision.
*)
Definition fig_pss : @seqmx C := iter 200 fig_dare_step fig_dare_P0.

(* DARE convergence: the steady-state value and the first thirty-seven iterations. *)
Definition dare_doc : string :=
  jobj [:: ("P_ss", jmx fig_pss)
         ; ("iterations", jarr (map jmx (fig_dare_iters 36))) ].

(* The system for the gramians: a stable matrix with a nonzero coupling of coordinates. *)
Definition gram_F : @seqmx C := [:: [:: frac 4 5; frac 3 10]; [:: 0%C; frac 1 2]].
(* The observability weight gram_W equals the inverse of R when R is the identity matrix. *)
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

(* Observability and controllability gramians in the observed and blind direction. *)
Definition gramian_doc : string :=
  jobj [:: ("cases", jarr
    [:: gram_case "obsv" true  false [:: [:: 1%C; 0%C]] gram_W
      ; gram_case "obsv" false false [:: [:: 0%C; 1%C]] gram_W
      ; gram_case "ctrl" true  true  [:: [:: 0%C]; [:: 1%C]] gram_Q
      ; gram_case "ctrl" false true  [:: [:: 1%C]; [:: 0%C]] gram_Q ]) ].

(* Schur stability: the closed-loop matrix and its powers. *)
Definition fig_Acl : @seqmx C :=
  closed_loop_seqmx cconj 1 2 1 sysF sysG sysH sysQ sysR fig_cinv fig_pss.

(*
  The square of the Frobenius norm of a matrix of order 2, that is $tr (M† M)$.

  It is the square that is output, not the norm itself: the square root is not
  defined on exact rationals, so the document stays the same over Q and over
  float64, and the comparison of the two computation paths keeps its meaning.
  The figure builds a logarithmic axis on which the passage to the norm is a
  halving of the exponent.
*)
Definition frob_sq2 (M : @seqmx C) : C :=
  trace_seqmx (m := 2%N)
    (@hmul_op _ _ _ 2%N 2%N 2%N (ctr_seqmx cconj 2%N 2%N M) M).

(* Schur stability in two forms: $A_(c l)$ alone, or with its powers. *)
Definition schur_doc : string := jobj [:: ("A_cl", jmx fig_Acl) ].

Definition schur_pow_doc : string :=
  jobj [:: ("A_cl", jmx fig_Acl)
         ; ("powers", jarr (map (fun k =>
             let Ak := mpow_seqmx 2%N fig_Acl k in
             jobj [:: ("k", jnat k); ("A_cl_k", jmx Ak)
                    ; ("frob_sq", jnm (frob_sq2 Ak)) ])
             (iota 0 31))) ].

(* Filter runs. *)
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
  Orthogonality. The optimal update is compared with the update under other
  gains in the Joseph form.
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
  Partial sums of the Lyapunov equation. The controllability gramian with unit
  weights converges to the solution of the Lyapunov equation for gram_F.
*)
Definition lyap_step (k : nat) : @seqmx C :=
  ctrl_gram_seqmx cconj 2 2 gram_F (iseqmx1 2) (iseqmx1 2) k.

Definition lyap_doc : string :=
  jobj [:: ("lyap_sol", jmx (lyap_step 200))
         ; ("iterations", jarr (map (fun n => jmx (lyap_step n)) (iota 0 37))) ].

(* Antitonicity of inversion on a pair of nonnegative definite matrices. *)
Definition spec_A : @seqmx C :=
  [:: [:: frac 5 2; frac 3 2]; [:: frac 3 2; frac 5 2]].
Definition spec_B : @seqmx C :=
  [:: [:: frac 13 2; frac 5 2]; [:: frac 5 2; frac 13 2]].

Definition spectral_doc : string :=
  jobj [:: ("A", jmx spec_A); ("B", jmx spec_B)
         ; ("A_inv", jmx (fig_cinv2 spec_A))
         ; ("B_inv", jmx (fig_cinv2 spec_B)) ].

End Figures.
