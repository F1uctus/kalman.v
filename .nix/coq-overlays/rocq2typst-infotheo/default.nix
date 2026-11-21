args@{
  lib,
  mkCoqDerivation,
  coq,
  rocq2typst,
  mathcomp-infotheo,
  micromega-plugin,
}:
let
  source = import ../../rocq2typst-source.nix;
in
import (source + "/.nix/coq-overlays/rocq2typst-infotheo/default.nix") (
  args // { version = source; }
)
