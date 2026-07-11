{
  lib,
  mkCoqDerivation,
  coq,
  rocq2typst,
  mathcomp-infotheo,
  version ? "0.1.0",
}:

mkCoqDerivation {
  pname = "rocq2typst-infotheo";
  opam-name = "rocq2typst-infotheo";
  owner = "F1uctus";
  repo = "rocq2typst";
  inherit version;
  defaultVersion = "0.1.0";
  release."0.1.0" = {
    rev = "ad99f4e3610030283e984bc48b73e51b7648c9dd";
    sha256 = "1gphvn6f756q24jipvfrmp3yz1dlc2gras29j02hgjada7hvg44q";
  };
  useDune = true;

  propagatedBuildInputs = [ rocq2typst mathcomp-infotheo ];

  meta = {
    description = "Infotheo notation dictionary for rocq2typst";
    license = lib.licenses.gpl3Plus;
  };
}
