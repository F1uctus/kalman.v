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
  bignums,
  coqeal,
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
    bignums
    coqeal
  ];

  nativeBuildInputs = with coq.ocamlPackages; [
    zarith
    yojson
  ];

  meta = {
    description = "Kalman filter implementation using Rocq, MathComp, and CoqEAL";
    license = lib.licenses.cecill-b;
  };
}
