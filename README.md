<!---
This file was generated from `meta.yml`, please do not edit manually.
Follow the instructions on https://github.com/coq-community/templates to regenerate.
--->
# Kalman Filter

[![Nix CI][nix-action-shield]][nix-action-link]

[nix-action-shield]: https://github.com/F1uctus/kalman.v/actions/workflows/nix-action-rocq-9.3.yml/badge.svg?branch=main
[nix-action-link]: https://github.com/F1uctus/kalman.v/actions/workflows/nix-action-rocq-9.3.yml




Formalization of Kalman filter properties in Rocq using Mathematical
Components (MathComp), Infotheo, Coq Efficient Algebra Library (CoqEAL), and
proof techniques adapted from CoqQ (Coq-Quantum). The noise model and matrix
expectation operator build on Infotheo finite distributions; positive
definiteness and monotonicity lemmas adapt CoqQ Hermitian matrix algebra;
executable seqmx programs are linked to the abstract specification through
CoqEAL refinements.

## Meta

- Author(s):
  - Ilya I. Nikitin
- License: [GNU General Public License v3.0 or later](LICENSE)
- Compatible Rocq/Coq versions: Rocq 9.3 (MathComp 2.6.0)
- Additional dependencies:
  - [Dune](https://dune.build) 3.21 or later
  - [Rocq-Elpi](https://github.com/LPCIC/coq-elpi) (HB plugin backend)
  - [Hierarchy Builder](https://github.com/math-comp/hierarchy-builder) 1.10.0 or later
  - [MathComp](https://math-comp.github.io) 2.6.0 boot library
  - [MathComp](https://math-comp.github.io) 2.6.0 order library
  - [MathComp](https://math-comp.github.io) 2.6.0 fingroup library
  - [MathComp](https://math-comp.github.io) 2.6.0 field library
  - [MathComp](https://math-comp.github.io) 2.6.0 solvable library
  - [MathComp finmap](https://github.com/math-comp/finmap) library
  - [MathComp](https://math-comp.github.io) 2.6.0 algebra library
  - [Elpi](https://github.com/LPCIC/elpi) (required by Hierarchy Builder)
  - [MathComp analysis](https://github.com/math-comp/analysis) classical library
  - [MathComp analysis](https://github.com/math-comp/analysis) reals library
  - [MathComp analysis](https://github.com/math-comp/analysis) 1.19.0 or later
  - Micromega 1.1.1 or later for MathComp arithmetic and ring tactics
  - [MathComp analysis](https://github.com/math-comp/analysis) Stdlib real-number bridge
  - [Interval](https://github.com/coqinterval/interval) verified interval arithmetic
  - [Flocq](https://flocq.gitlabpages.inria.fr/) floating-point arithmetic
  - [Coquelicot](https://coquelicot.gitlabpages.inria.fr/) real analysis for Stdlib
  - [Infotheo](https://github.com/affeldt-aist/infotheo) finite distributions and expectation
  - [Bignums](https://github.com/coq-community/bignums) binary arithmetic for `bigQ` execution
  - [CoqEAL](https://github.com/coq-community/coqeal) refinements for seqmx extraction
- Rocq/Coq namespace: `Kalman`
- Related publication(s): none

## Building and installation instructions

With the desired opam switch active, install from the checkout:

```shell
git clone https://github.com/F1uctus/kalman.v.git
cd kalman.v
opam repo add rocq-released https://rocq-prover.org/opam/released
opam install --jobs=1 .
```

Infotheo 0.9.9 is available from `rocq-released`. Opam uses the
`pin-depends` entries in `kalman.opam` to fetch rocq2typst 0.2.0 from the
same tagged source used by Nix.

Building Kalman runs the verified seqmx programs inside Rocq and promotes
`paper/data/*.json` for Typst figures. Dune also installs the generated files
under `share/kalman/paper-data/`.

GitHub Actions builds Kalman on ARM64 Linux. With the
[`f1uctus` binary cache](https://f1uctus.cachix.org) configured, Nix can reuse
the published binaries for the same source revision. To build the current
checkout in the Rocq 9.3 environment, run:

```shell
nix-shell --argstr bundle rocq-9.3 --run 'dune build -p kalman -j1'
```
