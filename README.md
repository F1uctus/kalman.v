<!---
This file was generated from `meta.yml`, please do not edit manually.
Follow the instructions on https://github.com/coq-community/templates to regenerate.
--->
# Kalman filter and it's properties

[![Docker CI][docker-action-shield]][docker-action-link]

[docker-action-shield]: https://github.com/F1uctus/kalman.v/actions/workflows/docker-action.yml/badge.svg?branch=main
[docker-action-link]: https://github.com/F1uctus/kalman.v/actions/workflows/docker-action.yml




Formalization of Kalman filter properties using the Mathematical Components
library and it's extraction using CoqEAL and refinements.

## Meta

- Author(s):
  - Ilya I. Nikitin
- License: [CeCILL-B](LICENSE)
- Compatible Rocq/Coq versions: Rocq 9.0 - 9.1 (MathComp 2.5.0; 9.2 pending math-comp release)
- Additional dependencies:
  - [Dune](https://dune.build) 3.21+
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
  - [Bignums](https://github.com/coq-community/bignums) binary arithmetic for `bigQ` execution in `riccati_seqmx`
  - [Dune](https://dune.build) 3.6 or later
- Rocq/Coq namespace: `Kalman`
- Related publication(s): none

## Building and installation instructions

The easiest way to install the latest released version of Kalman filter and it's properties
is via [OPAM](https://opam.ocaml.org/doc/Install.html):

```shell
opam repo add rocq-released https://rocq-prover.org/opam/released
opam install kalman
```

To instead build and install manually, you need to make sure that all the
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



