// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// viz/wire.typ. Derived-math library for the figures. Loads the raw verified
// matrices emitted by the extracted drivers under paper/data/*.json and
// provides the eigenvalue, ellipse, Frobenius, spectral-radius, PD/PSD, and
// PBH functions the figures apply. Holds the former driver-side
// float math.

// Parse a JSON file at `path` into a Typst dictionary.
#let load(path) = json(bytes(read(path)))

// Zip two equal-length numeric arrays into a list of (x, y) points for
// cetz-plot.plot.add.
#let pairs(xs, ys) = xs.zip(ys).map(((x, y)) => (x, y))

// Extract a column of (x, y) points from an array of objects, by field names.
#let points(rows, xf, yf) = rows.map(r => (r.at(xf), r.at(yf)))

// Eigenvalues of a symmetric 2x2 matrix, via the trace and discriminant.
#let eig2(P) = {
  let a = P.at(0).at(0); let b = P.at(0).at(1); let c = P.at(1).at(1)
  let tr = a + c; let d = calc.sqrt(calc.pow((a - c) / 2.0, 2) + b * b)
  (tr / 2.0 + d, tr / 2.0 - d)
}

// Covariance ellipse of a symmetric PSD 2x2 matrix. The semi-axes are the
// square roots of the eigenvalues, the angle is the eigenbasis rotation.
#let ellipse2(P) = {
  let (l1, l2) = eig2(P); let a = P.at(0).at(0); let b = P.at(0).at(1)
  (a: calc.sqrt(calc.max(0.0, l1)), b: calc.sqrt(calc.max(0.0, l2)),
   angle_rad: calc.atan2(b, l1 - a).rad())
}

// Quadratic-form level-set ellipse of a symmetric PD 2x2 matrix, the set of
// x with x^T P x = 1. The semi-axes are the reciprocal square roots of the
// eigenvalues, sharing the eigenbasis angle with ellipse2.
#let qform-ellipse2(P) = {
  let (l1, l2) = eig2(P); let a = P.at(0).at(0); let b = P.at(0).at(1)
  (a: 1.0 / calc.sqrt(l1), b: 1.0 / calc.sqrt(l2), angle_rad: calc.atan2(b, l1 - a).rad())
}

// Spectrum of a general, possibly non-symmetric, 2x2 matrix. Returns two
// (re, im) pairs, allowing complex-conjugate eigenvalues.
#let eig2-general(M) = {
  let a = M.at(0).at(0); let b = M.at(0).at(1)
  let c = M.at(1).at(0); let d = M.at(1).at(1)
  let tr = a + d; let det = a * d - b * c
  let disc = calc.pow(tr / 2.0, 2) - det
  if disc < 0.0 { let im = calc.sqrt(-disc); ((tr / 2.0, im), (tr / 2.0, -im)) }
  else { let s = calc.sqrt(disc); ((tr / 2.0 + s, 0.0), (tr / 2.0 - s, 0.0)) }
}

// Spectral radius of a general 2x2 matrix, the largest eigenvalue magnitude.
#let spectral-radius(M) = {
  let ((r1, i1), (r2, i2)) = eig2-general(M)
  calc.max(calc.sqrt(r1*r1 + i1*i1), calc.sqrt(r2*r2 + i2*i2))
}

// Frobenius distance between two equal-shape matrices.
#let frob-dist(P, Q) = {
  let s = 0.0
  for i in range(P.len()) { for j in range(P.at(0).len()) {
    s += calc.pow(P.at(i).at(j) - Q.at(i).at(j), 2) } }
  calc.sqrt(s)
}

// Trace of a 2x2 matrix.
#let trace2(P) = P.at(0).at(0) + P.at(1).at(1)

// Sylvester test for positive definiteness of a symmetric 2x2 matrix.
#let pd(P) = {
  let a = P.at(0).at(0); let det = a * P.at(1).at(1) - P.at(0).at(1) * P.at(1).at(0)
  a > 0.0 and det > 0.0
}

// Nonnegative-principal-minors test for positive semidefiniteness of a
// symmetric 2x2 matrix.
#let psd(P) = {
  let a = P.at(0).at(0); let d = P.at(1).at(1)
  let det = a * d - P.at(0).at(1) * P.at(1).at(0)
  a >= 0.0 and d >= 0.0 and det >= 0.0
}

// PBH spectral mirror of estimation and control duality, for a fixed
// didactic 2x2 system. For each eigenmode, tests whether it is detectable,
// seen by the output, and stabilizable, reached by the input, then repeats
// the test on the transposed dual system. Replaces the former driver-side gen_duality,
// dl_mode, reig2, and leig2. Takes no arguments, the system is hardcoded to
// match the former driver's dl_F, dl_H, dl_G.
#let pbh-duality() = {
  let F = ((1.2, 0.0), (0.0, 0.5))   // dl_F
  let H = ((1.0, 0.0),)              // dl_H, 1x2 output
  let G = ((0.0,), (1.0,))           // dl_G, 2x1 input
  let tr(m) = range(m.at(0).len()).map(j => range(m.len()).map(i => m.at(i).at(j)))
  let mv(m, v) = m.map(row => range(v.len()).fold(0.0, (s, j) => s + row.at(j) * v.at(j)))
  let vm(v, m) = range(m.at(0).len()).map(j =>
    range(v.len()).fold(0.0, (s, i) => s + v.at(i) * m.at(i).at(j)))
  let vnorm(v) = calc.sqrt(v.map(x => x * x).sum())
  let reig(m, lam) = {
    let a = m.at(0).at(0); let b = m.at(0).at(1)
    let c = m.at(1).at(0); let d = m.at(1).at(1)
    let v1 = (b, lam - a)
    let v = if vnorm(v1) > 1e-9 { v1 } else { (d - lam, -c) }
    let n = vnorm(v); v.map(x => x / n)
  }
  let leig(m, lam) = reig(tr(m), lam)
  let mode(m, hout, gin, ev) = {
    let re = ev.at(0); let im = ev.at(1); let mag = calc.sqrt(re * re + im * im)
    let v = reig(m, re); let w = leig(m, re)
    (re: re, im: im, abs: mag, unstable: mag >= 1.0,
     detectable: vnorm(mv(hout, v)) > 1e-7, stabilizable: vnorm(vm(w, gin)) > 1e-7)
  }
  let (e1, e2) = eig2-general(F)
  let modes(m, hout, gin) = (mode(m, hout, gin, e1), mode(m, hout, gin, e2))
  (system: (F: F, H: H, G: G), primal: modes(F, H, G), dual: modes(tr(F), tr(G), tr(H)))
}
