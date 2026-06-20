<!---
This file was generated from `meta.yml`, please do not edit manually.
Follow the instructions on https://github.com/coq-community/templates to regenerate.
--->
# Kalman Filter

[![Nix CI][nix-action-shield]][nix-action-link]

[nix-action-shield]: https://github.com/F1uctus/kalman.v/actions/workflows/nix-action-rocq-9.1.yml/badge.svg?branch=main
[nix-action-link]: https://github.com/F1uctus/kalman.v/actions/workflows/nix-action-rocq-9.1.yml




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
- Compatible Rocq/Coq versions: Rocq 9.0 - 9.1 (MathComp 2.5.0)
- Additional dependencies:
  - [Dune](https://dune.build) 3.21 or later
  - [Rocq-Elpi](https://github.com/LPCIC/coq-elpi) (HB plugin backend)
  - [Hierarchy Builder](https://github.com/math-comp/hierarchy-builder) 1.9.0 or later
  - [MathComp](https://math-comp.github.io) 2.5.0 boot library
  - [MathComp](https://math-comp.github.io) 2.5.0 order library
  - [MathComp](https://math-comp.github.io) 2.5.0 fingroup library
  - [MathComp](https://math-comp.github.io) 2.5.0 field library
  - [MathComp](https://math-comp.github.io) 2.5.0 solvable library
  - [MathComp finmap](https://github.com/math-comp/finmap) library
  - [MathComp](https://math-comp.github.io) 2.5.0 algebra library
  - [Elpi](https://github.com/LPCIC/elpi) (required by Hierarchy Builder)
  - [MathComp analysis](https://github.com/math-comp/analysis) classical library
  - [MathComp analysis](https://github.com/math-comp/analysis) reals library
  - [MathComp analysis](https://github.com/math-comp/analysis) 1.16.0 or later
  - [MathComp zify](https://github.com/math-comp/zify) micromega tactics for MathComp
  - [Infotheo](https://github.com/affeldt-aist/infotheo) finite distributions and expectation
  - [Bignums](https://github.com/coq-community/bignums) binary arithmetic for `bigQ` execution
  - [CoqEAL](https://github.com/coq-community/coqeal) refinements for seqmx extraction
- Rocq/Coq namespace: `Kalman`
- Related publication(s): none

## Building and installation instructions

To build and install manually, you need to make sure that all the
libraries this development depends on are installed.  The easiest way to do that
is still to rely on opam:

``` shell
git clone https://github.com/F1uctus/kalman.v.git
cd kalman.v
opam repo add rocq-released https://rocq-prover.org/opam/released
opam install --deps-only .
dune build
dune install
```



