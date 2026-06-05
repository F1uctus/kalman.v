

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

let closed_loop ~m ~n ~p ~cinv sF sG sH sQ sR sP =
  R.closed_loop_seqmx q0 qopp qadd qmul conj m n p sF sG sH sQ sR cinv sP

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
      ( "description",
        `String
            "DARE/Riccati convergence from the extracted seqmx core \
             (theories/seqmx/riccati_seqmx.v) over zarith Q.t." );
      ("system", jsystem);
      ("Pss", jmat pss);
      ("Pss_ellipse", jellipse (ellipse2 pss));
      ("fixed_point_residual", jfloat (frob_dist (mf (dare_step pss_q)) pss));
      ("num_iterations", jint (kmax + 1));
      ("iterations", `List (List.rev !rows));
    ]
  |> Yojson.Basic.to_file path

let gram_F = [ [ qfrac 4 5; qfrac 3 10 ]; [ q0; qfrac 1 2 ] ]
let gram_W = cinv1 [ [ q1 ] ] 
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
      ( "description",
        `String
            "Observability/controllability gramians O_k, C_k become PD exactly \
             at k=n for observable/controllable pairs (extracted from \
             theories/seqmx/experiments_seqmx.v: obsv_gram_seqmx / \
             ctrl_gram_seqmx, cite obsv_bound.obsv_gram_pd_of_observable / \
             ctrl_gram_pd_of_controllable)." );
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
      ( "description",
        `String
            "Closed loop A_cl = F - F Kf H (predicted-cov form, extracted from \
             theories/seqmx/experiments_seqmx.v closed_loop_seqmx): spectral \
             radius < 1 and ||A_cl^k||_F -> 0 (cite dare.v \
             riccati_closed_loop_identity, spec_rad.v)." );
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
      ( "description",
        `String
            "Synthetic Kalman run: the +/-sigma covariance band is the exact \
             extracted Riccati covariance (theories/seqmx/riccati_seqmx.v); the \
             trajectory and measurements use a seeded PRNG and the extracted \
             Kalman gain." );
      ("system", jsystem);
      ("steps", `List (List.rev !steps));
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
  gen_kalman_run ~kmax:39 (Filename.concat dir "kalman_run.json")
