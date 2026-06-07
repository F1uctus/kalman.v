#import "rocq.typ": rocq-src, rocq-locate, rocq-statement-range, rocq-proofbody-range, rocq-render-range, rocq-doc-comment, rocq-proof-sketch
#import "rocq-cite.typ": rocq-cite-list

#let conv-at-inf(source, target) = $ #source attach(arrow.r, t: infinity) #target $

#let rocq-conv-in-backtick-re = regex("`([^`]+) @ (?:\\\\oo|∞) --> ([^`]+)`")
#let rocq-conv-at-inf-re = regex(
  "(\\([^)]+\\)|\\w+(?:\\.\\w+)*|\\w+(?:\\s+\\w+)*) @ (?:\\\\oo|∞) --> ([^\\n,.;`]+)([.,;:]?)",
)

#let rocq-render-text(s) = {
  let t = s.replace("†", "^*")
  t = t.replace(
    rocq-conv-in-backtick-re,
    m => "#conv-at-inf[`" + m.captures.at(0) + "`][" + m.captures.at(1) + "]",
  )
  t.replace(
    rocq-conv-at-inf-re,
    m => {
      let tail = m.captures.at(2)
      let left = m.captures.at(0).trim()
      let right = m.captures.at(1).trim()
      "#conv-at-inf[" + left + "][" + right + "]" + tail
    },
  )
}
#let rocq-eval(s, scope) = eval(rocq-render-text(s), mode: "markup", scope: scope)

#let rocq-doc(
  source,
  name,
  env: none,
  sketch-env: none,
  title: auto,
  description: true,
  citations: true,
  statement: true,
  sketch: false,
  proof: false,
  scope: (:),
) = {
  let lines = rocq-src(source).split("\n")
  let loc = rocq-locate(lines, name)
  let doc = rocq-doc-comment(lines, loc.idx)
  let module = if source.ends-with(".v") {
    source.slice(0, source.len() - 2)
  } else { source }

  let title-str = if title == auto {
    if env != none { doc.title } else { "" }
  } else if title == none { "" } else { title }
  let lead = if title == auto and env != none { "" } else { doc.title }

  let prose = {
    let parts = ()
    if lead != "" { parts.push(lead) }
    if description and doc.description != "" { parts.push(doc.description) }
    if parts.len() > 0 { rocq-eval(parts.join("\n\n"), scope) }
    if citations {
      let cl = rocq-cite-list(module, name)
      if cl != none [ #cl]
    }
  }

  let stmt = if statement {
    let r = rocq-statement-range(lines, loc.idx, loc.kind)
    rocq-render-range(source, lines, r.start, r.end)
  }

  let sketch-text = if sketch { rocq-proof-sketch(lines, loc.idx, loc.kind) } else { none }
  let has-sketch = sketch-text != none and sketch-env != none

  let proofbody = if proof {
    let r = rocq-proofbody-range(lines, loc.idx)
    if r != none { rocq-render-range(source, lines, r.start, r.end) }
  }

  let inner = {
    prose
    stmt
    if not has-sketch { proofbody }
  }
  if env != none {
    let t = if title-str.ends-with(".") {
      title-str.slice(0, title-str.len() - 1)
    } else { title-str }
    if t != "" {
      env(title: rocq-eval(t, scope))[#inner]
    } else {
      env[#inner]
    }
  } else {
    inner
  }

  if has-sketch {
    sketch-env[#rocq-eval(sketch-text, scope)]
    proofbody
  }
}
