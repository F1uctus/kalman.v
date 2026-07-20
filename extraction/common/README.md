# Shared figure documents and printing

The JSON figure documents and the printing helpers that both extraction
paths (`../ocaml` for OCaml, `../c` for CertiRocq) share.

## The documents (`figures.v`)

`figures.v` is a section parameterized by the coefficient ring `C` (a CoqEAL
operation dictionary) and by a coefficient printer `jnm : C -> string`. It
assembles the documents from the same generic programs that provably
refine the specification: the half-steps and the Riccati step from `riccati.v`,
the gramians from `gramian.v`, the closed-loop matrix from `closed_loop.v` and
the runs from `sim.v`.

Only raw matrices are output. The derived quantities of a figure (eigenvalues,
ellipses, Frobenius norms, spectral radius) are computed on the Typst side in
`paper/viz/wire.typ`.

Schur stability comes in two forms. `schur_doc` outputs only the closed-loop
matrix `A_cl` and works on any coefficient type. `schur_pow_doc` adds the powers
`A_cl^k` and the squares of their Frobenius norms; it needs constant time
arithmetic, since over exact rationals the denominators of `A_cl` after two
hundred DARE iterations make raising to the thirtieth power infeasible.

## Instantiations

The same documents are instantiated at two rings, both consumed by `../c`:

- `figures_Q.v` at the exact rationals `Q`: verified numerics, `schur_doc` only.
  The values coincide with the proven `bigQ` terms (`riccati_iter_seqmxC` and
  the band lemmas), so this side is the verified counterpart.
- `figures_F64.v` at primitive `float64`: unverified numerics (instantiation at
  float is not a refinement, see `theories/seqmx/inst_Float64.v`), `schur_pow_doc`,
  the same values the OCaml generator in `../ocaml/figures` produces. A `float64`
  value is turned into an exact rational through `Prim2SF` (sign, mantissa,
  binary exponent), which is exact since a finite double is a rational with a
  power-of-two denominator, then printed with the same `q_dec` decimal notation.

The OCaml path keeps `figures.v` generic and supplies the ring and printer at
runtime instead of instantiating in Rocq; see `../ocaml`.

## Printing (`show.v`, `show_json.v`)

`show.v` prints rationals as `num/den` and turns a string into a byte list for
the C driver. `show_json.v` prints a `Q` value as a decimal with twenty
truncated fractional digits (`q_dec`), enough to recover a double exactly when
read in Typst, and assembles arrays and objects by string combinators. Printing
a matrix is built from the coefficient printer in `figures.v`, so it does not
depend on the coefficient type.
