#!/bin/sh
# Регенерация paper/data/rocq2typst.json из утверждений Rocq: тонкая
# обёртка над правилом dune (см. dune в этом каталоге).
set -e
cd "$(dirname "$0")/../.." && dune build extraction/typst/rocq2typst.json
echo "rocq2typst: paper/data/rocq2typst.json"
