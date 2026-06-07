
#let dare-convergence-path = "/paper/data/dare_convergence.json"
#let orthogonality-path = "/paper/data/orthogonality.json"
#let lyapunov-path = "/paper/data/lyapunov.json"
#let spectral-path = "/paper/data/spectral.json"

#let load(path) = json(bytes(read(path)))

#let pairs(xs, ys) = xs.zip(ys).map(((x, y)) => (x, y))

#let points(rows, x-field, y-field) = rows.map(r => (r.at(x-field), r.at(y-field)))
