
module R = Riccati

let q0 = Q.zero
let q1 = Q.one
let qopp = Q.neg
let qadd = Q.add
let qmul = Q.mul
let qinv = Q.inv
let conj (x : Q.t) : Q.t = x

type mat = Q.t list list

let cinv1 s = List.map (List.map qinv) s
let cinv2 s = R.cinv2 q0 qopp qadd qmul qinv s

let ident n : mat =
  List.init n (fun i -> List.init n (fun j -> if i = j then q1 else q0))

let qsub a b = qadd a (qopp b)
let msub (p : mat) (q : mat) : mat = List.map2 (List.map2 qsub) p q

let step ~m ~n ~p ~cinv sF sG sH sQ sR sP =
  R.riccati_step_seqmx q0 q1 qopp qadd qmul conj m n p sF sG sH sQ sR cinv sP

let predict_cov ~m ~n sF sG sQ sP =
  R.predict_cov_seqmx q0 qadd qmul conj m n sF sG sQ sP

let kalman_gain ~n ~p ~cinv sH sR sPpred =
  R.kalman_gain_seqmx q0 qadd qmul conj n p sH sR cinv sPpred

let mpow ~n sA k = R.mpow_seqmx q0 q1 qadd qmul n sA k

let obsv_gram ~n ~p sF sH sW k =
  R.obsv_gram_seqmx q0 q1 qadd qmul conj n p sF sH sW k

let ctrl_gram ~n ~m sF sG sQ k =
  R.ctrl_gram_seqmx q0 q1 qadd qmul conj n m sF sG sQ k

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

let qf = Q.to_float
let mf m = Array.of_list (List.map (fun r -> Array.of_list (List.map qf r)) m)
let qget g i j = List.nth (List.nth g i) j

let eig2 p =
  let a = p.(0).(0) and b = p.(0).(1) and c = p.(1).(1) in
  let tr = a +. c and d = sqrt (((a -. c) /. 2.) ** 2. +. b *. b) in
  (tr /. 2. +. d, tr /. 2. -. d)

let ellipse2 p =
  let l1, l2 = eig2 p in
  let a = p.(0).(0) and b = p.(0).(1) in
  (sqrt (max 0. l1), sqrt (max 0. l2), atan2 (l1 -. a) b)

let qform_ellipse2 p =
  let l1, l2 = eig2 p in
  let a = p.(0).(0) and b = p.(0).(1) in
  (1. /. sqrt l1, 1. /. sqrt l2, atan2 (l1 -. a) b)

let eig2_general m =
  let a = m.(0).(0) and b = m.(0).(1) and c = m.(1).(0) and d = m.(1).(1) in
  let tr = a +. d and det = a *. d -. b *. c in
  let disc = (tr /. 2.) ** 2. -. det in
  if disc < 0. then
    let im = sqrt (-.disc) in
    ((tr /. 2., im), (tr /. 2., -.im))
  else
    let s = sqrt disc in
    ((tr /. 2. +. s, 0.), (tr /. 2. -. s, 0.))

let spectral_radius m =
  let (r1, i1), (r2, i2) = eig2_general m in
  max (Float.hypot r1 i1) (Float.hypot r2 i2)

let frob m =
  let s = ref 0. in
  Array.iter (fun row -> Array.iter (fun x -> s := !s +. x *. x) row) m;
  sqrt !s

let frob_dist p q =
  let s = ref 0. in
  for i = 0 to Array.length p - 1 do
    for j = 0 to Array.length p.(0) - 1 do
      let d = p.(i).(j) -. q.(i).(j) in
      s := !s +. d *. d
    done
  done;
  sqrt !s

let trace2 p = p.(0).(0) +. p.(1).(1)

let pd_exact g =
  let a = qget g 0 0 and b = qget g 0 1 and c = qget g 1 0 and d = qget g 1 1 in
  let det = qadd (qmul a d) (qopp (qmul b c)) in
  Q.sign a > 0 && Q.sign det > 0

