#import "rocq.typ": (
  rocq-comment-text, rocq-doc-comment, rocq-locate, rocq-proof-sketch,
  rocq-proofbody-range, rocq-render-range, rocq-src, rocq-statement-range,
)
#import "rocq-cite.typ": rocq-cite-list

// great-theorems emits, inside every counted block, a metadata element labelled
// `great-theorems:numberfunc` whose value is `loc => <displayed number>`. The
// cross-reference handle resolves it eagerly to a fixed string, so the captured
// number is the block's own (rendering the lazy `prefix` number elsewhere would
// re-evaluate the counter at the reference site and be off by one).
#let great-theorems-numberfunc = label("great-theorems:numberfunc")


// Notation translation applied to comment prose before it is evaluated as Typst.
// The `.v` source keeps natural Rocq comment notation (e.g. `†` for the
// conjugate transpose, which also avoids forming `*)` and closing the comment),
// and the paper renders the project's `^*`. Add further pairs to the chain.
#let rocq-render-text(s) = {
  let t = s.replace("†", "^*")
  t
}
#let rocq-eval(s, scope) = eval(
  rocq-render-text(s),
  mode: "markup",
  scope: scope,
)

// Segment a `Proof. ... Qed.` line range into runs of code and standalone
// `(* ... *)` comment blocks (a block whose first non-space token on its opening
// line is `(*`; trailing inline comments after code stay inside the code run).
#let rocq-proof-segments(lines, start, end) = {
  let segs = ()
  let i = start
  while i <= end {
    let t = lines.at(i).trim()
    if t.starts-with("(*") {
      let j = i
      while j <= end and not lines.at(j).trim().ends-with("*)") { j += 1 }
      segs.push((kind: "comment", from: i, to: calc.min(j, end)))
      i = calc.min(j, end) + 1
    } else {
      let j = i
      while j <= end and not lines.at(j).trim().starts-with("(*") { j += 1 }
      segs.push((kind: "code", from: i, to: j - 1))
      i = j
    }
  }
  segs
}

// Render a proof body with standalone comment blocks lifted to formatted prose
// paragraphs interleaved between the code listings. Code runs keep continuous
// line numbers (via the original line indices).
#let rocq-render-proof(source, lines, start, end, scope) = {
  for s in rocq-proof-segments(lines, start, end) {
    if s.kind == "code" {
      rocq-render-range(source, lines, s.from, s.to)
    } else {
      let txt = rocq-comment-text(lines, (start: s.from, end: s.to + 1)).join(
        "\n",
      )
      block(
        inset: (left: 1.2em),
        above: 0.6em,
        below: 0.6em,
        rocq-eval(txt, scope),
      )
    }
  }
}

// Render a complete Rocq declaration block from its `.v` source, pulling every
// piece of prose from the file so the `.v` is the single source of truth. The
// rendered order is:
//   1. prose description (doc comment above the declaration);
//   2. citation list (trailing `- @key[...]` bullets, inline, `; `-joined);
//   3. statement signature listing (raw codly, no proof);
//   4. proof sketch (the comment between the statement and `Proof.`);
//   5. optionally the proof body `Proof. ... Qed.`.
//
// `env` / `sketch-env` are the great-theorems environments, passed in by the
// thin wrappers defined in lib.typ, so this module needs no import cycle.
//
// Arguments:
//   env          titled environment (theorem/lemma/...) or `none` for inline.
//   sketch-env   proofsketch environment, or `none` to suppress the sketch.
//   title        `auto` = first comment paragraph (only when `env` is set);
//                a value overrides it; `none` keeps everything as description.
//   description  render the prose description.
//   citations    render the trailing citation list.
//   statement    render the statement signature listing.
//   proof        also render the proof body `Proof. ... Qed.`.
//   scope        eval scope for the description / title / sketch markup.
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
  kind: none,
  counted: true,
) = {
  let lines = rocq-src(source).split("\n")
  let loc = rocq-locate(lines, name)
  let doc = rocq-doc-comment(lines, loc.idx)
  let module = if source.ends-with(".v") {
    source.slice(0, source.len() - 2)
  } else { source }

  // Resolve the title.
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

  // Proof sketches are opt-in.
  let sketch-text = if sketch {
    rocq-proof-sketch(lines, loc.idx, loc.kind)
  } else { none }
  let has-sketch = sketch-text != none and sketch-env != none

  let proofbody = if proof {
    let r = rocq-proofbody-range(lines, loc.idx)
    if r != none { rocq-render-proof(source, lines, r.start, r.end, scope) }
  }

  // Cross-reference handle for `@module.name.code` / `.num`, placed inside the
  // box. For a counted block, resolve this block's own number from the nearest
  // preceding `great-theorems:numberfunc` (emitted at the block's head). `.code`
  // links here; `.num` reads the resolved number from the metadata.
  let handle = if env != none and kind != none {
    context {
      let num = if counted {
        let nf = query(
          selector(great-theorems-numberfunc).before(here()),
        ).last()
        if nf != none { (nf.value)(nf.location()) }
      }
      [#metadata((kind: kind, number: num)) #label(module + "." + name)]
    }
  }

  // Without a sketch the proof body stays inside the box, right after the
  // statement; a sketch separates the statement from the proof, so both the
  // sketch and the proof body render after the box.
  let inner = {
    prose
    stmt
    if not has-sketch { proofbody }
    handle
  }
  if env != none {
    // A title is a label, so drop a trailing full stop.
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
