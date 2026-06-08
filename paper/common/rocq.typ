#import "/paper/packages/local/textmate/0.1.0/lib.typ": to-sublime-syntax
#import "@preview/codly:1.3.0"
#import "./fonts.typ": tnr-font

#let Rocq = box(
  image("/paper/images/logo-rocq-black-text.svg"),
  height: 0.65em,
)

#let rocq-syntax = to-sublime-syntax("/paper/assets/rocq.tmLanguage.json")
#let rocq-src(p) = read("/theories/" + p)

#let rocq-badge-color = rgb("#FF540A")

// Codly language badge: show file name instead of "rocq" lang id.
#let rocq-codly-lang(file) = (
  name: file,
  icon: box(image("/paper/images/icon-rocq-orange.svg", height: 100%), inset: (
    right: 4pt,
  )),
  color: rocq-badge-color,
)

#let rocq-raw(code) = raw(
  code,
  lang: "rocq",
  syntaxes: bytes(rocq-syntax),
  theme: "/paper/assets/rocq.tmTheme",
  block: true,
)

#let rocq-raw-inline(code) = raw(
  code,
  lang: "rocq",
  syntaxes: bytes(rocq-syntax),
  theme: "/paper/assets/rocq.tmTheme",
  block: false,
)

#let rocq-codly(body, source, ..args) = {
  codly.local(
    languages: (rocq: rocq-codly-lang(source)),
    ..args,
  )[#body]
}

#let rocq-line-end = regex("\.\s*(\(\*.*\*\)\s*)?$")
#let rocq-endings = (
  Variable: rocq-line-end,
  Definition: rocq-line-end,
  Hypothesis: rocq-line-end,
  Record: regex("\}\.\s*(\(\*.*\*\)\s*)?$"),
  Notation: rocq-line-end,
  Lemma: rocq-line-end,
  Corollary: rocq-line-end,
  Theorem: regex("Qed\.\s*(\(\*.*\*\)\s*)?$"),
  Axiom: rocq-line-end,
)

// Remove the common leading whitespace prefix shared by all non-blank lines
#let rocq-leading-indent(line) = {
  let m = line.match(regex("^([ \t]+)"))
  if m != none { m.end } else { 0 }
}

#let rocq-dedent-lines(lines) = {
  let indents = lines.filter(l => l.trim() != "").map(rocq-leading-indent)
  if indents.len() == 0 {
    lines
  } else {
    let margin = calc.min(..indents)
    lines.map(l => {
      if l.trim() == "" { "" } else { l.slice(margin) }
    })
  }
}

#let rocq-standalone-comment(line) = {
  let t = line.trim()
  t.starts-with("(*") and t.ends-with("*)")
}

#let rocq-comment-start-before(lines, def-idx) = {
  let walk(i, start, in-multiline) = {
    if i < 0 {
      start
    } else {
      let line = lines.at(i)
      let t = line.trim()
      if t == "" {
        start
      } else if rocq-standalone-comment(line) {
        i
      } else if t.ends-with("*)") {
        walk(i - 1, i, true)
      } else if in-multiline {
        if t.starts-with("(*") {
          i
        } else {
          walk(i - 1, i, true)
        }
      } else {
        start
      }
    }
  }
  if def-idx == 0 { 0 } else { walk(def-idx - 1, def-idx, false) }
}

#let rocq-proof-end = regex("(Qed|Defined)\.")

#let rocq-snippet-range(lines, name, comment: false, proof: false) = {
  let from-line = lines.enumerate().find(((i, l)) => name in l)
  let def-idx = from-line.at(0)
  let start-idx = if comment {
    rocq-comment-start-before(lines, def-idx)
  } else {
    def-idx
  }
  let end = if proof {
    rocq-proof-end
  } else {
    rocq-endings.pairs().find(((s, e)) => s in from-line.at(1)).at(1)
  }
  let to-idx = (
    lines.slice(def-idx).enumerate().find(((idx, line)) => end in line).at(0)
      + def-idx
  )
  (start: start-idx, end: to-idx)
}

#let rocq-render-range(source, lines, start, end) = {
  let snippet = rocq-dedent-lines(lines.slice(start, end + 1))
  rocq-codly(
    rocq-raw(snippet.join("\n")),
    source,
    offset: start,
    display-icon: false,
  )
}

#let rocq-snippet(source, name, comment: false, proof: false) = {
  let lines = rocq-src(source).split("\n")
  let range = rocq-snippet-range(lines, name, comment: comment, proof: proof)
  rocq-render-range(source, lines, range.start, range.end)
}


