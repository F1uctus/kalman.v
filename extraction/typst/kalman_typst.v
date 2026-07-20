(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  The notation layer of this project for Rocq -> Typst rendering.

  The printing engine and the dictionaries of the standard library, mathcomp,
  mathcomp-analysis, CoqEAL and infotheo come from the rocq2typst packages (the
  typst.db base, see Typst.Core). Only the clauses for this project's
  definitions are added here: definiteness and the Loewner order, the Frobenius
  norm, spectral notations, the table of named constants, the list of printed
  statements and the redefinition of the identity matrix notation. gen.v runs
  the RenderTypst command via the dune rule.
*)

From elpi Require Import elpi.
From Typst Require Export Core Mathcomp Analysis CoqEAL Infotheo.
From Kalman Require Import mxnotation mxdefinite mxherm mxloewner spectral
  mxfrob mxtopo mxmonotone riccati_def riccati_cont riccati_mono obsv_bound
  lyapunov gramian_infty detectability spec_rad dare kalman duality faddeev.
From Kalman.seqmx Require Import support inverse riccati.

Elpi Accumulate typst.db lp:{{

% the project's pp-app dictionary
% expectation argument: the lambda over the sample point is hidden
pred exp-arg i:term, o:string.
exp-arg (fun N T Bo) S :- !, coq.name->id N Nm,
  @pi-decl N T x\ (name-of x Nm :- !) => (hidden-var x :- !) =>
    pp 0 (Bo x) S.
exp-arg X S :- pp 0 X S.

% expectation  Exp μ X  ->  EE[X]; the bound sample point ω
% is hidden in the random variable indices (see hidden-var)
:before "pp-app.fallback"
pp-app _ GR Args S :- gsuf "expectation.Exp" GR, std.last Args X, !,
  exp-arg X SX, style-fmt "expectation" [SX] S.
% limit of a monotone matrix sequence  mx_mono_lim u -> lim u_k
:before "pp-app.fallback"
pp-app Ctx GR Args S :- gsuf "mx_mono_lim" GR, std.last Args Seq, !,
  ( Seq = fun N T Bo, !, coq.name->id N Nm, q Nm QNm,
    @pi-decl N T x\ ((name-of x Nm :- !) => pp 41 (Bo x) SB),
    style-fmt "limit" [QNm, SB] RAW
  ; pp 41 Seq SB, RAW is "lim " ^ SB ),
  paren Ctx 25 RAW S.
% psd M -> M succ.eq 0 ; pd M -> M succ 0   (Loewner definiteness)
:before "pp-app.fallback"
pp-app Ctx GR [_, _, M] S :- gsuf "mxdefinite.psd" GR, !,
  pp 11 M SM, style-fmt "psd" [] C, RAW is SM ^ " " ^ C, paren Ctx 10 RAW S.
:before "pp-app.fallback"
pp-app Ctx GR [_, _, M] S :- gsuf "mxdefinite.pd" GR, !,
  pp 11 M SM, style-fmt "pd" [] C, RAW is SM ^ " " ^ C, paren Ctx 10 RAW S.
% Loewner order  psd_le A B  ->  A prec.eq B
:before "pp-app.fallback"
pp-app Ctx GR [_, A, B] S :- gsuf "mxloewner.psd_le" GR, !,
  style-fmt "loewner-le" [] Op, pp-rel Ctx Op A B S.
% diagonal matrix from a family  diag l  ->  "diag"(l_1, ..., l_n)
:before "pp-app.fallback"
pp-app _ GR [_, N, L] S :- gsuf "spectral.diag" GR, !,
  pp 50 N NN, pp 50 L LL, style-fmt "op-diag" [] DN,
  S is DN ^ "(" ^ LL ^ "_1, dots.h, " ^ LL ^ "_" ^ NN ^ ")".
% embedding of a natural number into an abstract ring  cnat n  ->  n
:before "pp-app.fallback"
pp-app Ctx GR Args S :- gsuf "support.cnat" GR, std.last Args J, !,
  pp Ctx J S.
% square of the Frobenius norm  frob_sq M = tr (M† M)  ->  norm(M)_F^2
% (printed as a single symbol, without expansion into the trace form)
:before "pp-app.fallback"
pp-app Ctx GR Args S :- gsuf "mxfrob.frob_sq" GR, std.last Args M, !,
  pp 0 M SM, style-fmt "frob-sq" [SM] RAW, paren Ctx 40 RAW S.


% other extension points
% the project's negated relations
neg-rel Ctx T S :- head T GR [_, A, B], gsuf "mxloewner.psd_le" GR, !,
  style-fmt "loewner-le-not" [] Op, pp-rel Ctx Op A B S.
neg-rel Ctx T S :- head T GR [_, _, M], gsuf "mxdefinite.psd" GR, !,
  pp 11 M SM, style-fmt "psd-not" [] C,
  RAW is SM ^ " " ^ C, paren Ctx 10 RAW S.
neg-rel Ctx T S :- head T GR [_, _, M], gsuf "mxdefinite.pd" GR, !,
  pp 11 M SM, style-fmt "pd-not" [] C,
  RAW is SM ^ " " ^ C, paren Ctx 10 RAW S.

% foldable constraints on a variable
var-constraint1 T Nm C :- head T GR [_, _, X],
  gsuf "mxdefinite.psd" GR, name-of X Nm, !, style-fmt "psd" [] C.
var-constraint1 T Nm C :- head T GR [_, _, X],
  gsuf "mxdefinite.pd" GR, name-of X Nm, !, style-fmt "pd" [] C.

% structure operator heads are not expanded by structural parsing
struct-head G :- gsuf "mxdefinite.psd" G.
struct-head G :- gsuf "mxdefinite.pd" G.
struct-head G :- gsuf "mxloewner.psd_le" G.
struct-head G :- gsuf "mxfrob.frob_sq" G.

% one-sided relation in the conclusion: the definiteness sign
concl-oneside T M C :- head T GR [_, _, M], gsuf "mxdefinite.psd" GR, !,
  style-fmt "psd" [] C.
concl-oneside T M C :- head T GR [_, _, M], gsuf "mxdefinite.pd" GR, !,
  style-fmt "pd" [] C.

% the matrix under the named square of the Frobenius norm
frob-inner T M :- head T GR Args, gsuf "mxfrob.frob_sq" GR, !,
  std.last Args M.


% table of named constants
const-notation "kalman.x_true" "x" nsub 2.
const-notation "kalman.x_hat" "hat(x)" nsub 2.
const-notation "kalman.x_err" "tilde(x)" nsub 2.
const-notation "faddeev.flM" "M" nsub 1.
const-notation "faddeev.flc" "c" nsub 1.
const-notation "faddeev.fl_inv" "fl_inv" ncall 1.
const-notation "lyapunov.lyap_sol" "lyap_sol" ncall 2.
const-notation "dare.P_bnd" "P_\"bnd\"" nbare 0.
const-notation "dare.P_ss" "P_\"ss\"" nbare 0.
const-notation "dare.OP" "op(\"OP\")" nbare 0.
const-notation "dare.K_0" "K_0" nbare 0.
const-notation "dare.kf_run" "kf_run" ncall 1.
const-notation "kalman.kf_step" "kf_step" ncall 3.
const-notation "gramian_infty.ctrl_gram_infty" "W_\"c\"" nbare 0.
const-notation "riccati_def.riccati_step" "op(\"Ric\")" npartial 1.
const-notation "inverse.fl_M" "M" nsub 1.
const-notation "inverse.cinv_fl" "cinv_fl" ncall 2.
const-notation "riccati.update_cov_seqmx" "update_cov_seqmx" ncall 1.
const-notation "riccati.predict_cov_seqmx" "predict_cov_seqmx" ncall 1.


% redefinition of notations
% identity matrix with the size in the index: E_n instead of bb(1)
:before "style.default"
style "identity" "E_{}".


% list of printed statements
% the clause order sets the key order in JSON
target "dare" "def" "K_0".
target "dare" "def" "OP".
target "dare" "def" "P_bnd".
target "dare" "def" "P_ss".
target "dare" "def" "kf_run".
target "dare" "lemma" "Fp_Ppss_le".
target "dare" "lemma" "Fp_schur".
target "dare" "lemma" "Mc_schur".
target "dare" "lemma" "OP_fix".
target "dare" "lemma" "OP_psd".
target "dare" "lemma" "Pseq_bnd".
target "dare" "lemma" "Pseq_le_lyap_partial".
target "dare" "lemma" "P_ss_cvgn".
target "dare" "lemma" "P_ss_fix".
target "dare" "lemma" "P_ss_gain_cvgn".
target "dare" "lemma" "P_ss_le_fixed_gain_lyap_sol".
target "dare" "lemma" "P_ss_pd".
target "dare" "lemma" "P_ss_psd".
target "dare" "lemma" "P_ss_unique_pd".
target "dare" "lemma" "Wc_psd".
target "dare" "lemma" "cvgn_frob_sq_eps_N".
target "dare" "lemma" "dare_psd_sol".
target "dare" "lemma" "dare_stabilizing_sol".
target "dare" "lemma" "dare_stabilizing_sol_frob".
target "dare" "lemma" "filter_gain_frob_cvgn".
target "dare" "lemma" "kalman_filter_frob_cvgn".
target "dare" "lemma" "kf_cov_step".
target "dare" "lemma" "kf_run_cov".
target "dare" "lemma" "riccati_closed_loop_identity".
target "dare" "lemma" "riccati_frob_cvgn".
target "dare" "lemma" "riccati_iter_cvgn".
target "dare" "lemma" "riccati_step_le_Mc".
target "detectability" "def" "detectable".
target "detectability" "def" "detectable_stabilizing".
target "detectability" "def" "schur_stable".
target "detectability" "def" "stabilizable".
target "duality" "lemma" "ctrl_gram_dual".
target "duality" "lemma" "stabilizable_stabilizing_dual".
target "faddeev" "def" "flM".
target "faddeev" "def" "fl_inv".
target "faddeev" "lemma" "char_poly_deriv".
target "faddeev" "lemma" "fl_inv1".
target "faddeev" "lemma" "fl_inv_correct".
target "gramian_infty" "def" "ctrl_gram_infty".
target "gramian_infty" "lemma" "ctrl_gram_eq_partial".
target "gramian_infty" "lemma" "ctrl_gram_infty_fix".
target "kalman" "def" "controllable".
target "kalman" "def" "ctrl_block".
target "kalman" "def" "joseph_form".
target "kalman" "def" "kf_state".
target "kalman" "def" "observable".
target "kalman" "def" "obsv_block".
target "kalman" "def" "predict_state".
target "kalman" "def" "update_state".
target "kalman" "def" "x_err".
target "kalman" "def" "x_hat".
target "kalman" "def" "x_true".
target "kalman" "lemma" "Exp_predict_innov_zero".
target "kalman" "lemma" "alt_update_cov_diff".
target "kalman" "lemma" "filter_gain_normal_eq".
target "kalman" "lemma" "filter_gain_optimal".
target "kalman" "lemma" "innov_cov_inv".
target "kalman" "lemma" "innov_cov_pd".
target "kalman" "lemma" "joseph_formE".
target "kalman" "lemma" "kf_step_psd".
target "kalman" "lemma" "predict_cov_psd".
target "kalman" "lemma" "predict_cov_sym".
target "kalman" "lemma" "unbiased".
target "kalman" "lemma" "update_cov_inverse".
target "kalman" "lemma" "update_cov_le".
target "kalman" "lemma" "update_cov_pd".
target "kalman" "lemma" "update_cov_psd".
target "kalman" "lemma" "update_cov_sym".
target "kalman" "lemma" "update_cov_trace_le".
target "kalman" "lemma" "update_cov_unit".
target "kalman" "lemma" "x_err_recursion".
target "lyapunov" "def" "lyap_partial".
target "lyapunov" "def" "lyap_sol".
target "lyapunov" "lemma" "lyap_partial_mono".
target "lyapunov" "lemma" "lyap_partial_psd".
target "lyapunov" "lemma" "lyap_sol_cvgn".
target "lyapunov" "lemma" "lyap_sol_fix".
target "lyapunov" "lemma" "lyap_sol_psd".
target "lyapunov" "lemma" "lyap_sol_unique".
target "mxdefinite" "lemma" "pd_inv".
target "mxdefinite" "lemma" "pd_unit".
target "mxdefinite" "lemma" "psd_congr".
target "mxdefinite" "lemma" "psd_lcongr".
target "mxloewner" "def" "psd_le".
target "obsv_bound" "def" "ctrl_gram".
target "obsv_bound" "def" "obsv_gram".
target "obsv_bound" "lemma" "ctrl_gram_pd_of_controllable".
target "obsv_bound" "lemma" "ctrl_gram_shift".
target "obsv_bound" "lemma" "obsv_gram_pd_of_observable".
target "riccati_def" "def" "alt_update_cov".
target "riccati_def" "def" "filter_gain".
target "riccati_def" "def" "innov_cov".
target "riccati_def" "def" "predict_cov".
target "riccati_def" "def" "update_cov".
target "riccati_mono" "lemma" "predict_cov_mono".
target "riccati_mono" "lemma" "riccati_iter0_mono".
target "riccati_mono" "lemma" "riccati_step_mono".
target "riccati_mono" "lemma" "riccati_step_psd".
target "riccati_mono" "lemma" "update_cov_mono".
target "seqmx/inverse" "def" "cinv_fl".
target "seqmx/inverse" "lemma" "cinv_fl_correct".
target "seqmx/inverse" "lemma" "cinv_fl_correct1".
target "seqmx/riccati" "def" "riccati_step_seqmx".
target "spec_rad" "def" "spec_rad_lt1".
target "spec_rad" "lemma" "lyap_partial_le_bnd_schur".
target "spec_rad" "lemma" "schur_stable_pow_cvgn".
target "spectral" "lemma" "pd_inv_antimono".
target "spectral" "lemma" "psd_le_antisym".
target "spectral" "lemma" "spectral_decomp".

}}.
