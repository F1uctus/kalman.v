// viz/plotdata.typ — load experiment JSON emitted by extraction/ocaml/driver.exe.
//
// Mirrors the read()/json() idiom already used in common/rocq.typ. Paths are
// absolute from the project root, e.g. "/paper/data/dare_convergence.json".

#let dare-convergence-path = "/paper/data/dare_convergence.json"
#let orthogonality-path = "/paper/data/orthogonality.json"
#let lyapunov-path = "/paper/data/lyapunov.json"
#let spectral-path = "/paper/data/spectral.json"

// Parse a JSON file at `path` into a Typst dictionary.
#let load(path) = json(bytes(read(path)))

// Zip two equal-length numeric arrays into a list of (x, y) points for
// cetz-plot.plot.add.
#let pairs(xs, ys) = xs.zip(ys).map(((x, y)) => (x, y))

// Extract a column of (x, y) points from an array of objects, by field names.
#let points(rows, x-field, y-field) = rows.map(r => (r.at(x-field), r.at(y-field)))
