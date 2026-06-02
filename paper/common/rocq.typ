#import "/paper/packages/local/textmate/0.1.0/lib.typ": to-sublime-syntax
#import "@preview/codly:1.3.0"

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
  icon: box(image("/paper/images/icon-rocq-orange.svg", height: 100%), inset: (right: 4pt)),
  color: rocq-badge-color,
)

#let rocq-raw(code) = raw(
  code,
  lang: "rocq",
  syntaxes: bytes(rocq-syntax),
  theme: "/paper/assets/rocq.tmTheme",
  block: true,
)

#let rocq-codly(body, source, ..args) = {
  codly.local(
    languages: (rocq: rocq-codly-lang(source)),
    ..args,
  )[#body]
}

#let rocq-endings = (
  Variable: regex("\."),
  Definition: regex("\."),
  Hypothesis: regex("\."),
  Lemma: regex("\."),
  Theorem: regex("Qed\."),
)

#let rocq-snippet(source, name) = {
  let lines = rocq-src(source).split("\n")
  let from-line = lines //
    .enumerate()
    .find(((i, l)) => name in l)
  let end = rocq-endings //
    .pairs()
    .find(((s, e)) => s in from-line.at(1))
    .at(1)
  let to-line = (
    lines //
      .slice(from-line.at(0))
      .enumerate()
      .find(((idx, line)) => end in line)
      .zip(from-line)
      .map(a => a.sum())
  )
  let snippet = lines.slice(from-line.at(0), to-line.at(0) + 1)
  rocq-codly(
    rocq-raw(snippet.join("\n")),
    source,
    offset: from-line.at(0),
    display-icon: false,
  )
}

#show raw: set text(font: "Times New Roman")
