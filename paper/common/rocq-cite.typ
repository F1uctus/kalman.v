#import "@local/djvu:0.1.0": djvu-pages, djvu-find
#import "rocq.typ": rocq-src, rocq-comment-start-before, rocq-decl-kinds

#let rocq-stems = (
  "dare", "detectability", "duality", "expectation", "gramian_infty", "kalman",
  "lyap_inv", "lyapunov", "mxdefinite", "mxfrob", "mxherm", "mxhermform",
  "mxloewner", "mxmonotone", "mxnotation", "mxtopo", "obsv_bound",
  "riccati_cont", "riccati_mono", "riccati_seqmx", "riccati_unique",
  "spec_rad", "spectral",
)

#let rocq-target(t) = {
  let dot = t.position(".")
  if dot == none { false } else {
    rocq-stems.contains(t.slice(0, dot))
  }
}

#let book-sources = (
  kailath2000: (
    path: "/references/Kailath T., Sayed A., Hassibi B. - Linear Estimation.djvu",
    front-skip: 25,
    folio: idx => idx - (if idx >= 748 { 23 } else { 25 }),
  ),
)

#let book-pages(key) = djvu-pages(read(book-sources.at(key).path, encoding: none))

#let resolve-page(source) = {
  if source.anchor == none or source.quoted == none { return none }
  if not book-sources.keys().contains(source.key) { return none }
  let book = book-sources.at(source.key)
  let pages = book-pages(source.key)
  let hit = djvu-find(pages.slice(book.front-skip), source.anchor, source.quoted)
  if hit == none { none } else { (book.folio)(book.front-skip + hit) }
}

#let citation-ref-re = regex(
  "@([a-zA-Z0-9_]+)\\[((?:[^\\[\\]]|\\[[^\\[\\]]*\\])*)\\]",
)
#let number-re = regex("[A-Z]?\\.?\\d+(\\.\\d+)*")
#let kind-number-re = regex(
  "(Theorem|Lemma|Corollary|Proposition|Fact|Equation|Eq\\.?|Definition|Def\\.?)"
    + "\\s+[A-Z]?\\.?\\d+(\\.\\d+)*",
)

#let parse-source(key, supplement) = {
  let locator = supplement.trim()
  let q-open = locator.position("\"")
  let quoted = if q-open != none {
    let rest = locator.slice(q-open + 1, none)
    let q-close = rest.position("\"")
    if q-close == none { none } else { rest.slice(0, q-close) }
  } else {
    none
  }
  let head = if q-open != none { locator.slice(0, q-open) } else { locator }
  let km = head.match(kind-number-re)
  let anchor = if km != none {
    km.text
  } else {
    let nums = head.matches(number-re)
    if nums.len() == 0 { none } else { nums.last().text }
  }
  (key: key, locator: locator, anchor: anchor, quoted: quoted)
}

#let parse-citations(comment) = {
  comment
    .matches(citation-ref-re)
    .map(m => parse-source(m.captures.at(0), m.captures.at(1)))
}

#let rocq-cite-data-opt(module, name) = {
  let lines = rocq-src(module + ".v").split("\n")
  let decl-re = regex(
    "^\\s*(" + rocq-decl-kinds.join("|") + ")\\s+" + name + "\\b",
  )
  let hit = lines.enumerate().find(((i, l)) => l.match(decl-re) != none)
  if hit == none {
    panic("rocq-cite: no declaration `" + name + "` in " + module + ".v")
  }
  let def-idx = hit.at(0)
  let c-end = def-idx
  while c-end > 0 and lines.at(c-end - 1).trim() == "" { c-end -= 1 }
  let start = rocq-comment-start-before(lines, c-end)
  let comment = if start < c-end { lines.slice(start, c-end).join("\n") } else { "" }
  (name: name, sources: parse-citations(comment))
}

#let rocq-cite-data(module, name) = {
  let data = rocq-cite-data-opt(module, name)
  if data.sources.len() == 0 {
    panic(
      "rocq-cite: no parseable citation in the comment above "
        + module
        + "."
        + name,
    )
  }
  data
}

#let supplement-text(source, page) = {
  let loc = source.locator.replace(regex("\\s*\"[^\"]*\""), "").trim()
  if page != none {
    loc + ", p. " + str(page)
  } else {
    loc
  }
}

#let rocq-cite-render(t) = {
  let dot = t.position(".")
  let data = rocq-cite-data(t.slice(0, dot), t.slice(dot + 1, none))
  data.sources
    .map(source => cite(
      label(source.key),
      supplement: supplement-text(source, resolve-page(source)),
    ))
    .join("; ")
}

#let rocq-cite-list(module, name) = {
  let data = rocq-cite-data-opt(module, name)
  if data.sources.len() == 0 { return none }
  data
    .sources
    .map(source => cite(
      label(source.key),
      supplement: supplement-text(source, resolve-page(source)),
    ))
    .join("; ")
}

#let rocq-cite-ref(it) = {
  let t = str(it.target)
  if rocq-target(t) { rocq-cite-render(t) } else { it }
}