let jfloat x = `Float x
let jint n = `Int n
let jvec a = `List (Array.to_list (Array.map jfloat a))
let jmat a = `List (Array.to_list (Array.map jvec a))
let jobj xs = `Assoc xs
let jellipse (a, b, ang) =
  jobj [ ("a", jfloat a); ("b", jfloat b); ("angle_rad", jfloat ang) ]

let qof_int = Q.of_int
let qfrac a b = Q.make (Z.of_int a) (Z.of_int b)

let psd_exact g =
  let a = qget g 0 0 and b = qget g 0 1 and c = qget g 1 0 and d = qget g 1 1 in
  let det = qadd (qmul a d) (qopp (qmul b c)) in
  Q.sign a >= 0 && Q.sign d >= 0 && Q.sign det >= 0


let sys_F = [ [ q1; q1 ]; [ q0; q1 ] ]
let sys_G = [ [ qfrac 1 2 ]; [ q1 ] ]
let sys_H = [ [ q1; q0 ] ]
let sys_Q = [ [ qfrac 1 10 ] ]
let sys_R = [ [ q1 ] ]
let sys_P0 = [ [ q0; q0 ]; [ q0; q0 ] ]

let dare_step = step ~m:1 ~n:2 ~p:1 ~cinv:cinv1 sys_F sys_G sys_H sys_Q sys_R

let jsystem =
  jobj
    [
      ("n", jint 2);
      ("m", jint 1);
      ("p", jint 1);
      ("F", jmat (mf sys_F));
      ("G", jmat (mf sys_G));
      ("H", jmat (mf sys_H));
      ("Q", jmat (mf sys_Q));
      ("R", jmat (mf sys_R));
    ]

let dare_iter_row k p pss =
  let l1, l2 = eig2 p in
  let fd = frob_dist p pss in
  jobj
    [
      ("k", jint k);
      ("P", jmat p);
      ("frob_dist", jfloat fd);
      ("log10_frob_dist", jfloat (if fd > 0. then log10 fd else -.infinity));
      ("trace", jfloat (trace2 p));
      ("eig", `List [ jfloat l1; jfloat l2 ]);
      ("ellipse", jellipse (ellipse2 p));
    ]

let gen_dare ~kmax ~kss path =
  let pss_q = iter kss dare_step sys_P0 in
  let pss = mf pss_q in
  let rows = ref [] in
  let cur = ref sys_P0 in
  for k = 0 to kmax do
    rows := dare_iter_row k (mf !cur) pss :: !rows;
    cur := dare_step !cur
  done;
  jobj
    [
      ("system", jsystem);
      ("Pss", jmat pss);
      ("Pss_ellipse", jellipse (ellipse2 pss));
      ("fixed_point_residual", jfloat (frob_dist (mf (dare_step pss_q)) pss));
      ("num_iterations", jint (kmax + 1));
      ("iterations", `List (List.rev !rows));
    ]
  |> Yojson.Basic.to_file path


let gram_F = [ [ qfrac 4 5; qfrac 3 10 ]; [ q0; qfrac 1 2 ] ]
let gram_W = cinv1 [ [ q1 ] ] (* weight = invmx R, R = I *)
let gram_Q = [ [ q1 ] ]

let gram_frame g k =
  let gf = mf g in
  let l1, l2 = eig2 gf in
  jobj
    [
      ("k", jint k);
      ("gram", jmat gf);
      ("eig", `List [ jfloat l1; jfloat l2 ]);
      ("pd", `Bool (pd_exact g));
      ("ellipse", jellipse (ellipse2 gf));
    ]

let gram_case ~kmax ~n ~kind ~positive ~view ~weight ~gram_at =
  let frames = List.init kmax (fun i -> gram_frame (gram_at (i + 1)) (i + 1)) in
  jobj
    [
      ("kind", `String kind);
      ("positive", `Bool positive);
      ("F", jmat (mf gram_F));
      ("view", jmat (mf view));
      ("weight", jmat (mf weight));
      ("pd_at_n", `Bool (pd_exact (gram_at n)));
      ("frames", `List frames);
    ]

let gen_gramian ~n ~kmax path =
  let obsv view k = obsv_gram ~n ~p:1 gram_F view gram_W k in
  let ctrl view k = ctrl_gram ~n ~m:1 gram_F view gram_Q k in
  let cases =
    [
      gram_case ~kmax ~n ~kind:"obsv" ~positive:true
        ~view:[ [ q1; q0 ] ] ~weight:gram_W ~gram_at:(obsv [ [ q1; q0 ] ]);
      gram_case ~kmax ~n ~kind:"obsv" ~positive:false
        ~view:[ [ q0; q1 ] ] ~weight:gram_W ~gram_at:(obsv [ [ q0; q1 ] ]);
      gram_case ~kmax ~n ~kind:"ctrl" ~positive:true
        ~view:[ [ q0 ]; [ q1 ] ] ~weight:gram_Q ~gram_at:(ctrl [ [ q0 ]; [ q1 ] ]);
      gram_case ~kmax ~n ~kind:"ctrl" ~positive:false
        ~view:[ [ q1 ]; [ q0 ] ] ~weight:gram_Q ~gram_at:(ctrl [ [ q1 ]; [ q0 ] ]);
    ]
  in
  jobj
    [
      ("n", jint n);
      ("kmax", jint kmax);
      ("cases", `List cases);
    ]
  |> Yojson.Basic.to_file path


