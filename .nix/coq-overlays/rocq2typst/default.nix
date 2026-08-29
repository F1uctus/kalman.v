{
  lib,
  mkCoqDerivation,
  coq,
  coq-elpi,
  version ? "0.1.0",
}:

mkCoqDerivation {
  pname = "rocq2typst";
  opam-name = "rocq2typst";
  owner = "F1uctus";
  repo = "rocq2typst";
  inherit version;
  defaultVersion = "0.1.0";
  release."0.1.0" = {
    rev = "71b4026c992defd19a428ea39905adebb5fa9730";
    sha256 = "0110zxl4xfars5dncxy8cd8fwk5gn9zby91x540akdlphrq7104m";
  };
  useDune = true;

  propagatedBuildInputs = [ coq-elpi ];

  meta = {
    description = "Rendering of Rocq statements as Typst mathematical markup";
    license = lib.licenses.gpl3Plus;
  };
}
