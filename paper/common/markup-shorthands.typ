// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Single source for math/identifier shorthands used in thesis math, scope-math
// previews, and `rocq-eval` (via `dictionary(markup-shorthands)` in preamble.typ).
#let eps = math.epsilon
#let ss = "ss"
#let pss = "pss"
#let bnd = "bnd"
#let seq = "seq"
#let cl = "cl"
#let diag = "diag"
#let kalman = "kalman"
#let frob = "frob"
#let sq = "2"
#let lyap = "lyap"
#let sol = "sol"
#let Herm = "Herm"
#let hat(it) = math.accent(it, math.hat, size: 1.1em)
#let est(x) = $hat(bold(#x))$
#let tilde(it) = math.accent(it, math.tilde, size: 1.1em)
#let err(x) = $tilde(limits(bold(#x)))$

#let replace-comma-in-script(body) = {
  let f(c) = {
    if c.has("text") and c.text == "," {
      $times$
    } else if c.has("children") {
      c.children.map(f).join()
    } else if c.has("body") {
      math.lr(f(c.body))
    } else {
      c
    }
  }
  if body.has("children") {
    body.children.map(f).join()
  } else {
    f(body)
  }
}

#let show-markup-shorthands(it) = {
  show math.attach: attach => {
    if attach.has("label") and attach.label == <comma-dim-done> {
      return attach
    }
    let (base, ..atts) = attach.fields()
    if atts.t != none {
      atts.t = replace-comma-in-script(atts.t)
    }
    [#math.attach(base, ..atts)<comma-dim-done>]
  }
  it
}