let gen_schur ~kmax ~kss path =
  let pss_q = iter kss dare_step sys_P0 in
  let acl_q =
    closed_loop ~m:1 ~n:2 ~p:1 ~cinv:cinv1 sys_F sys_G sys_H sys_Q sys_R pss_q
  in
  let acl = mf acl_q in
  let (r1, i1), (r2, i2) = eig2_general acl in
  let pows =
    List.init (kmax + 1) (fun k ->
        jobj [ ("k", jint k); ("frob", jfloat (frob (mf (mpow ~n:2 acl_q k)))) ])
  in
  jobj
    [
      ("A_cl", jmat acl);
      ("spectral_radius", jfloat (spectral_radius acl));
      ( "eigenvalues",
        `List
          [
            jobj [ ("re", jfloat r1); ("im", jfloat i1) ];
            jobj [ ("re", jfloat r2); ("im", jfloat i2) ];
          ] );
      ("power_norms", `List pows);
    ]
  |> Yojson.Basic.to_file path


let rng = ref 123456789
let nextf () =
  rng := (1103515245 * !rng + 12345) land 0x3FFFFFFF;
  float_of_int !rng /. float_of_int 0x40000000

let gauss () =
  let u1 = nextf () and u2 = nextf () in
  sqrt (-2. *. log (max 1e-12 u1)) *. cos (2. *. Float.pi *. u2)

let fF = mf sys_F and fG = mf sys_G and fH = mf sys_H
let sigma_w = sqrt (qf (qget sys_Q 0 0))
let sigma_v = sqrt (qf (qget sys_R 0 0))

let matvec m v =
  Array.map (fun row -> Array.fold_left ( +. ) 0.
    (Array.mapi (fun j x -> x *. v.(j)) row)) m

let kr_P0 = [ [ qof_int 2; q0 ]; [ q0; qof_int 2 ] ]

