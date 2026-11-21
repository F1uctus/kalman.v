{
  lib,
  mkCoqDerivation,
  coq,
  hierarchy-builder,
  coq-elpi,
  mathcomp-field,
  mathcomp-fingroup,
  mathcomp-order,
  mathcomp-solvable,
  mathcomp-finmap,
  mathcomp-classical,
  mathcomp-reals,
  mathcomp-analysis,
  mathcomp-reals-stdlib,
  mathcomp-infotheo,
  micromega-plugin,
  bignums,
  coqeal,
  rocq2typst,
  rocq2typst-mathcomp,
  rocq2typst-analysis,
  rocq2typst-coqeal,
  rocq2typst-infotheo,
  version ? ../../../.,
}:

mkCoqDerivation {
  pname = "kalman";
  opam-name = "kalman";
  inherit version;
  useDune = true;

  propagatedBuildInputs = [
    hierarchy-builder
    coq-elpi
    mathcomp-field
    mathcomp-fingroup
    mathcomp-order
    mathcomp-solvable
    mathcomp-finmap
    mathcomp-classical
    mathcomp-reals
    mathcomp-analysis
    mathcomp-reals-stdlib
    mathcomp-infotheo
    micromega-plugin
    bignums
    coqeal
    rocq2typst
    rocq2typst-mathcomp
    rocq2typst-analysis
    rocq2typst-coqeal
    rocq2typst-infotheo
  ];

  meta = {
    description = "Kalman filter implementation using Rocq, MathComp, and CoqEAL";
    license = lib.licenses.gpl3Plus;
  };

}
