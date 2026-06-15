#import "@local/djvu:0.1.0": djvu-find, djvu-pages
#import "rocq.typ": (
  rocq-comment-start-before, rocq-decl-kinds, rocq-raw-inline, rocq-src,
  rocq-theory-modules,
)

// Theory-file stems, derived live from the `(modules ...)` stanza of
// `theories/dune`. A citation target names the bare file stem, so any
// directory prefix (e.g. `seqmx/`) is dropped.
#let rocq-stems = rocq-theory-modules().map(m => m.split("/").last())

// `@module.name` is a Rocq citation iff the part before the first dot is a
// theory-file stem; everything else (figure/section/eq refs, `@bibkey`) is left
// to Typst.
#let rocq-target(t) = {
  let dot = t.position(".")
  if dot == none { false } else {
    rocq-stems.contains(t.slice(0, dot))
  }
}

// Books whose committed `.djvu` can be searched for printed page numbers.
//  - path:        project-root-absolute path to the `.djvu`.
//  - front-skip:  number of leading (front-matter) djvu pages to ignore when
//                 searching, so a table-of-contents line never matches first.
//  - folio:       djvu page index (1-based) -> printed folio. The offset is not
//                 constant across a scan (unnumbered divider pages), so it is a
//                 small piecewise map calibrated once per book.
// Wonham is intentionally absent: it is not committed, so reading it would fail
// the build. Add it here (and commit the `.djvu`) to enable its page numbers.
#let book-sources = (
  kailath2000: (
    path: "/references/Kailath T., Sayed A., Hassibi B. - Linear Estimation.djvu",
    front-skip: 25,
    // Chapters: index - 25. Appendices A-E (index >= 748): index - 23.
    folio: idx => idx - (if idx >= 748 { 23 } else { 25 }),
  ),
)

#let book-pages(key) = djvu-pages(read(
  book-sources.at(key).path,
  encoding: none,
))

// Resolve the printed folio for one parsed source, or `none`. Needs both a
// search anchor (e.g. `Lemma 9.3.2`) and the quoted theorem name; searches only
// the book body (front matter skipped); maps the djvu index to a printed folio.
#let resolve-page(source) = {
  if source.anchor == none or source.quoted == none { return none }
  if not book-sources.keys().contains(source.key) { return none }
  let book = book-sources.at(source.key)
  let pages = book-pages(source.key)
  let hit = djvu-find(
    pages.slice(book.front-skip),
    source.anchor,
    source.quoted,
  )
  if hit == none { none } else { (book.folio)(book.front-skip + hit) }
}

// A bib citation in a `.v` comment uses Typst cite syntax `@key[locator "quoted"]`.
// Captures the key and the supplement (which may contain one nested `[...]`, e.g.
// a quoted title that itself has brackets).
#let citation-ref-re = regex(
  "@([a-zA-Z0-9_]+)\\[((?:[^\\[\\]]|\\[[^\\[\\]]*\\])*)\\]",
)
#let number-re = regex("[A-Z]?\\.?\\d+(\\.\\d+)*")
// A `Kind Number` phrase (e.g. `Lemma 9.3.2`, `Theorem E.5.1`). Used as the
// primary search needle: it is specific enough to skip table-of-contents lines
// that carry the bare section number only.
#let kind-number-re = regex(
  "(Theorem|Lemma|Corollary|Proposition|Fact|Equation|Eq\\.?|Definition|Def\\.?)"
    + "\\s+[A-Z]?\\.?\\d+(\\.\\d+)*",
)

#let parse-source(key, supplement) = {
  let locator = supplement.trim()
  // Quoted theorem name (page-search anchor; not displayed).
  let q-open = locator.position("\"")
  let quoted = if q-open != none {
    let rest = locator.slice(q-open + 1, none)
    let q-close = rest.position("\"")
    if q-close == none { none } else { rest.slice(0, q-close) }
  } else {
    none
  }
  // Search anchor: the `Kind Number` phrase if present, else the most specific
  // bare number, taken from the locator head before the quote.
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

