# Extraction of the Kalman filtering algorithms to OCaml

This directory extracts the proven `theories/seqmx` program layer to
self-contained OCaml code. It is split by three concerns:

- `riccati_extract.v` produces `riccati.ml`, a library of building blocks
  generic over the coefficient ring (the DARE step and half-steps, the gain,
  the gramians, the closed-loop matrix, and the filter run). The library
  `kalman_filter` checks that the module compiles as self-contained OCaml code
  with no external dependencies.
- `figures/` instantiates the same generic layer at the `float` ring and
  assembles the JSON figure documents for `paper/viz`.

## Genericity over the ring

The extracted programs take the CoqEAL ring operations as separate arguments:
`zero`, `one`, `opp`, `add`, `mul`, `inv`. They are supplied by the project that
links the library. For example, the DARE step over `float` numbers:

```ocaml
let step =
  Riccati.riccati_step_seqmx
    (fun x -> x)                    (* conjugation: the identity on reals *)
    1 2 1                           (* dimensions p n m *)
    f g h q r
    (Riccati.cinv_fl 0. 1. (~-.) (+.) ( *. ) (fun x -> 1. /. x) 1)
```

Instantiating with exact rationals (for example zarith `Q.t`) makes the programs
the same term for which the refinement of the specification is proven
(`inst_bigQ.riccati_iter_seqmxC`). Instantiating with `float` does not carry the
refinement: floating point numbers round, so the structure of the recursion
holds while the numeric result does not.

## Build

```sh
dune build extraction/ocaml                    # the kalman_filter library (riccati.ml)
dune build @extraction/ocaml/figures/paper_data  # the JSON documents in paper/data
```

The `extraction/c` directory takes the same documents, instantiated at the
exact rational type `Q` in `extraction/common/figures_Q.v` and at `float64` in
`extraction/common/figures_F64.v`, and compiles them through CertiRocq.
