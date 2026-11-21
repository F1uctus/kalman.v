args@{
  lib,
  mkCoqDerivation,
  coq,
  coq-elpi,
}:
let
  source = import ../../rocq2typst-source.nix;
in
import (source + "/.nix/coq-overlays/rocq2typst/default.nix") (
  args // { version = source; }
)
