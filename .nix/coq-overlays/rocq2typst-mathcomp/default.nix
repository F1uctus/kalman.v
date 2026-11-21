args@{
  lib,
  mkCoqDerivation,
  coq,
  rocq2typst,
  mathcomp-algebra,
  mathcomp-fingroup,
}:
let
  source = import ../../rocq2typst-source.nix;
in
import (source + "/.nix/coq-overlays/rocq2typst-mathcomp/default.nix") (
  args // { version = source; }
)
