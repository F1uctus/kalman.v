

Set Warnings "-notation-overridden,-coercions,-default".

From Kalman Require Import kalman obsv_bound lyapunov gramian_infty.
From Kalman Require Import spec_rad detectability lyap_inv riccati_unique dare.

Definition kailath_parity_refs :=
  ( kalman.riccati_step,
    @dare.dare_stabilizing_sol,
    @dare.Pss_unique_pd,
    @riccati_unique.riccati_step_fix_unique,
    @dare.riccati_iter_cvgn,
    @dare.riccati_frob_cvgn,
    @dare.kalman_gain_frob_cvgn,
    @dare.dare_stabilizing_sol_frob,
    @dare.kalman_filter_frob_cvgn,
    @dare.kf_run,
    @dare.kf_run_cov,
    @dare.riccati_closed_loop_identity,
    @dare.Fp_schur,
    @dare.Fp_Ppss_le,
    @dare.OP,
    @dare.OP_fix,
    @lyap_inv.lyap_inversion,
    @lyap_inv.lyap_inv_spec_rad,
    @spec_rad.spec_rad_lt1,
    @spec_rad.frob_sq_contract_spec_rad_lt1,
    @spec_rad.schur_stable_pow_cvgn,
    @lyapunov.lyap_sol,
    @lyapunov.lyap_sol_unique,
    @spec_rad.lyap_sol_fix_schur,
    @spec_rad.lyap_two_sided_zero_schur,
    @obsv_bound.obsv_gram,
    @gramian_infty.ctrl_gram_infty,
    @gramian_infty.obsv_gram_infty,
    @gramian_infty.ctrl_gram_infty_pd_of_controllable,
    @gramian_infty.obsv_gram_infty_pd_of_observable,
    @gramian_infty.controllable_oi_gram_pd,
    @dare.riccati_iter_le_lyap_partial,
    @dare.Pss_le_fixed_gain_lyap_sol,
    @spec_rad.lyap_partial_le_sol_schur,
    @detectability.detectable,
    @detectability.stabilizable,
    @detectability.unit_circle_controllable,
    @detectability.pole_placement_detect,
    @detectability.detectable_stabilizing_filter ).
