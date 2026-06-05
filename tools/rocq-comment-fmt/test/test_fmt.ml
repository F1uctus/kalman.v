let opts = Rcf.default_options
let failures = ref 0
let pass name = Printf.printf "ok   %s\n" name
let fmt o x = (Rcf.format_string o x).Rcf.output
let sp n = String.make n ' '
let rep n s = String.concat "" (List.init n (fun _ -> s))

let eqo name o input expected =
  let got = fmt o input in
  if got = expected then pass name
  else begin
    incr failures;
    Printf.printf "FAIL %s\n  expected: %S\n  got:      %S\n" name expected got
  end

let eq name input expected = eqo name opts input expected

let contains hay needle =
  let nl = String.length needle and hl = String.length hay in
  let rec f i =
    if i + nl > hl then false
    else if String.sub hay i nl = needle then true
    else f (i + 1)
  in
  nl = 0 || f 0

let has name input needle =
  let got = fmt opts input in
  if contains got needle then pass name
  else begin
    incr failures;
    Printf.printf "FAIL %s\n  missing: %S\n  in:      %S\n" name needle got
  end

let idem name input =
  let a = fmt opts input in
  let b = fmt opts a in
  if a = b then pass ("idem " ^ name)
  else begin
    incr failures;
    Printf.printf "FAIL idem %s\n  once:  %S\n  twice: %S\n" name a b
  end

(* Code-safety: no code *character* may change. Merging adjacent comments
   legitimately consumes inter-comment whitespace, and whitespace is never
   semantically significant in Coq, so compare with whitespace removed. *)
let nows s =
  String.to_seq s
  |> Seq.filter (fun c -> not (c = ' ' || c = '\t' || c = '\n' || c = '\r'))
  |> String.of_seq

let safe name input =
  let f = fmt opts input in
  if nows (Rcf.code_only input) = nows (Rcf.code_only f) then pass ("safe " ^ name)
  else begin
    incr failures;
    Printf.printf "FAIL safe %s\n  code before: %S\n  code after:  %S\n" name
      (Rcf.code_only input) (Rcf.code_only f)
  end

let warns name input =
  let r = Rcf.format_string opts input in
  if r.Rcf.warnings <> [] then pass ("warns " ^ name)
  else begin
    incr failures;
    Printf.printf "FAIL warns %s: expected a warning, got none\n  out: %S\n" name
      r.Rcf.output
  end

(* 16 four-letter words: too wide for one line (79 + delimiters), wraps to two. *)
let long16 =
  "aaaa bbbb cccc dddd eeee ffff gggg hhhh iiii jjjj kkkk llll mmmm nnnn oooo pppp"

let line15 =
  "aaaa bbbb cccc dddd eeee ffff gggg hhhh iiii jjjj kkkk llll mmmm nnnn oooo"