let gen_kalman_run ~kmax path =
  rng := 123456789;
  let pcur = ref kr_P0 in
  let xt = ref [| 1.; 1. |] in
  let xe = ref [| 0.; 0. |] in
  let steps = ref [] in
  for k = 0 to kmax do
    let ppred = predict_cov ~m:1 ~n:2 sys_F sys_G sys_Q !pcur in
    let kk = mf (kalman_gain ~n:2 ~p:1 ~cinv:cinv1 sys_H sys_R ppred) in
    let meas = (matvec fH !xt).(0) +. sigma_v *. gauss () in
    let xpred = matvec fF !xe in
    let innov = meas -. (matvec fH xpred).(0) in
    let xe' = Array.mapi (fun i x -> x +. kk.(i).(0) *. innov) xpred in
    xe := xe';
    let pfilt = step ~m:1 ~n:2 ~p:1 ~cinv:cinv1 sys_F sys_G sys_H sys_Q sys_R !pcur in
    let pf = mf pfilt in
    steps :=
      jobj
        [
          ("k", jint k);
          ("x_true", jvec !xt);
          ("x_est", jvec !xe);
          ("meas", jfloat meas);
          ("pos_sigma", jfloat (sqrt pf.(0).(0)));
          ("ellipse", jellipse (ellipse2 pf));
        ]
      :: !steps;
    pcur := pfilt;
    let w = sigma_w *. gauss () in
    let drive = Array.map (fun row -> row.(0) *. w) fG in
    xt := Array.mapi (fun i x -> x +. drive.(i)) (matvec fF !xt)
  done;
  jobj
    [
      ("system", jsystem);
      ("steps", `List (List.rev !steps));
    ]
  |> Yojson.Basic.to_file path


let dl_F = [| [| 1.2; 0. |]; [| 0.; 0.5 |] |]
let dl_H = [| [| 1.; 0. |] |] (* output 1x2 *)
let dl_G = [| [| 0. |]; [| 1. |] |] (* input 2x1 *)

let tr_f m =
  let r = Array.length m and c = Array.length m.(0) in
  Array.init c (fun i -> Array.init r (fun j -> m.(j).(i)))

let mv_f m v =
  Array.init (Array.length m) (fun i ->
      let s = ref 0. in
      for j = 0 to Array.length v - 1 do
        s := !s +. (m.(i).(j) *. v.(j))
      done;
      !s)

let vm_f v m =
  Array.init (Array.length m.(0)) (fun j ->
      let s = ref 0. in
      for i = 0 to Array.length v - 1 do
        s := !s +. (v.(i) *. m.(i).(j))
      done;
      !s)

let vnorm_f v = sqrt (Array.fold_left (fun a x -> a +. (x *. x)) 0. v)

let reig2 m lam =
  let a = m.(0).(0) and b = m.(0).(1) and c = m.(1).(0) and d = m.(1).(1) in
  let v1 = [| b; lam -. a |] in
  let v = if vnorm_f v1 > 1e-9 then v1 else [| d -. lam; -.c |] in
  let n = vnorm_f v in
  Array.map (fun x -> x /. n) v

let leig2 m lam = reig2 (tr_f m) lam

let dl_mode m hout gin (re, im) =
  let v = reig2 m re and w = leig2 m re in
  let seen = vnorm_f (mv_f hout v) > 1e-7 in
  let reached = vnorm_f (vm_f w gin) > 1e-7 in
  jobj
    [
      ("re", jfloat re);
      ("im", jfloat im);
      ("abs", jfloat (Float.hypot re im));
      ("unstable", `Bool (Float.hypot re im >= 1.0));
      ("detectable", `Bool seen);
      ("stabilizable", `Bool reached);
    ]

let gen_duality path =
  let e1, e2 = eig2_general dl_F in
  let modes m hout gin = `List [ dl_mode m hout gin e1; dl_mode m hout gin e2 ] in
  let ft = tr_f dl_F and ht = tr_f dl_H and gt = tr_f dl_G in
  jobj
    [
      ("system", jobj [ ("F", jmat dl_F); ("H", jmat dl_H); ("G", jmat dl_G) ]);
      ("primal", modes dl_F dl_H dl_G);
      ("dual", modes ft gt ht);
    ]
  |> Yojson.Basic.to_file path


let qscale c (s : mat) : mat = List.map (List.map (qmul c)) s

let gen_orthogonality ~kss path =
  let pss = iter kss dare_step sys_P0 in
  let p_pred = predict_cov ~m:1 ~n:2 sys_F sys_G sys_Q pss in
  let k = kalman_gain ~n:2 ~p:1 ~cinv:cinv1 sys_H sys_R p_pred in
  let s = innov_cov ~n:2 ~p:1 sys_H sys_R p_pred in
  let p_opt = update_cov ~n:2 ~p:1 ~cinv:cinv1 sys_H sys_R p_pred in
  let tr_opt = trace2 (mf p_opt) in
  let alt label kp =
    let p_alt = alt_update_cov ~n:2 ~p:1 sys_H sys_R kp p_pred in
    let tr = trace2 (mf p_alt) in
    assert (tr_opt <= tr +. 1e-9);
    jobj [ ("label", `String label); ("K", jmat (mf kp)); ("trace", jfloat tr) ]
  in
  let zero_gain = [ [ q0 ]; [ q0 ] ] in
  let alts =
    [
      alt "K' = 0" zero_gain;
      alt "K' = 3K" (qscale (qof_int 3) k);
    ]
  in
  jobj
    [
      ("system", jsystem);
      ("P_pred", jmat (mf p_pred));
      ("S", jmat (mf s));
      ("K", jmat (mf k));
      ("trace_opt", jfloat tr_opt);
      ("alternatives", `List alts);
    ]
  |> Yojson.Basic.to_file path


let lyap_A = gram_F
let lyap_W = ident 2

let lyap_step k = lyap_partial ~n:2 lyap_A lyap_W k

let lyap_iter_row n_ p pss =
  let l1, l2 = eig2 p in
  let fd = frob_dist p pss in
  jobj
    [
      ("N", jint n_);
      ("P", jmat p);
      ("frob_dist", jfloat fd);
      ("log10_frob_dist", jfloat (if fd > 0. then log10 fd else -.infinity));
      ("trace", jfloat (trace2 p));
      ("eig", `List [ jfloat l1; jfloat l2 ]);
      ("ellipse", jellipse (ellipse2 p));
    ]

