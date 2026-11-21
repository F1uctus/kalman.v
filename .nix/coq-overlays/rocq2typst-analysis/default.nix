args@{
  lib,
  mkCoqDerivation,
  coq,
  rocq2typst-mathcomp,
  mathcomp-analysis,
  micromega-plugin,
}:
let
  source = import ../../rocq2typst-source.nix;
in
import (source + "/.nix/coq-overlays/rocq2typst-analysis/default.nix") (
  args // { version = source; }
)
