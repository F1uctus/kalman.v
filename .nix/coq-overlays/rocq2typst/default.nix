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
    rev = "ad99f4e3610030283e984bc48b73e51b7648c9dd";
    sha256 = "1gphvn6f756q24jipvfrmp3yz1dlc2gras29j02hgjada7hvg44q";
  };
  useDune = true;

  propagatedBuildInputs = [ coq-elpi ];

  meta = {
    description = "Rendering of Rocq statements as Typst mathematical markup";
    license = lib.licenses.gpl3Plus;
  };
}