let gen_lyapunov ~kmax ~kss path =
  let pss_q = lyap_step kss in
  let pss = mf pss_q in
  let rows = ref [] in
  let prev_fd = ref infinity in
  let prev_q = ref (lyap_step 0) in
  for n_ = 0 to kmax do
    let cur_q = if n_ = 0 then !prev_q else lyap_step n_ in
    let cur = mf cur_q in
    let nxt_q = lyap_step (n_ + 1) in
    assert (psd_exact (msub nxt_q cur_q));
    let fd = frob_dist cur pss in
    assert (fd <= !prev_fd +. 1e-12);
    prev_fd := fd;
    prev_q := nxt_q;
    rows := lyap_iter_row n_ cur pss :: !rows
  done;
  jobj
    [
      ("A", jmat (mf lyap_A));
      ("W", jmat (mf lyap_W));
      ("lyap_sol", jmat pss);
      ("lyap_sol_ellipse", jellipse (ellipse2 pss));
      ("fixed_point_residual", jfloat (frob_dist (mf (lyap_step (kss + 1))) pss));
      ("num_iterations", jint (kmax + 1));
      ("iterations", `List (List.rev !rows));
    ]
  |> Yojson.Basic.to_file path


let spec_A = [ [ qfrac 5 2; qfrac 3 2 ]; [ qfrac 3 2; qfrac 5 2 ] ] (* eig 4, 1 *)
let spec_B = [ [ qfrac 13 2; qfrac 5 2 ]; [ qfrac 5 2; qfrac 13 2 ] ] (* eig 9, 4 *)

let spec_mat_obj g =
  let gf = mf g in
  let l1, l2 = eig2 gf in
  jobj
    [
      ("mat", jmat gf);
      ("eig", `List [ jfloat l1; jfloat l2 ]);
      ("qform_ellipse", jellipse (qform_ellipse2 gf));
    ]

let gen_spectral path =
  let a_inv = cinv2 spec_A and b_inv = cinv2 spec_B in
  assert (pd_exact spec_A);
  assert (pd_exact spec_B);
  assert (psd_exact (msub spec_B spec_A));
  assert (psd_exact (msub a_inv b_inv));
  jobj
    [
      ( "antitone",
        jobj
          [
            ("A", spec_mat_obj spec_A);
            ("B", spec_mat_obj spec_B);
            ("A_inv", spec_mat_obj a_inv);
            ("B_inv", spec_mat_obj b_inv);
          ] );
    ]
  |> Yojson.Basic.to_file path


let () =
  let f = [ [ qof_int 2 ] ] and one = [ [ q1 ] ] in
  let p2 = iter 2 (step ~m:1 ~n:1 ~p:1 ~cinv:cinv1 f one one one one) [ [ q1 ] ] in
  (match p2 with
   | [ [ v ] ] -> assert (Q.equal v (qfrac 13 16))
   | _ -> assert false);
  let dir = if Array.length Sys.argv > 1 then Sys.argv.(1) else "../../../paper/data" in
  gen_dare ~kmax:36 ~kss:200 (Filename.concat dir "dare_convergence.json");
  gen_gramian ~n:2 ~kmax:5 (Filename.concat dir "gramian.json");
  gen_schur ~kmax:30 ~kss:200 (Filename.concat dir "schur_stability.json");
  gen_kalman_run ~kmax:39 (Filename.concat dir "kalman_run.json");
  gen_duality (Filename.concat dir "duality_spectral.json");
  gen_orthogonality ~kss:200 (Filename.concat dir "orthogonality.json");
  gen_lyapunov ~kmax:36 ~kss:200 (Filename.concat dir "lyapunov.json");
  gen_spectral (Filename.concat dir "spectral.json")