(* a list item with a fenced matrix, indented under a 2-space comment. The fence
   in the input sits at column 8 (over-indented); it must be repositioned to the
   item body column 6, keeping the matrix's internal alignment. *)
let fence_item_in =
  "  (*\n    - условие:\n" ^ sp 8 ^ "```\n" ^ sp 13 ^ "⎡A⎤\n" ^ sp 8
  ^ "rank ⎣B⎦\n" ^ sp 8 ^ "```\n  *)"

let fence_item_out =
  "  (*\n    - условие:\n" ^ sp 6 ^ "```\n" ^ sp 11 ^ "⎡A⎤\n" ^ sp 6
  ^ "rank ⎣B⎦\n" ^ sp 6 ^ "```\n  *)"

(* outdented fence content ("out" left of the fence) is clamped to the fence
   column; the deeper line keeps its relative indent. *)
let clamp_in = "(*\n  - x:\n" ^ sp 4 ^ "```\n" ^ sp 2 ^ "out\n" ^ sp 9 ^ "in\n" ^ sp 4 ^ "```\n*)"
let clamp_out = "(*\n  - x:\n" ^ sp 4 ^ "```\n" ^ sp 4 ^ "out\n" ^ sp 9 ^ "in\n" ^ sp 4 ^ "```\n*)"

(* an ASCII grid that already fits: must round-trip unchanged *)
let tbl_ascii = "(*\n  +---+---+\n  | a | b |\n  +---+---+\n*)"

(* a box grid whose right cell is too long for its drawn column: the column
   grows to the widest atom and the prose rewraps inside the cell *)
let tbl_box =
  "(*\n  ┌────────┬──────┐\n  │ ключ   │ знач │\n  ├────────┼──────┤\n"
  ^ "  │ a      │ это очень длинное значение ячейки │\n  └────────┴──────┘\n*)"

(* a one-column table drawn far wider than 80: must warn and shrink to the
   minimal column width *)
let tbl_wide =
  "(*\n  +" ^ String.make 84 '-' ^ "+\n  | x |\n  +" ^ String.make 84 '-' ^ "+\n*)"

(* a ragged grid (a row with the wrong number of cells): not a clean grid, so
   it is emitted verbatim, never corrupted *)
let tbl_ragged = "(*\n  +----+----+\n  | a  | b  | c |\n  +----+----+\n*)"

let () =
  (* single-line stays / collapses *)
  eq "single-stable" "(* привет мир *)" "(* привет мир *)";
  eq "block-to-single" "(*\n  привет мир\n*)" "(* привет мир *)";
  eq "ws-collapse" "(* a    b *)" "(* a b *)";

  (* merge adjacent single-line comments *)
  eq "merge2" "(* привет *)\n(* мир *)" "(* привет мир *)";

  (* blank line prevents merge; both stay separate and unchanged *)
  eq "blank-no-merge" "(* привет *)\n\n(* мир *)" "(* привет *)\n\n(* мир *)";

  (* long -> block form, greedy wrap at 80, indent 0 *)
  eq "block-wrap" ("(* " ^ long16 ^ " *)") ("(*\n  " ^ line15 ^ "\n  pppp\n*)");

  (* long -> block form, indent preserved (2 spaces) *)
  eq "block-wrap-indent"
    ("  (* " ^ long16 ^ " *)")
    ("  (*\n    " ^ line15 ^ "\n    pppp\n  *)");

  (* protected atoms never split, even when overflowing *)
  has "paren-atomic"
    "(* x (this is a long parenthetical phrase that surely exceeds eighty cols) y \
     *)"
    "(this is a long parenthetical phrase that surely exceeds eighty cols)";
  has "bracket-atomic" "(* см. [kailath2000, гл. 14.5] подробнее *)"
    "[kailath2000, гл. 14.5]";
  has "backtick-atomic" "(* контур `F - K H` устойчив *)" "`F - K H`";
  has "dollar-atomic"
    "(* матрица $A - B C^\\top$ положительно определена *)" "$A - B C^\\top$";

  (* whitespace inside a paren group is collapsed too *)
  eq "paren-ws-collapse" "(* a (b   c) d *)" "(* a (b c) d *)";
  eq "dollar-ws-collapse" "(* a $b   c$ d *)" "(* a $b c$ d *)";

  (* dash list: >=2 minus items render as a list, 2-space body indent *)
  eq "list-two-items" "(*\n  Заголовок:\n  - один\n  - два\n*)"
    "(*\n  Заголовок:\n  - один\n  - два\n*)";
  has "list-item-line" "(*\n  Заголовок:\n  - пункт один\n  - пункт два\n*)"
    "  - пункт один";

  (* genuine single dash item with hang-indented continuation *)
  has "list-hang"
    "(*\n  - очень длинный пункт списка раз два три четыре пять шесть семь восемь \
     девять десять одиннадцать двенадцать\n*)"
    "\n    ";

  (* numbered list: preserved, 4-space (even) body indent *)
  eq "numbered" "(*\n  Шаги:\n  1. первый\n  2. второй\n*)"
    "(*\n  Шаги:\n  1.  первый\n  2.  второй\n*)";

  (* fenced block inside a list item: repositioned to the item body column,
     keeping internal alignment; trailing prose stays in the item *)
  eq "fence-in-item-reposition" fence_item_in fence_item_out;
  eq "fence-clamp" clamp_in clamp_out;

  (* ambiguous: lone minus + un-indented continuation = sentence dash -> warn,
     leave verbatim *)
  let amb = "(*\n  - это тире в начале строки\n  продолжение на базовом отступе\n*)" in
  warns "ambiguous-dash" amb;
  eq "ambiguous-unchanged" amb amb;

  (* fenced code: verbatim, internal spacing preserved, not glued *)
  has "fence-verbatim"
    "(*\n  текст тут\n  ```\n  code  with  spaces\n  ```\n*)" "code  with  spaces";

  (* format: off / on leaves the region verbatim *)
  eqo "format-off" opts
    "(* format: off *)\n(* a    b *)\n(* format: on *)"
    "(* format: off *)\n(* a    b *)\n(* format: on *)";

  (* inline trailing comment untouched *)
  eq "inline-untouched" "Definition x := 1. (* a    b *)\n"
    "Definition x := 1. (* a    b *)\n";

  (* coqdoc always preserved verbatim (its own markup must not be reflowed) *)
  eq "coqdoc-skip" "(** doc    text *)" "(** doc    text *)";
  eq "coqdoc-multiline" "(** doc    text\n   more *)" "(** doc    text\n   more *)";

  (* banners preserved with --protect-banners *)
  eqo "banner-protect" { opts with protect_banners = true }
    "(* ===== *)\n(* Заголовок *)\n(* ===== *)"
    "(* ===== *)\n(* Заголовок *)\n(* ===== *)";

  (* a string literal containing (* ... *) is not treated as a comment *)
  has "string-literal-intact"
    "Definition s := \"a (* x *) b\".\n(* real    cmt *)\n" "\"a (* x *) b\"";
  eq "string-then-comment"
    "Definition s := \"a (* x *) b\".\n(* real    cmt *)\n"
    "Definition s := \"a (* x *) b\".\n(* real cmt *)\n";

  (* idempotency *)
  List.iter
    (fun (n, x) -> idem n x)
    [
      ("single", "(* привет мир *)");
      ("merge", "(* привет *)\n(* мир *)");
      ("block", "(* " ^ long16 ^ " *)");
      ("block-indent", "  (* " ^ long16 ^ " *)");
      ("list", "(*\n  Заголовок:\n  - пункт один\n  - пункт два\n*)");
      ("list-hang",
        "(*\n  - очень длинный пункт списка раз два три четыре пять шесть семь \
         восемь девять десять одиннадцать двенадцать тринадцать\n*)");
      ("numbered", "(*\n  Шаги:\n  1. первый\n  2. второй\n*)");
      ("numbered-wrap",
        "(*\n  1. первый очень длинный пункт нумерованного списка раз два три \
         четыре пять шесть семь восемь девять\n  2. второй\n*)");
      ("fence", "(*\n  текст тут\n  ```\n  code  with  spaces\n  ```\n*)");
      ("fence-in-item", fence_item_in);
      ("fence-clamp", clamp_in);
      ("paren", "(* a (b   c) d *)");
      ("dollar", "(* a $b   c$ d *)");
      ("citation", "(* см. [kailath2000, гл. 14.5] подробнее *)");
      ("blank", "(* привет *)\n\n(* мир *)");
      ("dash-prose",
        "(* раз два три четыре пять шесть семь восемь - девять десять одиннадцать \
         двенадцать тринадцать четырнадцать пятнадцать шестнадцать *)");
      ("emdash-prose",
        "(* раз два три четыре пять шесть семь — восемь девять десять одиннадцать \
         двенадцать тринадцать четырнадцать пятнадцать шестнадцать *)");
      ("ambiguous", "(*\n  - тире\n  база на том же отступе продолжается тут\n*)");
    ];

  (* code-safety: non-comment bytes are byte-identical before/after *)
  List.iter (fun (n, x) -> safe n x)
    [
      ("decl-inline", "Definition x := 1. (* a    b *)\nLemma y : x = x.\n");
      ("string", "Definition s := \"a (* x *) b\".\n(* real    cmt *)\n");
      ("merge", "Section S.\n(* привет *)\n(* мир *)\nEnd S.\n");
      ("block", "(* " ^ long16 ^ " *)\nDefinition z := 0.\n");
      ("fence-item", fence_item_in);
    ];

  (* tables: ASCII (+ - |) and Unicode box-drawing grids *)
  eq "table-ascii-stable" tbl_ascii tbl_ascii;
  (* the long right cell reflows: "значение" lands alone on a grown column *)
  has "table-box-reflow" tbl_box "│ значение │";
  (* the grown grid: col0 box = 6+2, col1 box (widest atom 8) = 8+2 *)
  has "table-box-grid" tbl_box ("└" ^ rep 8 "─" ^ "┴" ^ rep 10 "─" ^ "┘");
  (* over-wide table: warns and shrinks to the minimal column width *)
  warns "table-too-wide" tbl_wide;
  has "table-wide-shrunk" tbl_wide "| x |";
  (* ragged grid is left verbatim (no corruption) *)
  eq "table-ragged-verbatim" tbl_ragged tbl_ragged;

  List.iter (fun (n, x) -> idem n x)
    [ ("table-ascii", tbl_ascii); ("table-box", tbl_box);
      ("table-wide", tbl_wide); ("table-ragged", tbl_ragged) ];
  List.iter (fun (n, x) -> safe n x)
    [ ("table-box", tbl_box); ("table-wide", tbl_wide);
      ("table-ragged", tbl_ragged) ];

  if !failures > 0 then (Printf.printf "\n%d FAILURE(S)\n" !failures; exit 1)
  else Printf.printf "\nall tests passed\n"
