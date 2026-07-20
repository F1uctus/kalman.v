#!/bin/sh
# Regenerate paper/data/rocq2typst.json from the Rocq statements: a thin
# wrapper over the dune rule (see dune in this directory).
set -e
cd "$(dirname "$0")/../.." && dune build extraction/typst/rocq2typst.json
echo "rocq2typst: paper/data/rocq2typst.json"
