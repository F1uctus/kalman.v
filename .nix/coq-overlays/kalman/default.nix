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
  mathcomp-infotheo,
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
    mathcomp-infotheo
    bignums
    coqeal
  ];

  nativeBuildInputs = with coq.ocamlPackages; [
    zarith
    yojson
  ];

  meta = {
    description = "Kalman filter implementation using Rocq, MathComp, and CoqEAL";
    license = lib.licenses.gpl3Plus;
  };

  # `dune build -p kalman` promotes figure JSON into paper/data/; ship them so
  # CI can copy from the Cachix-cached derivation instead of rebuilding.
  postInstall = ''
    if ls paper/data/*.json >/dev/null 2>&1; then
      mkdir -p "$out/share/kalman/paper-data"
      cp paper/data/*.json "$out/share/kalman/paper-data/"
    fi
  '';
}
