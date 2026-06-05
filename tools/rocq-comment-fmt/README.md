# rocq-comment-fmt

A deterministic, idempotent formatter for comments in Rocq/Coq (`*.v`) sources.
It rewraps comment bodies to a column budget (default 80), merges runs of
adjacent single-line comments, and **never touches code** — only the bytes
inside `(* … *)` spans are rewritten.

Written in OCaml (the comment lexis of Coq is identical to OCaml's). The design
follows ocamlformat's `wrap-comments` model (paragraphs split by blank lines,
each wrapped at the margin), adapted to this project's Russian-prose comments.

## Build & run

Uses the repo's existing opam switch (no extra dependencies):

```sh
opam exec --switch=. -- dune build  --root tools/rocq-comment-fmt
opam exec --switch=. -- dune test   --root tools/rocq-comment-fmt   # unit tests
BIN=tools/rocq-comment-fmt/_build/default/bin/main.exe

"$BIN" theories/dare.v            # print formatted result to stdout
"$BIN" --check theories/          # exit 1 if anything would change (CI)
"$BIN" --write theories/          # reformat in place
```

CLI:

```
rocq-comment-fmt [--write] [--check] [--width N] [--protect-banners] <files-or-dirs…>
```

- default: print formatted output to stdout;
- `--write`: edit files in place;
- `--check`: print nothing, exit 1 if any file would change;
- `--width N`: column budget (default 80);
- `--protect-banners`: leave `(* ==== *)` banner comments untouched;
- directories are searched recursively for `*.v`.

## Formatting rules

1. A run of adjacent **single-line** comments on consecutive lines (no blank
   line between) is merged into one comment.
2. Comments separated by a blank line are never merged.
3. Each paragraph is greedily reflowed to ≤ `width` columns.
4. Words are never split.
5. A `(…)`, `[…]`, `` `…` ``, `$…$` or inline ```` ```…``` ```` group is never
   split across lines, even if it overflows.
6. A fenced ```` ``` ```` block is copied verbatim (no rewrap, no gluing).
7. Whitespace runs are collapsed to single spaces everywhere except fenced code
   and skip regions — including inside `(…)`/`[…]`/`$…$`.
8. A comment that fits becomes `(* … *)`; otherwise it becomes a block:
   ```
   (*
     …two-space body indent, each line ≤ width…
   *)
   ```

## Lists

A line whose first non-space character is an **ASCII minus** `-` followed by a
space, or a **number** `1.` / `2)` followed by a space, is a **list item**.
Dash items get a 2-space hanging indent; numbered items a 4-space (even) one.
Continuations and fenced blocks belonging to the item are kept under it.

En/em dashes (`–`, `—`) and any mid-line `-` are ordinary prose; a lone dash or
numbered token is glued to the previous word so it never lands at a line start
(where it would be mistaken for a marker).

If a single `-`/`N.` marker is followed by an **un-indented** continuation line
(the signature of a sentence dash/clause the author placed at the start of a
line, not a list), the comment is **left unformatted and reported**:

```
theories/foo.v:42: not formatted: leading '-' or 'N.' looks like a sentence dash …
```

Fix it by hand (e.g. join the dash to the previous line, or indent the
continuation) and re-run, or wrap the comment in `format: off`.

A fenced ```` ``` ```` block inside a list item is repositioned to the item's
body column. Its content keeps its indentation **relative to the opening ```**
(content left of the fence is clamped to the fence column; the least-indented
content line aligns with the fence), and the closing ``` matches the opening
one's indent — so e.g. an aligned matrix display keeps its shape.

## Tables

ASCII (`+` `-` `|`) and Unicode box-drawing grid tables are first-class: their
structure is preserved and the prose **inside** each cell is rewrapped, instead
of the whole grid being flattened into a paragraph.

A table is a run of consecutive lines that are each either a **rule** (a border
or separator: only horizontal/junction glyphs — `-`/`─`/`═`/`━` and
`+`/`┌┬┐├┼┤└┴┘`/`╞╪╡`/… — with at least two junctions) or a **row** (starts with
a vertical bar `|`/`│`/`║`). A genuine table needs at least one of each, so lone
dividers and stray pipe-prefixed prose stay prose.

- The rows **between two rule lines** are one *logical row*; a cell may span
  several physical lines. Put a rule line between entries you want kept as
  **separate** rows (this is the grid-table convention).
- Each cell's text is rewrapped (whitespace collapsed, words filled) to its
  column width and re-padded. Protected groups (`(…)`, `[…]`, `` `…` ``,
  `$…$`) stay whole, exactly as in prose.
- Column widths come from the first rule line, but a column **grows** to fit its
  widest unbreakable atom (a long citation or qualified name) so it never
  overflows and breaks alignment.
- If the table still does not fit the configured `--width`, the file is
  **warned** (`…: table needs N cols, over the 80-col width; reflowed columns to
  their minimal widths`) and the columns are reflowed to their **minimal**
  widths (the narrowest that keeps every atom whole).
- Rule glyphs are re-emitted from each line's own captured junction/horizontal
  characters, so top/middle/bottom borders, a heavier header separator, and
  ASCII-vs-box styles are all reproduced faithfully.
- A block that is not a clean grid (ragged cell counts, inconsistent junctions)
  is emitted **verbatim** — never corrupted.

## Opting out

Wrap deliberate layout (alignment tables, banners, display math) so it is copied
verbatim:

```coq
(* format: off *)
(* ┌──────────┬──────────┐   hand-aligned table … *)
(* format: on *)
```

`(** … *)` coqdoc comments are always preserved verbatim (their markup must not
be reflowed).

## Safety

The tool only ever splices comment spans; it tokenises the file into
code/string/comment regions (Coq comments nest, and string literals are honoured
inside both code and comments, so `(*` inside `"…"` is not a comment). On every
run it asserts that the whitespace-stripped non-comment text is byte-identical
before and after; if not, it refuses to touch the file and exits non-zero. The
test suite covers this invariant plus idempotency (`format (format x) =
format x`).

## Known limitations

- Nested lists (a list item inside another) are flattened to one level.
- A `====` / `----` banner written on the `(* …` opening line is moved onto its
  own line and reflowed as prose; wrap such comments in `format: off`.
- Unbalanced `(`/`[`/backtick/`$` inside a paragraph is treated as a literal
  character (the group protection needs a matching close).