// Locate `module.name`'s declaration, read the comment above it, parse its
// citation(s). Lenient: `sources` may be empty (panics only if the declaration
// itself is missing).
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
  // Skip blank lines between the declaration and the comment above it.
  let c-end = def-idx
  while c-end > 0 and lines.at(c-end - 1).trim() == "" { c-end -= 1 }
  let start = rocq-comment-start-before(lines, c-end)
  let comment = if start < c-end { lines.slice(start, c-end).join("\n") } else {
    ""
  }
  (name: name, sources: parse-citations(comment))
}

// Strict variant: additionally panics when no citation is parseable.
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

// Displayed locator: the quoted theorem name (a search anchor) is dropped, the
// page is appended when found.
#let supplement-text(source, page) = {
  let loc = source.locator.replace(regex("\\s*\"[^\"]*\""), "").trim()
  if page != none {
    loc + ", p. " + str(page)
  } else {
    loc
  }
}

// Split a citation target into `(module, name, mode)`. A trailing `.code` or
// `.num` selects a cross-reference mode; otherwise the default `cite` mode
// renders the bibliography source(s).
#let rocq-parse-target(t) = {
  let parts = t.split(".")
  let last = parts.last()
  let mode = if last == "code" { "code" } else if last == "num" {
    "num"
  } else { "cite" }
  let body = if mode == "cite" { parts } else {
    parts.slice(0, parts.len() - 1)
  }
  (module: body.first(), name: body.slice(1).join("."), mode: mode)
}

// `.code`: the Rocq declaration name as inline code, compile-checked against the
// `.v` file (`rocq-cite-data-opt` panics when the declaration is absent). When a
// cross-reference label for the block exists (a `rocq-doc` block, or a snippet
// tagged `<module.name>`), the name is hyperlinked to it; otherwise it renders
// as plain inline code.
#let rocq-name-render(module, name) = context {
  let _ = rocq-cite-data-opt(module, name)
  let lbl = label(module + "." + name)
  let code = rocq-raw-inline(name)
  if query(lbl).len() > 0 { link(lbl, code) } else { code }
}

// `.num`: the kind word and number of the rendered block (e.g. "Лемма 4.5"),
// hyperlinked to it. Reads the metadata attached by `rocq-doc`; panics if the
// block was never rendered.
#let rocq-num-render(module, name) = context {
  let lbl = label(module + "." + name)
  let els = query(lbl)
  if els.len() == 0 {
    panic(
      "rocq-cite: `.num` needs a rendered block for "
        + module
        + "."
        + name
        + " (via #rocq-lemma/#rocq-theorem/...)",
    )
  }
  let v = els.first().value
  if v.number == none {
    panic("rocq-cite: `.num` needs a counted block for " + module + "." + name)
  }
  link(lbl)[#v.kind~#v.number]
}

// Render `module.name`. Default (cite) mode: one live bibliography link per
// source, `, `-joined, carrying the locator and (when found) the printed page;
// the Rocq name is not printed inline as the adjacent code block already shows
// it. The `.code` / `.num` suffixes select the cross-reference modes above.
#let rocq-cite-render(t) = {
  let p = rocq-parse-target(t)
  if p.mode == "code" {
    rocq-name-render(p.module, p.name)
  } else if p.mode == "num" {
    rocq-num-render(p.module, p.name)
  } else {
    rocq-cite-data(p.module, p.name)
      .sources
      .map(source => cite(
        label(source.key),
        supplement: supplement-text(source, resolve-page(source)),
      ))
      .join(", ")
  }
}

// Render the citation(s) in `module.name`'s doc comment as a `, `-joined run of
// live bibliography links, for inline use at the end of a prose description.
// Each link carries its locator and (when found) the printed page. The doc
// comment lists the sources as separate `- @key[...]` bullets; they render as
// one comma-separated trailing reference. `none` when there is no citation.
#let rocq-cite-list(module, name) = {
  let data = rocq-cite-data-opt(module, name)
  if data.sources.len() == 0 { return none }
  data
    .sources
    .map(source => cite(
      label(source.key),
      supplement: supplement-text(source, resolve-page(source)),
    ))
    .join(", ")
}

// `show ref` hook for the template: intercept `@module.name`, pass through the
// rest.
#let rocq-cite-ref(it) = {
  let t = str(it.target)
  if rocq-target(t) { rocq-cite-render(t) } else { it }
}
