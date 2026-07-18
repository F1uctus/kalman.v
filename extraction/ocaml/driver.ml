(* Run the extracted, verified seqmx programs (theories/seqmx/*.v) over zarith
   Q.t and write the thesis figures' paper/data/*.json.

   The exact linear algebra is the extracted code; this driver only wires the Q
   coefficient dictionary, converts the extracted exact-rational matrices to
   float for JSON, and runs the seeded Kalman simulation. Every derived
   presentation quantity (eigenvalues, ellipses, norms, PD/PSD tests) is
   computed downstream in Typst, not here: the JSON below carries raw matrices
   only. *)

module R = Riccati

(* ---- exact rational coefficient dictionary (zarith analogue of bigQ) ---- *)
let q0 = Q.zero
let q1 = Q.one
let qopp = Q.neg
let qadd = Q.add
let qmul = Q.mul
let qinv = Q.inv
let conj (x : Q.t) : Q.t = x

type mat = Q.t list list

(* General-p inverse: the extracted Faddeev-LeVerrier method. *)
let cinv ~n s = R.cinv_fl q0 q1 qopp qadd qmul qinv n s

(* n x n identity in the seqmx (list-of-rows) representation. *)
let ident n : mat =
  List.init n (fun i -> List.init n (fun j -> if i = j then q1 else q0))

let qsub a b = qadd a (qopp b)
let msub (p : mat) (q : mat) : mat = List.map2 (List.map2 qsub) p q

(* ---- thin wrappers around the extracted seqmx programs ---- *)
let step ~m ~n ~p ~cinv sF sG sH sQ sR sP =
  R.riccati_step_seqmx q0 q1 qopp qadd qmul conj m n p sF sG sH sQ sR cinv sP

let predict_cov ~m ~n sF sG sQ sP =
  R.predict_cov_seqmx q0 qadd qmul conj m n sF sG sQ sP

let filter_gain ~n ~p ~cinv sH sR sPpred =
  R.filter_gain_seqmx q0 qadd qmul conj n p sH sR cinv sPpred

let mpow ~n sA k = R.mpow_seqmx q0 q1 qadd qmul n sA k

let obsv_gram ~n ~p sF sH sW k =
  R.obsv_gram_seqmx q0 q1 qadd qmul conj n p sF sH sW k

let ctrl_gram ~n ~m sF sG sQ k =
  R.ctrl_gram_seqmx q0 q1 qadd qmul conj n m sF sG sQ k

(* lyap_partial F W k = sum_{j<k} F^j W (F†)^j, computed by reusing the extracted
   controllability gramian with G = I_n, Q = W. By gramian_infty.ctrl_gram_eq_partial
   ctrl_gram F G Q k = lyap_partial F (G Q G†) k, so with G = I_n the program
   computes lyap_partial F (I W I†) k = lyap_partial F W k exactly. No new theory
   or extraction: the linear algebra stays in the verified seqmx core. *)
let lyap_partial ~n sF sW k = ctrl_gram ~n ~m:n sF (ident n) sW k

let closed_loop ~m ~n ~p ~cinv sF sG sH sQ sR sP =
  R.closed_loop_seqmx q0 qopp qadd qmul conj m n p sF sG sH sQ sR cinv sP

let innov_cov ~n ~p sH sR sP =
  R.innov_cov_seqmx q0 qadd qmul conj n p sH sR sP

let update_cov ~n ~p ~cinv sH sR sP =
  R.update_cov_seqmx q0 q1 qopp qadd qmul conj n p sH sR cinv sP

let alt_update_cov ~n ~p sH sR sKp sP =
  R.alt_update_cov_seqmx q0 q1 qopp qadd qmul conj n p sH sR sKp sP

let rec iter k f x = if k <= 0 then x else iter (k - 1) f (f x)

(* ---- conversions ---- *)
let qf = Q.to_float
let mf m = Array.of_list (List.map (fun r -> Array.of_list (List.map qf r)) m)
let qget g i j = List.nth (List.nth g i) j

(* ---- yojson helpers ---- *)
let jfloat x = `Float x
let jint n = `Int n
let jvec a = `List (Array.to_list (Array.map jfloat a))
let jmat a = `List (Array.to_list (Array.map jvec a))
let jobj xs = `Assoc xs

let qof_int = Q.of_int
let qfrac a b = Q.make (Z.of_int a) (Z.of_int b)
let qscale c (s : mat) : mat = List.map (List.map (qmul c)) s

(* ================= DARE / Riccati convergence ================= *)

let sys_F = [ [ q1; q1 ]; [ q0; q1 ] ]
let sys_G = [ [ qfrac 1 2 ]; [ q1 ] ]
let sys_H = [ [ q1; q0 ] ]
let sys_Q = [ [ qfrac 1 10 ] ]
let sys_R = [ [ q1 ] ]
let sys_P_0 = [ [ q0; q0 ]; [ q0; q0 ] ]

let dare_step = step ~m:1 ~n:2 ~p:1 ~cinv:(cinv ~n:1) sys_F sys_G sys_H sys_Q sys_R

let gen_dare ~kmax path =
  jobj
    [ ("P_ss", jmat (mf (iter 200 dare_step sys_P_0)));
      ("iterations",
       `List (List.init (kmax + 1) (fun k -> jmat (mf (iter k dare_step sys_P_0))))) ]
  |> Yojson.Basic.to_file path

(* ================= gramians ================= *)

let gram_F = [ [ qfrac 4 5; qfrac 3 10 ]; [ q0; qfrac 1 2 ] ]
let gram_W = cinv ~n:1 [ [ q1 ] ] (* weight = invmx R, R = I *)
let gram_Q = [ [ q1 ] ]

let gram_case ~kmax ~kind ~positive ~view ~weight ~gram_at =
  jobj
    [ ("kind", `String kind); ("positive", `Bool positive);
      ("F", jmat (mf gram_F)); ("view", jmat (mf view)); ("weight", jmat (mf weight));
      ("frames", `List (List.init kmax (fun i -> jmat (mf (gram_at (i + 1)))))) ]

let gen_gramian ~kmax path =
  let obsv view k = obsv_gram ~n:2 ~p:1 gram_F view gram_W k in
  let ctrl view k = ctrl_gram ~n:2 ~m:1 gram_F view gram_Q k in
  jobj
    [ ("cases",
       `List
         [ gram_case ~kmax ~kind:"obsv" ~positive:true
             ~view:[ [ q1; q0 ] ] ~weight:gram_W ~gram_at:(obsv [ [ q1; q0 ] ]);
           gram_case ~kmax ~kind:"obsv" ~positive:false
             ~view:[ [ q0; q1 ] ] ~weight:gram_W ~gram_at:(obsv [ [ q0; q1 ] ]);
           gram_case ~kmax ~kind:"ctrl" ~positive:true
             ~view:[ [ q0 ]; [ q1 ] ] ~weight:gram_Q ~gram_at:(ctrl [ [ q0 ]; [ q1 ] ]);
           gram_case ~kmax ~kind:"ctrl" ~positive:false
             ~view:[ [ q1 ]; [ q0 ] ] ~weight:gram_Q ~gram_at:(ctrl [ [ q1 ]; [ q0 ] ]) ]) ]
  |> Yojson.Basic.to_file path

(* ================= Schur stability ================= *)

(* Только A_cl; степени A_cl^k и их нормы вычисляет Typst (это визуализация). *)
let gen_schur ~kss path =
  let pss = iter kss dare_step sys_P_0 in
  let acl = closed_loop ~m:1 ~n:2 ~p:1 ~cinv:(cinv ~n:1) sys_F sys_G sys_H sys_Q sys_R pss in
  jobj [ ("A_cl", jmat (mf acl)) ] |> Yojson.Basic.to_file path

(* ================= Kalman runs ================= *)
(* Both runs are the extracted, verified programs theories/seqmx/kalman_sim.v
   (kalman_sim_run / kalman_sim3_run): the noises come from the four-point
   model of theories/noise.v and the sample path is the Lehmer generator
   defined inside Rocq (kalman_sim3_run additionally exercises the extracted
   general Faddeev-LeVerrier inverse, cinv ~n:3, since three positions are
   measured). No PRNG and no simulation logic lives in OCaml; this driver only
   converts the extracted exact-rational rows to raw JSON matrices. The head
   row of each run is the initial state before any filter update; its "meas"
   field is the zero-vector placeholder kalman_sim_run/kalman_sim3_run emit
   for that row (kalman_sim.v: head_row), so it serialises as a real zero
   matrix rather than JSON null. *)

let simrow_json (((xt, y), xe), p) =
  let meas = match y with [] -> `Null | _ -> jmat (mf y) in
  jobj [ ("x_true", jmat (mf xt)); ("meas", meas); ("x_est", jmat (mf xe)); ("P", jmat (mf p)) ]

let gen_kalman_run ~kmax path =
  jobj [ ("steps",
          `List (List.map simrow_json
                   (R.kalman_sim_run q0 q1 qopp qadd qmul qinv conj (cinv ~n:1) kmax))) ]
  |> Yojson.Basic.to_file path

let gen_kalman_run_3d ~kmax path =
  jobj [ ("steps",
          `List (List.map simrow_json
                   (R.kalman_sim3_run q0 q1 qopp qadd qmul qinv conj (cinv ~n:3) R.sim3_seed kmax))) ]
  |> Yojson.Basic.to_file path

(* ================= orthogonality ================= *)
(* For the steady predicted covariance P_pred = predict_cov(P_ss), the Kalman
   gain K minimises the trace of the posterior covariance update_cov P_pred;
   every other gain K' yields the Joseph-form alt_update_cov K' P_pred whose
   trace is not smaller (kalman.filter_gain_optimal). All matrices are the
   extracted seqmx programs (theories/seqmx/riccati_seqmx.v: filter_gain_seqmx
   / update_cov_seqmx / alt_update_cov_seqmx); the trace comparison itself is
   Typst's job now. K' = 0 is the estimator that ignores the new measurement,
   so its posterior is exactly the predicted covariance P_pred. *)

let gen_orthogonality ~kss path =
  let pss = iter kss dare_step sys_P_0 in
  let p_pred = predict_cov ~m:1 ~n:2 sys_F sys_G sys_Q pss in
  let k = filter_gain ~n:2 ~p:1 ~cinv:(cinv ~n:1) sys_H sys_R p_pred in
  let s = innov_cov ~n:2 ~p:1 sys_H sys_R p_pred in
  let p_opt = update_cov ~n:2 ~p:1 ~cinv:(cinv ~n:1) sys_H sys_R p_pred in
  let alt label kp =
    jobj [ ("label", `String label); ("K", jmat (mf kp));
           ("P_alt", jmat (mf (alt_update_cov ~n:2 ~p:1 sys_H sys_R kp p_pred))) ]
  in
  jobj
    [ ("P_pred", jmat (mf p_pred)); ("S", jmat (mf s)); ("K", jmat (mf k));
      ("P_opt", jmat (mf p_opt));
      ("alternatives",
       `List [ alt "K' = 0" [ [ q0 ]; [ q0 ] ]; alt "K' = 3K" (qscale (qof_int 3) k) ]) ]
  |> Yojson.Basic.to_file path

(* ================= Lyapunov partial sums ================= *)
(* lyap_partial A W N = sum_{k<N} A^k W (A†)^k rises monotonically (Loewner) to
   the Lyapunov solution lyap_sol A W = X solving X = A X A† + W
   (theories/lyapunov.v: lyap_partial, lyap_partial_mono, lyap_partial_psd; the
   limit lyap_sol and gramian_infty.ctrl_gram_infty = lyap_sol F (G Q G†)). The
   exact matrices are the extracted controllability gramian ctrl_gram_seqmx run
   with G = I_2, Q = W, which equals lyap_partial by ctrl_gram_eq_partial. A is
   the Schur-stable gram_F (frob_sq A = 49/50 < 1), W = I_2 (ident 2) is
   positive definite; lyap_sol is approximated by the partial sum at kss. *)

let lyap_step k = lyap_partial ~n:2 gram_F (ident 2) k

let gen_lyapunov ~kmax ~kss path =
  jobj
    [ ("lyap_sol", jmat (mf (lyap_step kss)));
      ("iterations", `List (List.init (kmax + 1) (fun n -> jmat (mf (lyap_step n))))) ]
  |> Yojson.Basic.to_file path

(* ================= antitone inverse ================= *)
(* Antitone inverse (spectral.pd_inv_antimono): A <= B (both PD) implies
   B^-1 <= A^-1. The matrices and their inverses are the extracted, verified
   core (cinv_fl = invmx by cinv_fl_correct); the PD/ordering checks and the
   quadratic-form level-ellipse presentation move to Typst. A, B share the
   45-degree eigenbasis for a clean picture; the lemma itself is general. *)

let spec_A = [ [ qfrac 5 2; qfrac 3 2 ]; [ qfrac 3 2; qfrac 5 2 ] ] (* eig 4, 1 *)
let spec_B = [ [ qfrac 13 2; qfrac 5 2 ]; [ qfrac 5 2; qfrac 13 2 ] ] (* eig 9, 4 *)

let gen_spectral path =
  jobj
    [ ("A", jmat (mf spec_A)); ("B", jmat (mf spec_B));
      ("A_inv", jmat (mf (cinv ~n:2 spec_A))); ("B_inv", jmat (mf (cinv ~n:2 spec_B))) ]
  |> Yojson.Basic.to_file path

(* ================= entry point ================= *)

let () =
  (* self-test: scalar DARE iterate 2 from P_0 = 1 is 13/16 *)
  let f = [ [ qof_int 2 ] ] and one = [ [ q1 ] ] in
  let p2 = iter 2 (step ~m:1 ~n:1 ~p:1 ~cinv:(cinv ~n:1) f one one one one) [ [ q1 ] ] in
  (match p2 with [ [ v ] ] -> assert (Q.equal v (qfrac 13 16)) | _ -> assert false);
  let dir = if Array.length Sys.argv > 1 then Sys.argv.(1) else "../../../paper/data" in
  gen_dare ~kmax:36 (Filename.concat dir "dare_convergence.json");
  gen_gramian ~kmax:5 (Filename.concat dir "gramian.json");
  gen_schur ~kss:200 (Filename.concat dir "schur_stability.json");
  gen_kalman_run ~kmax:40 (Filename.concat dir "kalman_run.json");
  gen_kalman_run_3d ~kmax:30 (Filename.concat dir "kalman_run_3d.json");
  gen_orthogonality ~kss:200 (Filename.concat dir "orthogonality.json");
  gen_lyapunov ~kmax:36 ~kss:200 (Filename.concat dir "lyapunov.json");
  gen_spectral (Filename.concat dir "spectral.json")
