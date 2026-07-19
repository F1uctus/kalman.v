# C extraction via CertiRocq

Compiles the verified Kalman filter programs to C(light) with
[CertiRocq](https://github.com/CertiRocq/certirocq) **0.9.1+9.1**, in
addition to the dune-native figure-data generator in `extraction/data`.

The compiled Gallina terms are the eight figure documents of
`extraction/common/figures.v`, instantiated at the exact rational type
`Q` in `extraction/common/figures_Q.v` — the same documents the
dune-native generator instantiates at `float64`, and the same ones
`extraction/wasm` compiles. `kalman_c.v` therefore holds nothing but
`CertiRocq Compile` commands: the JSON printing is defined once, in
`figures.v`, so no output format lives in this directory.

Each experiment builds its own binary and writes the file that
`paper/data` would hold, so the two paths can be compared directly.
Values agree to double-precision rounding rather than byte for byte,
since this path prints exact rationals and the dune path prints rounded
`float64`.

All `CertiRocq Compile` commands here use the **default pipeline**, in
which every erasure pass is verified. Correctness is pinned in the main
development by `vm_compute` lemmas checked in CI: `q_run_eq_bigq` /
`q_run3_eq_bigq` / `q_dare_iters_eq_bigq` prove the compiled terms equal
(value for value, via `BigQ.to_Q`) the proven `bigQ` terms, which
satisfy the two-sigma band lemmas `sim_run_in_band` / `sim3_run_in_band`
and the refinement `riccati_iter_seqmxC`. CoqEAL remains the layer that
makes the terms executable; only the backend changes (Gallina to C
instead of the `vm_compute` used inside `dune`).

## Theory is compiled as is — no extraction-side shims

The runtime closure of the theory contains no opaque proofs of
computational sort, so CertiRocq accepts the literally-proven programs.
This took three source-level choices (all value-preserving, proven so):

- `iscalar_seqmx`/`iseqmx1` (`support.v`) build scalar matrices by
  `iota`/`eqn` instead of CoqEAL's `mkseqmx_ord` ordinal enumeration,
  whose `insub_eq`/`idP` path is opaque `reflect` (Set-sorted, so not
  erasable, and Qed bodies are invisible to MetaRocq quoting);
- `val4` (`sim.v`) compares outcomes with `Nat.ltb`: mathcomp's
  `ltn` unfolds to `eq_op` on the nat eqType structure with opaque
  `eqnP` (bridge lemma `ltb_ltn`);
- dimension literals of `@hmul_op` carry `%N`: under `ring_scope` they
  would elaborate as `2%:R` in nat's semiring structure, pulling the
  bundled nat algebra (with `eqnP` and choice mixins) into the term.

## Why Q and not bigQ

Two CertiRocq 0.9.1 limitations block the `bigQ` instantiation:

1. The default pipeline does not translate coinductive types — and
   silently emits C that calls an erased term as a closure, segfaulting
   at startup. Bignums memoizes the BigN operation tower through
   Stdlib's `StreamMemo` (`make_op_list` in `NMake_gen.v`), a top-level
   coinductive stream, so any program touching `bigQ` crashes (minimal
   reproducers: any `CoFixpoint` stream, or `BigN.eqb 147 0`).
2. Since upstream PR #98 the `-unsafe-erasure` option enables MetaRocq's
   cofixpoint-to-fixpoint translation (the one erasure pass not yet
   verified, per upstream PR #152) with lazy/force compiled to thunks.
   This is correct — `make smoke` includes a `bigQ` case compiled this
   way — but the thunks are naive (non-memoizing), and the compiled
   Kalman/DARE arithmetic over `bigQ` slows down about two orders of
   magnitude per DARE iteration (5 iterations 0.01 s, 6 iterations
   1.9 s, 7 iterations over 90 s), while the identical program over `Q`
   finishes all 109 checked rows in about half a minute. Value sizes
   are small (9-27 digits) and isolated bigQ arithmetic is fast, so the
   blowup is recomputation inside the lazily-translated Bignums closure.

## Toolchain (separate opam switch)

CertiRocq needs OCaml 4.14.3 (CompCert 3.17), while the project switch
runs OCaml 5.4.1, so this directory builds against the local switch of
a dedicated opam switch. To create it:

```bash
opam switch create <dir> ocaml-base-compiler.4.14.3
opam repo add rocq-released https://rocq-prover.org/opam/released
opam install rocq-certirocq rocq-bignums
# mathcomp 2.5 stack on top; coq-wasm 2.2.0 caps mathcomp at 2.4,
# the override is required and coq-wasm is rebuilt against 2.5:
opam install --ignore-constraints-on coq-mathcomp-ssreflect,rocq-mathcomp-ssreflect \
  dune rocq-elpi rocq-hierarchy-builder \
  rocq-mathcomp-boot.2.5.0 rocq-mathcomp-order.2.5.0 rocq-mathcomp-fingroup.2.5.0 \
  rocq-mathcomp-algebra.2.5.0 rocq-mathcomp-field.2.5.0 rocq-mathcomp-solvable.2.5.0 \
  rocq-mathcomp-finmap rocq-mathcomp-classical rocq-mathcomp-reals \
  rocq-mathcomp-analysis coq-mathcomp-zify coq-mathcomp-algebra-tactics \
  rocq-mathcomp-reals-stdlib coq-infotheo coq-coqeal coq-interval coq-flocq coq-coquelicot
```

Do not run `opam upgrade` in that switch: the constraint override is
not remembered, an upgrade would roll mathcomp back to 2.4.

Requires `clang` (the generated C is compiled with `-Wno-everything`).

## Build and run

This directory is not part of dune or CI; it is built manually:

```bash
make smoke        # gates: Q arithmetic (default pipeline) and bigQ
                  # arithmetic (-unsafe-erasure), byte-compared with
                  # vm_compute-pinned Examples in smoke.v
make vo           # Kalman and KalmanShow .vo in the CertiRocq switch
make compile      # kalman_c.v -> generated/*.c for all eight experiments
make spectral     # build and run one experiment -> generated/spectral.json
make all          # build and run all eight experiments
```

The four iter-200 steady-state terms, `dare`, `schur`, `orthogonality`
and `lyapunov`, are the slow ones: the default CertiRocq erasure
pipeline implements exact `Q` arithmetic with no GMP-backed fast path.
The cheap experiments are `spectral`, `gramian`, `run` and `run3`.

`SWITCH=<path-or-name>` overrides the opam switch (default:
the active opam switch).

## Layout

- `show.v` — Q/bigQ to "num/den" decimal string, string to `list byte`;
- `smoke.v` — smoke tests with `vm_compute`-pinned expected strings;
- `kalman_c.v` — `CertiRocq Compile` commands only;
- `../common/figures.v`, `../common/figures_Q.v` — the eight documents
  and their `Q` instantiation, shared with `extraction/wasm`;
- `main.c` — walks the returned byte list and prints it;
- `generated/` — CertiRocq output, binaries and JSON (git-ignored).