#let rocq-decl-kinds = (
  "Theorem",
  "Lemma",
  "Corollary",
  "Definition",
  "Notation",
  "Record",
  "Variable",
  "Hypothesis",
  "Fixpoint",
  "Inductive",
  "Axiom",
)

#let rocq-locate(lines, name) = {
  let decl-re = regex(
    "^\\s*(" + rocq-decl-kinds.join("|") + ")\\s+" + name + "\\b",
  )
  let hit = lines.enumerate().find(((i, l)) => l.match(decl-re) != none)
  if hit == none { panic("rocq-doc: no declaration `" + name + "`") }
  (idx: hit.at(0), kind: hit.at(1).match(decl-re).captures.at(0))
}

#let rocq-statement-range(lines, idx, kind) = {
  let end = if kind == "Record" { rocq-endings.Record } else { rocq-line-end }
  let to-idx = (
    lines.slice(idx).enumerate().find(((i, l)) => end in l).at(0) + idx
  )
  (start: idx, end: to-idx)
}

#let rocq-proof-start = regex("^\\s*Proof\\.")

#let rocq-proofbody-range(lines, idx) = {
  let p = lines.slice(idx).enumerate().find(((i, l)) => rocq-proof-start in l)
  if p == none { return none }
  let proof-idx = p.at(0) + idx
  let e = lines
    .slice(proof-idx)
    .enumerate()
    .find(((i, l)) => rocq-proof-end in l)
  if e == none { return none }
  (start: proof-idx, end: e.at(0) + proof-idx)
}

#let rocq-comment-above(lines, idx) = {
  let c-end = idx
  while c-end > 0 and lines.at(c-end - 1).trim() == "" { c-end -= 1 }
  if c-end == 0 or not lines.at(c-end - 1).trim().ends-with("*)") {
    return none
  }
  if lines.at(c-end - 1).trim().starts-with("(*") {
    return (start: c-end - 1, end: c-end)
  }
  let i = c-end - 1
  while i >= 0 and not lines.at(i).trim().starts-with("(*") { i -= 1 }
  if i < 0 { none } else { (start: i, end: c-end) }
}

#let rocq-trim-blank-edges(ls) = {
  let a = ls
  while a.len() > 0 and a.first().trim() == "" { a = a.slice(1) }
  while a.len() > 0 and a.last().trim() == "" { a = a.slice(0, a.len() - 1) }
  a
}

#let rocq-comment-text(lines, span) = {
  let raw = lines.slice(span.start, span.end).join("\n").trim()
  if raw.starts-with("(*") { raw = raw.slice(2) }
  if raw.ends-with("*)") { raw = raw.slice(0, raw.len() - 2) }
  rocq-trim-blank-edges(rocq-dedent-lines(raw.split("\n")))
}

#let rocq-split-paragraphs(ls) = {
  let paras = ()
  let cur = ()
  for l in ls {
    if l.trim() == "" {
      if cur.len() > 0 {
        paras.push(cur)
        cur = ()
      }
    } else {
      cur.push(l)
    }
  }
  if cur.len() > 0 { paras.push(cur) }
  paras
}

#let rocq-citation-line = regex("^\\s*-\\s*@[a-zA-Z0-9_]+\\[")

#let rocq-doc-comment(lines, idx) = {
  let span = rocq-comment-above(lines, idx)
  if span == none { return (title: "", description: "") }
  let body = rocq-comment-text(lines, span)
  let paras = rocq-split-paragraphs(body)
  if paras.len() > 0 and rocq-citation-line in paras.last().first() {
    paras = paras.slice(0, paras.len() - 1)
  }
  let title = if paras.len() > 0 {
    paras.first().map(l => l.trim()).join(" ")
  } else { "" }
  let description = if paras.len() > 1 {
    paras.slice(1).map(p => p.join("\n")).join("\n\n")
  } else { "" }
  (title: title, description: description)
}

#let rocq-sketch-prefix = regex(
  "(?i)^\\s*схема(\\s+доказательства)?\\s*[:.]?\\s*",
)

#let rocq-proof-sketch(lines, idx, kind) = {
  let stmt = rocq-statement-range(lines, idx, kind)
  let p = lines
    .slice(stmt.end + 1)
    .enumerate()
    .find(((i, l)) => rocq-proof-start in l)
  if p == none { return none }
  let proof-idx = p.at(0) + stmt.end + 1
  let span = rocq-comment-above(lines, proof-idx)
  if span == none or span.start <= stmt.end { return none }
  let text = rocq-comment-text(lines, span).join("\n")
  text.replace(rocq-sketch-prefix, "")
}

#show raw: set text(font: tnr-font)
