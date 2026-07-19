# WASM extraction via CertiRocq's C backend

Compiles the same verified Kalman filter programs as `extraction/c` to
WebAssembly, running under `wasmtime`, as a second, independent execution
of the raw-matrix figure data alongside the wired, dune-native generator
in `extraction/data`.

The compiled Gallina terms are the closed `Q` instantiations from
`theories/seqmx/inst_Q.v`, the same generic seqmx programs of
`riccati.v`/`sim.v` that `extraction/c` already compiles to
native C. Only the target changes: the C(light) that CertiRocq emits is
cross-compiled with clang for `wasm32-wasi` and executed by `wasmtime`
instead of running natively. See `extraction/c/README.md` for the
CertiRocq switch setup and the value-preserving shims that make the
theory extractable at all; this directory reuses the same closed terms
unchanged and adds only the wasm32-wasi backend.

`kalman_wasm.v` defines eight entry points, `dare gramian schur run run3
orthogonality lyapunov spectral`, each producing one JSON file under
`generated/` that names the matching file under `paper/data`:
`dare_convergence.json gramian.json schur_stability.json kalman_run.json
kalman_run_3d.json orthogonality.json lyapunov.json spectral.json`. Every
file carries raw matrices only. `show_json.v` renders each `Q` leaf as a
fixed 20-digit decimal string and matrices as JSON arrays; derived visual
quantities such as eigenvalues, ellipse axes, and norms are computed by
Typst from these raw matrices, not by either driver.

## Why not CertiRocq's direct Wasm backend

CertiRocq also offers a second backend that compiles Gallina straight to
WebAssembly without an intermediate C stage, invoked through `CertiRocq
Compile Wasm`. That backend is unusable for the Kalman experiments here.
Its runtime is a bump allocator: every allocation advances a pointer
through a fixed region of linear memory, and nothing is ever reclaimed
because the backend carries no garbage collector at all. The DARE and
Lyapunov experiments in `kalman_wasm.v` iterate exact-rational Riccati and
Lyapunov steps up to 200 deep, and each step allocates fresh `Q`
numerators and denominators without bound. Under the direct Wasm backend
this exhausts the module's linear memory within a few DARE iterations,
long before reaching the 36 or 200 iterations these experiments actually
need.

The C backend used in this directory avoids the problem entirely. The
generated C is compiled and linked against CertiRocq's `gc_stack.c`, a
real generational collector with a nursery and older generations, so a
long iterative computation reclaims garbage as it runs instead of running
out of memory. This is the same collector `extraction/c` links into its
native binaries; only the compilation target differs here.

## Toolchain

This directory needs a wasm32-wasi cross-toolchain in addition to the
CertiRocq opam switch that `extraction/c`'s README documents.

- clang with the `wasm32-wasi` target enabled. This directory was built
  and verified against clang/llvm 21.
- `wasi-libc` and `wasi-compiler-rt`, the WASI C standard library and the
  runtime support library for the `wasm32-wasi` target. On Void Linux
  these are the `wasi-libc` and `wasi-compiler-rt` packages; other
  distributions ship an equivalent WASI sysroot package, or the sources
  can be built from the `wasi-libc` and `llvm-project` `compiler-rt`
  trees. The sysroot is expected at `/usr/share/wasi-sysroot`; pass
  `SYSROOT=<path>` on the `make` command line to point at a different
  location.
- A one-time builtins symlink. On this system `wasi-compiler-rt` ships
  its `wasm32-unknown-wasi` builtins archive under the llvm 22 clang
  resource directory, while the installed clang itself is llvm 21, so
  clang-21's builtins search path never finds them. Bridge the two once
  with a symlink:

  ```bash
  SRC=/usr/lib/llvm/22/lib/clang/22/lib
  DST=/usr/lib/llvm/21/lib/clang/21/lib
  sudo mkdir -p $DST
  sudo ln -sf $SRC/wasm32-unknown-wasi $DST/wasm32-unknown-wasi
  ```

  Adjust the version numbers to whatever clang and `wasi-compiler-rt`
  versions the local system actually pairs. The symlink needs to exist
  only once for every later build.
- `wasm-ld`, the WebAssembly linker shipped by the lld project. clang
  invokes it automatically for the `wasm32-wasi` target once lld is
  installed; the Makefile never calls it directly.
- `wasmtime`, version 27 or later, on `PATH` or pointed to through the
  Makefile's `WASMTIME` variable. This directory was built and verified
  against wasmtime 27.

## Build and run

Like `extraction/c`, this directory is not part of dune or CI and is
built manually:

```bash
cd extraction/wasm
make all       # build and run all eight experiments
make dare      # or build a single experiment
```

For each experiment, `make all` compiles `theories/seqmx/inst_Q.vo`,
`theories/seqmx/gramian.vo` and `theories/seqmx/closed_loop.vo` in the
CertiRocq switch, compiles
`kalman_wasm.v` with `rocq c` to obtain a CertiRocq C term and its glue
code under `generated/`, cross-compiles that C with clang into a
`wasm32-wasi` binary linked against CertiRocq's runtime sources, then runs
the binary under `wasmtime` with its standard output captured straight
into the matching JSON file under `generated/`.

`SWITCH=<path-or-name>` overrides the opam switch, matching
`extraction/c`'s convention, and defaults to
the active opam switch. `WASMTIME=<path>` overrides the
wasmtime binary if it is not on `PATH` under that name. The four iter-200
steady-state terms, `dare`, `schur`, `orthogonality`, and `lyapunov`, each
take several minutes under `wasmtime`, since the default CertiRocq erasure
pipeline implements exact `Q` arithmetic without a GMP-backed fast path;
budget on the order of fifteen to twenty minutes for the full `make all`
run.

`paper/data` itself is produced by `extraction/data`, the primary path
that dune and CI keep current: the same documents of
`extraction/common/figures.v`, instantiated on primitive `float64` and
written out by a coq-elpi command. That path rounds at every operation.
This WASM directory is the exact cross-check: it compiles the *same*
document terms at the exact rational type `Q`, through a completely
different backend and runtime, so agreement between the two confirms the
figure data independently of both the arithmetic and the pipeline.
Values agree to double-precision rounding rather than byte for byte,
since one path prints exact rationals and the other prints rounded
`float64`.

## Schur stability: `A_cl` only on this path

This directory emits only the closed-loop matrix `A_cl` for the Schur
stability experiment (`figures.v` `schur_doc`), not its powers or their
Frobenius norms. Computing `A_cl^k` exactly in rationals for `k` up to 30
is intractable: the denominators of `A_cl` are already large after 200
DARE iterations, and `wasmtime` has no GMP-backed bignum arithmetic
behind the default CertiRocq erasure pipeline. An earlier version of this
experiment that also computed the power sequence exceeded forty minutes
on that step alone.

The `float64` path has no such cost and does emit the powers and their
squared norms (`figures.v` `schur_pow_doc`), which is what the figure
reads. Cross-checking `A_cl` alone is enough: the powers are a
deterministic function of it.

## Layout

- `kalman_wasm.v`: entry points and `CertiRocq Compile` commands for all
  eight experiments;
- `../common/show_json.v`: `Q` to fixed 20-digit decimal string, matrix
  and JSON object combinators;
- `../common/figures.v`: the eight figure documents, generic in the
  coefficient type;
- `wasi_main.c`: WASI driver that calls the compiled `body` and prints
  the returned byte list to standard output;
- `Makefile`: builds every experiment through the CertiRocq switch,
  clang, and wasmtime;
- `generated/`: CertiRocq output, wasm binaries, and captured JSON;
  git-ignored.
