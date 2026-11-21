args@{
  lib,
  mkCoqDerivation,
  coq,
  rocq2typst-mathcomp,
  coqeal,
}:
let
  source = import ../../rocq2typst-source.nix;
in
import (source + "/.nix/coq-overlays/rocq2typst-coqeal/default.nix") (
  args // { version = source; }
)
