# C extraction via CertiRocq

Compiles the verified Kalman filter programs to C(light) with
[CertiRocq](https://github.com/CertiRocq/certirocq) **0.9.1+9.1**, in
addition to the OCaml extraction in `extraction/ocaml`.

The compiled Gallina terms are the closed `Q` instantiations from
`theories/seqmx/inst_Q.v` — the same generic seqmx programs of
`riccati.v`/`sim.v`, only the coefficient type differs:

- `q_dare_iters 36` — DARE iterations (the data of `dare_convergence.json`);
- `q_run 40` — the 2D constant-velocity run (`kalman_run.json`);
- `q_run3 sim3_seed 30` — the 3D helix run (`kalman_run_3d.json`).

All `CertiRocq Compile` commands here use the **default pipeline**, in
which every erasure pass is verified. Correctness is pinned in the main
development by `vm_compute` lemmas checked in CI: `q_run_eq_bigq` /
`q_run3_eq_bigq` / `q_dare_iters_eq_bigq` prove the compiled terms equal
(value for value, via `BigQ.to_Q`) the proven `bigQ` terms, which
satisfy the two-sigma band lemmas `sim_run_in_band` / `sim3_run_in_band`
and the refinement `riccati_iter_seqmxC`. CoqEAL remains the layer that
makes the terms executable; only the backend changes (Gallina to C
instead of Gallina to OCaml).

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
make theories-vo  # Kalman .vo in the CertiRocq switch (_build_certirocq)
make kalman       # kalman_c.v -> generated/kalman_c.c -> kalman_c_bin
make check        # run the binary, compare with paper/data JSONs
```

`SWITCH=<path-or-name>` overrides the opam switch (default:
the active opam switch).

## Layout

- `show.v` — Q/bigQ to "num/den" decimal string, string to `list byte`;
- `smoke.v` — smoke tests with `vm_compute`-pinned expected strings;
- `kalman_c.v` — entry points and `CertiRocq Compile` commands;
- `main.c` — walks the returned byte list and prints it;
- `check.py` — compares the binary output with `paper/data/*.json`
  (tolerance 1e-9) and re-checks the two-sigma band on exact fractions;
- `generated/` — CertiRocq output and binaries (git-ignored).
