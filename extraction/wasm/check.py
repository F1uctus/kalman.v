#!/usr/bin/env python3
"""Numeric parity: WASM generated/*.json vs the OCaml driver's paper/data/*.json.
Both drivers emit the same raw-matrix schema; every numeric leaf must agree."""
import json, sys

def close(a, b, t=1e-9):
    if isinstance(a, dict) and isinstance(b, dict):
        return a.keys() == b.keys() and all(close(a[k], b[k], t) for k in a)
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(close(x, y, t) for x, y in zip(a, b))
    if a is None or b is None:
        return a == b
    if isinstance(a, str) or isinstance(b, str):
        return a == b
    return abs(a - b) <= t * (1 + abs(b))

def main(wasm_dir, data_dir):
    files = ["dare_convergence.json", "gramian.json", "schur_stability.json",
             "kalman_run.json", "kalman_run_3d.json", "orthogonality.json",
             "lyapunov.json", "spectral.json"]
    good = True
    for f in files:
        w = json.load(open(f"{wasm_dir}/{f}"))
        o = json.load(open(f"{data_dir}/{f}"))
        ok = close(w, o)
        good &= ok
        print(f"{'OK ' if ok else 'FAIL'} {f}")
    print("PARITY OK" if good else "PARITY FAILED")
    sys.exit(0 if good else 1)

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "generated",
         sys.argv[2] if len(sys.argv) > 2 else "../../paper/data")
