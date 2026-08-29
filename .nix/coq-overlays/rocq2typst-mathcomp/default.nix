{
  lib,
  mkCoqDerivation,
  coq,
  rocq2typst,
  mathcomp-algebra,
  version ? "0.1.0",
}:

mkCoqDerivation {
  pname = "rocq2typst-mathcomp";
  opam-name = "rocq2typst-mathcomp";
  owner = "F1uctus";
  repo = "rocq2typst";
  inherit version;
  defaultVersion = "0.1.0";
  release."0.1.0" = {
    rev = "71b4026c992defd19a428ea39905adebb5fa9730";
    sha256 = "0110zxl4xfars5dncxy8cd8fwk5gn9zby91x540akdlphrq7104m";
  };
  useDune = true;

  propagatedBuildInputs = [ rocq2typst mathcomp-algebra ];

  meta = {
    description = "Mathematical Components notation dictionary for rocq2typst";
    license = lib.licenses.gpl3Plus;
  };
}
