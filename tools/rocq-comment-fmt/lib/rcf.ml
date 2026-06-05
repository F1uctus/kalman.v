(* rocq-comment-fmt: deterministic, idempotent formatter for Rocq/Coq comments.

   Only comment spans are rewritten; every other byte (code, string literals,
   inter-comment whitespace) is copied verbatim, so code can never be corrupted.
   See tools/rocq-comment-fmt/README.md for the design notes. *)

type options = {
  width : int;            (* hard column budget, default 80 *)
  protect_banners : bool; (* skip single-line (* ==== *) banner comments *)
}

let default_options = { width = 80; protect_banners = false }

(* Formatting result: the new text, plus warnings (line, message) for comments
   left unformatted because they were ambiguous. *)
type result = { output : string; warnings : (int * string) list }

type comment = {
  start : int;        (* byte index of '(' in "(*" *)
  stop : int;         (* byte index just past "*)" *)
  indent : string;    (* leading whitespace of the line, when standalone *)
  standalone : bool;  (* only whitespace precedes "(*" on its line *)
}

(* A comment body is split into paragraphs (by blank lines, fence-aware); each
   paragraph is a sequence of segments: prose lines and verbatim fenced blocks. *)
type seg = SLine of string | SFence of string list | STable of string list

(* A paragraph splits into units: lead prose and marked list items. An item's
   content is a sequence of chunks: prose runs (filled) and fences (verbatim). *)
type chunk = CText of string list | CFence of string list | CTable of string list
type punit = ULead of chunk list | UItem of string * int * chunk list
(* UItem (marker, content_indent, chunks): marker e.g. "-" / "1.", content_indent
   = even column where the item body and its continuations sit. *)

type rendered = Done of string | Skip of string  (* Skip = leave verbatim + warn *)

(* ------------------------------------------------------------------ *)
(* Small string helpers                                                *)
(* ------------------------------------------------------------------ *)

(* Number of Unicode scalar values (not bytes): count non-continuation bytes. *)
let utf8_len s =
  let n = String.length s and c = ref 0 in
  for k = 0 to n - 1 do
    if Char.code s.[k] land 0xC0 <> 0x80 then incr c
  done;
  !c

let is_ws c = c = ' ' || c = '\t' || c = '\n' || c = '\r'

let lstrip s =
  let n = String.length s in
  let i = ref 0 in
  while !i < n && (s.[!i] = ' ' || s.[!i] = '\t') do incr i done;
  String.sub s !i (n - !i)

let rstrip s =
  let n = ref (String.length s) in
  while !n > 0 && (let c = s.[!n - 1] in c = ' ' || c = '\t' || c = '\r') do
    decr n
  done;
  String.sub s 0 !n

(* Number of leading spaces. *)
let indent_of l =
  let n = String.length l in
  let i = ref 0 in
  while !i < n && l.[!i] = ' ' do incr i done;
  !i

let spaces n = String.make (max 0 n) ' '

let split_lines s =
  String.split_on_char '\n' s
  |> List.map (fun l ->
         let n = String.length l in
         if n > 0 && l.[n - 1] = '\r' then String.sub l 0 (n - 1) else l)

let line_of s off =
  let n = ref 1 in
  for k = 0 to off - 1 do if s.[k] = '\n' then incr n done;
  !n

(* ------------------------------------------------------------------ *)
(* UTF-8 scalar decoding + table (box-drawing / ASCII) char classes    *)
(* ------------------------------------------------------------------ *)

(* Split a string into its UTF-8 scalar substrings (1-4 bytes each). *)
let utf8_chars s =
  let n = String.length s in
  let rec go i acc =
    if i >= n then List.rev acc
    else begin
      let j = ref (i + 1) in
      while !j < n && Char.code s.[!j] land 0xC0 = 0x80 do incr j done;
      go !j (String.sub s i (!j - i) :: acc)
    end
  in
  go 0 []

(* Codepoint of the first UTF-8 scalar of [s] (0 on empty). *)
let cp_of_char s =
  let n = String.length s in
  if n = 0 then 0
  else
    let b k = Char.code s.[k] in
    let b0 = b 0 in
    if b0 < 0x80 then b0
    else if b0 < 0xE0 && n >= 2 then ((b0 land 0x1F) lsl 6) lor (b 1 land 0x3F)
    else if b0 < 0xF0 && n >= 3 then
      ((b0 land 0x0F) lsl 12) lor ((b 1 land 0x3F) lsl 6) lor (b 2 land 0x3F)
    else if n >= 4 then
      ((b0 land 0x07) lsl 18) lor ((b 1 land 0x3F) lsl 12)
      lor ((b 2 land 0x3F) lsl 6) lor (b 3 land 0x3F)
    else b0

(* Table frames are vertical separators, horizontal rules and junctions
   (corners / tees / cross). The Unicode box-drawing block is U+2500..U+257F;
   ASCII '|' '-' '+' are their plain-text equivalents. Any box glyph that is
   neither a pure vertical nor a pure horizontal acts as a junction, so every
   corner / tee / cross variant (light, heavy, double, rounded) is covered. *)
let box_cp cp = cp >= 0x2500 && cp <= 0x257F
let vbar_cp cp = cp = 0x7C || cp = 0x2502 || cp = 0x2503 || cp = 0x2551
let hbar_cp cp = cp = 0x2D || cp = 0x2500 || cp = 0x2501 || cp = 0x2550
let junction_cp cp =
  cp = 0x2B || (box_cp cp && (not (vbar_cp cp)) && not (hbar_cp cp))

let is_vbar c = vbar_cp (cp_of_char c)
let is_hbar c = hbar_cp (cp_of_char c)
let is_junction c = junction_cp (cp_of_char c)

(* ------------------------------------------------------------------ *)
(* Stage 0: lex the file into comment spans                            *)
(* ------------------------------------------------------------------ *)

(* Skip a string literal in [s] starting just after the opening quote at index
   [i]. Returns the index just past the closing quote. "" is an embedded quote.
   [line_start] is updated on newlines so standalone-detection stays correct. *)
let skip_string s n i line_start =
  let i = ref i in
  let fin = ref false in
  while (not !fin) && !i < n do
    (match s.[!i] with
     | '"' ->
       if !i + 1 < n && s.[!i + 1] = '"' then i := !i + 2
       else (incr i; fin := true)
     | '\n' -> incr i; line_start := !i
     | _ -> incr i)
  done;
  !i

let scan (s : string) : comment list =
  let n = String.length s in
  let comments = ref [] in
  let line_start = ref 0 in
  let i = ref 0 in
  while !i < n do
    let c = s.[!i] in
    if c = '\n' then (incr i; line_start := !i)
    else if c = '"' then i := skip_string s n (!i + 1) line_start
    else if c = '(' && !i + 1 < n && s.[!i + 1] = '*' then begin
      let cstart = !i in
      let standalone =
        let rec chk k =
          k >= cstart || ((s.[k] = ' ' || s.[k] = '\t') && chk (k + 1))
        in
        chk !line_start
      in
      let indent = String.sub s !line_start (cstart - !line_start) in
      i := !i + 2;
      let depth = ref 1 in
      while !depth > 0 && !i < n do
        if !i + 1 < n && s.[!i] = '(' && s.[!i + 1] = '*' then
          (incr depth; i := !i + 2)
        else if !i + 1 < n && s.[!i] = '*' && s.[!i + 1] = ')' then
          (decr depth; i := !i + 2)
        else if s.[!i] = '"' then i := skip_string s n (!i + 1) line_start
        else if s.[!i] = '\n' then (incr i; line_start := !i)
        else incr i
      done;
      comments :=
        { start = cstart; stop = !i; indent; standalone } :: !comments
    end
    else incr i
  done;
  List.rev !comments

let inner_of s c =
  let a = c.start + 2 and b = c.stop - 2 in
  if b <= a then "" else String.sub s a (b - a)

(* Concatenation of all NON-comment regions. *)
let code_only s =
  let cs = scan s in
  let out = Buffer.create (String.length s) in
  let cur = ref 0 in
  List.iter
    (fun c ->
      Buffer.add_substring out s !cur (c.start - !cur);
      cur := c.stop)
    cs;
  Buffer.add_substring out s !cur (String.length s - !cur);
  Buffer.contents out

(* code_only with all whitespace removed: the strongest safety signature.
   Formatting must never change it (only comment spans are rewritten, and
   inter-comment whitespace consumed by merging is not significant in Coq). *)
let code_sig s =
  code_only s |> String.to_seq |> Seq.filter (fun c -> not (is_ws c))
  |> String.of_seq

(* ------------------------------------------------------------------ *)
(* Stage 4 helpers: protected groups and atom tokenizer                *)
(* ------------------------------------------------------------------ *)

(* If [s.[i]] opens a protected group ( '(' '[' '`' '$' or "```" ), return the
   index just past its matching close; nested ()/[] and backtick/dollar spans
   are skipped. Returns None if no matching close exists in [s]. *)
let rec scan_protected s i =
  let n = String.length s in
  if i >= n then None
  else
    match s.[i] with
    | '`' ->
      if i + 2 < n && s.[i + 1] = '`' && s.[i + 2] = '`' then
        let rec f k =
          if k + 2 >= n then None
          else if s.[k] = '`' && s.[k + 1] = '`' && s.[k + 2] = '`' then
            Some (k + 3)
          else f (k + 1)
        in
        f (i + 3)
      else
        let rec f k =
          if k >= n then None else if s.[k] = '`' then Some (k + 1) else f (k + 1)
        in
        f (i + 1)
    | '$' ->
      let rec f k =
        if k >= n then None else if s.[k] = '$' then Some (k + 1) else f (k + 1)
      in
      f (i + 1)
    | ('(' | '[') as oc ->
      let cc = if oc = '(' then ')' else ']' in
      let rec go k =
        if k >= n then None
        else if s.[k] = cc then Some (k + 1)
        else
          match s.[k] with
          | '(' | '[' | '`' | '$' -> (
            match scan_protected s k with Some k' -> go k' | None -> go (k + 1))
          | _ -> go (k + 1)
      in
      go (i + 1)
    | _ -> None

(* Copy s[i..j) into [buf], collapsing runs of whitespace to a single space. *)
let append_collapsed buf s i j =
  let prev_ws = ref false in
  for k = i to j - 1 do
    let c = s.[k] in
    if is_ws c then (if not !prev_ws then Buffer.add_char buf ' '; prev_ws := true)
    else (Buffer.add_char buf c; prev_ws := false)
  done

(* Split [s] into atoms separated by whitespace runs. An atom is a maximal run
   of non-whitespace, except that a protected group ((...) [...] `...` $...$
   ```) is kept whole even if it contains spaces. *)
let tokenize (s : string) : string list =
  let n = String.length s in
  let atoms = ref [] in
  let i = ref 0 in
  let skip_ws () = while !i < n && is_ws s.[!i] do incr i done in
  skip_ws ();
  while !i < n do
    let buf = Buffer.create 16 in
    let go = ref true in
    while !go do
      if !i >= n then go := false
      else
        let c = s.[!i] in
        if is_ws c then go := false
        else
          match c with
          | '(' | '[' | '`' | '$' -> (
            match scan_protected s !i with
            | Some j -> append_collapsed buf s !i j; i := j
            | None -> Buffer.add_char buf c; incr i)
          | _ -> Buffer.add_char buf c; incr i
    done;
    atoms := Buffer.contents buf :: !atoms;
    skip_ws ()
  done;
  List.rev !atoms

(* ------------------------------------------------------------------ *)
(* Stage 5: greedy fill                                                *)
(* ------------------------------------------------------------------ *)

(* A lone sentence dash (ASCII "-", en/em dash) or a lone numbered token ("5.",
   "12)") is glued to the preceding atom so it never begins a wrapped line —
   where it would be mistaken for a list marker and break idempotency. Genuine
   list markers are stripped before filling, so they are never glue candidates. *)
let is_dash a = a = "-" || a = "\xE2\x80\x93" (* – *) || a = "\xE2\x80\x94" (* — *)

let is_num_token a =
  let n = String.length a in
  n >= 2
  && (a.[n - 1] = '.' || a.[n - 1] = ')')
  &&
  let ok = ref true in
  for k = 0 to n - 2 do
    if not (a.[k] >= '0' && a.[k] <= '9') then ok := false
  done;
  !ok

let glue_atoms atoms =
  List.rev
    (List.fold_left
       (fun acc a ->
         match acc with
         | prev :: rest when is_dash a || is_num_token a -> (prev ^ " " ^ a) :: rest
         | _ -> a :: acc)
       [] atoms)

let fill tw atoms =
  let tw = max 1 tw in
  let atoms = glue_atoms atoms in
  let lines = ref [] in
  let cur = Buffer.create 80 in
  let curw = ref 0 in
  let flush () =
    if Buffer.length cur > 0 then begin
      lines := Buffer.contents cur :: !lines;
      Buffer.clear cur;
      curw := 0
    end
  in
  List.iter
    (fun a ->
      let aw = utf8_len a in
      if !curw = 0 then (Buffer.add_string cur a; curw := aw)
      else if !curw + 1 + aw <= tw then
        (Buffer.add_char cur ' '; Buffer.add_string cur a; curw := !curw + 1 + aw)
      else (flush (); Buffer.add_string cur a; curw := aw))
    atoms;
  flush ();
  List.rev !lines

(* ------------------------------------------------------------------ *)
(* Stage 3: fence-aware paragraph splitting                            *)
(* ------------------------------------------------------------------ *)

let line_has_triple l =
  let n = String.length l in
  let rec f k =
    if k + 2 >= n then false
    else if l.[k] = '`' && l.[k + 1] = '`' && l.[k + 2] = '`' then true
    else f (k + 1)
  in
  f 0

(* A line opens a fence iff it starts (after indent) with ``` not closed on the
   same line. *)
let is_fence_open l =
  let t = lstrip l in
  String.length t >= 3 && t.[0] = '`' && t.[1] = '`' && t.[2] = '`'
  && not
       (let rec has k =
          if k + 2 >= String.length t then false
          else if t.[k] = '`' && t.[k + 1] = '`' && t.[k + 2] = '`' then true
          else has (k + 1)
        in
        has 3)

(* ------------------------------------------------------------------ *)
(* Table detection: a run of consecutive *rule* lines (only horizontal /
   junction glyphs, >=2 junctions) and *row* lines (starting with a vertical
   separator). A genuine table needs at least one of each, so lone dividers
   and stray pipe-prefixed prose stay prose.                                *)
(* ------------------------------------------------------------------ *)

type tline = Rule | Row | NotTable

let classify_tline l =
  match utf8_chars (lstrip l) with
  | [] -> NotTable
  | c0 :: _ as cs ->
    if is_vbar c0 then Row
    else begin
      let ok = ref true and nj = ref 0 and nh = ref 0 in
      List.iter
        (fun c ->
          if c = " " then ()
          else if is_junction c then incr nj
          else if is_hbar c then incr nh
          else ok := false)
        cs;
      if !ok && !nj >= 2 && !nh >= 1 then Rule else NotTable
    end

(* Maximal prefix of consecutive table lines, and the remaining lines. *)
let table_run lines =
  let rec take acc = function
    | l :: rest when classify_tline l <> NotTable -> take (l :: acc) rest
    | rest -> (List.rev acc, rest)
  in
  take [] lines

let run_is_table run =
  List.length run >= 2
  && List.exists (fun l -> classify_tline l = Rule) run
  && List.exists (fun l -> classify_tline l = Row) run

(* Split body lines into paragraphs (separated by blank lines, but a blank line
   inside a fence does not split). Each paragraph is a list of segments. *)
let paragraphs lines =
  let paras = ref [] and cur = ref [] in
  let flush () = if !cur <> [] then (paras := List.rev !cur :: !paras; cur := []) in
  let rec go = function
    | [] -> flush ()
    | l :: rest when is_fence_open l ->
      let fence = ref [ l ] in
      let rec coll = function
        | [] -> []
        | x :: xs -> fence := x :: !fence; if line_has_triple x then xs else coll xs
      in
      let rest' = coll rest in
      cur := SFence (List.rev !fence) :: !cur;
      go rest'
    | (_ :: _) as ls when run_is_table (fst (table_run ls)) ->
      let run, rest' = table_run ls in
      cur := STable run :: !cur;
      go rest'
    | l :: rest when String.trim l = "" -> flush (); go rest
    | l :: rest -> cur := SLine l :: !cur; go rest
  in
  go lines;
  List.rev !paras

(* ------------------------------------------------------------------ *)
(* Lists: ASCII "- " or "N." / "N)" at line start. En/em dashes and mid-line
   "-" are prose (glued off line starts). Dash items use a 2-space body indent,
   numbered items a 4-space (even) one.                                        *)
(* ------------------------------------------------------------------ *)

(* On an lstripped line: Some (marker, content_indent, rest) if it is a list
   item. content_indent is even-ish: 2 for "-", 4 for numbered (>=marker+1). *)
let marker_split li =
  let n = String.length li in
  let skip_sp k =
    let k = ref k in
    while !k < n && (li.[!k] = ' ' || li.[!k] = '\t') do incr k done;
    !k
  in
  if n >= 2 && li.[0] = '-' && li.[1] = ' ' then
    let r = skip_sp 1 in
    Some ("-", 2, String.sub li r (n - r))
  else begin
    let j = ref 0 in
    while !j < n && li.[!j] >= '0' && li.[!j] <= '9' do incr j done;
    if
      !j > 0 && !j < n
      && (li.[!j] = '.' || li.[!j] = ')')
      && !j + 1 < n && li.[!j + 1] = ' '
    then
      let marker = String.sub li 0 (!j + 1) in
      let r = skip_sp (!j + 1) in
      Some (marker, max 4 (utf8_len marker + 1), String.sub li r (n - r))
    else None
  end

let seg_indent = function
  | SLine l -> indent_of l
  | SFence (l :: _) | STable (l :: _) -> indent_of l
  | SFence [] | STable [] -> 0

let seg_is_marker = function SLine l -> marker_split (lstrip l) <> None | _ -> false
let seg_blank = function SLine l -> lstrip l = "" | SFence _ | STable _ -> false

(* Append a prose line / fence to a (forward) chunk list, merging adjacent
   prose into one CText run. *)
let add_text ch l =
  match List.rev ch with
  | CText ls :: rtl -> List.rev (CText (ls @ [ l ]) :: rtl)
  | _ -> ch @ [ CText [ l ] ]

let add_fence ch fl = ch @ [ CFence fl ]
let add_table ch tl = ch @ [ CTable tl ]

let split_units segs =
  let units = ref [] in
  let push u = units := u :: !units in
  let lead = ref [] in
  let item = ref None in
  let mind = ref (-1) in
  let flush_lead () = if !lead <> [] then (push (ULead !lead); lead := []) in
  let flush_item () =
    match !item with
    | Some (m, ci, ch) -> push (UItem (m, ci, ch)); item := None; mind := -1
    | None -> ()
  in
  List.iter
    (fun seg ->
      if seg_is_marker seg then begin
        flush_lead ();
        flush_item ();
        match seg with
        | SLine l -> (
          match marker_split (lstrip l) with
          | Some (m, ci, rest) -> mind := indent_of l; item := Some (m, ci, [ CText [ rest ] ])
          | None -> ())
        | SFence _ | STable _ -> ()
      end
      else if !item <> None && (not (seg_blank seg)) && seg_indent seg > !mind then
        match (!item, seg) with
        | Some (m, ci, ch), SLine l -> item := Some (m, ci, add_text ch (lstrip l))
        | Some (m, ci, ch), SFence fl -> item := Some (m, ci, add_fence ch fl)
        | Some (m, ci, ch), STable tl -> item := Some (m, ci, add_table ch tl)
        | None, _ -> ()
      else begin
        flush_item ();
        match seg with
        | SLine l -> if lstrip l <> "" then lead := add_text !lead (lstrip l)
        | SFence fl -> lead := add_fence !lead fl
        | STable tl -> lead := add_table !lead tl
      end)
    segs;
  flush_item ();
  flush_lead ();
  List.rev !units

(* A paragraph is ambiguous when it has exactly one marker followed by a
   non-blank segment at indent <= the marker's (an un-indented continuation):
   the signature of a sentence dash / numbered clause at a line start, not a
   list. We refuse to reformat the comment and warn. *)
let para_ambiguous segs =
  let arr = Array.of_list segs in
  let n = Array.length arr in
  let marks = ref [] in
  Array.iteri (fun i s -> if seg_is_marker s then marks := (i, seg_indent s) :: !marks) arr;
  match List.rev !marks with
  | [ (idx, mind) ] ->
    let bad = ref false in
    for k = idx + 1 to n - 1 do
      if (not (seg_is_marker arr.(k))) && (not (seg_blank arr.(k)))
         && seg_indent arr.(k) <= mind
      then bad := true
    done;
    !bad
  | _ -> false

(* ------------------------------------------------------------------ *)
(* Stage 6: render                                                     *)
(* ------------------------------------------------------------------ *)

(* Reposition a fenced block to column [tcol]: the opening and closing ``` go to
   [tcol]; content keeps its indentation relative to the original ``` (negatives
   clamped to 0), with the least-indented content line aligned to [tcol]. *)
let render_fence tcol lines =
  match lines with
  | [] -> []
  | first :: _ ->
    let n = List.length lines in
    let c = indent_of first in
    let last_is_close = n >= 2 && line_has_triple (List.nth lines (n - 1)) in
    let rel l = max 0 (indent_of l - c) in
    let min_rel =
      List.fold_left
        (fun acc (i, l) ->
          if i = 0 || (i = n - 1 && last_is_close) || String.trim l = "" then acc
          else min acc (rel l))
        max_int
        (List.mapi (fun i l -> (i, l)) lines)
    in
    let min_rel = if min_rel = max_int then 0 else min_rel in
    List.mapi
      (fun i l ->
        if i = 0 || (i = n - 1 && last_is_close) then spaces tcol ^ lstrip l
        else if String.trim l = "" then ""
        else spaces (tcol + max 0 (rel l - min_rel)) ^ lstrip l)
      lines

(* Split a row's char list on its vertical separators: "| a | b |" yields
   ["";" a ";" b ";""] (the empty ends are the outer borders). *)
let split_on_vbar chars =
  let pieces = ref [] and cur = Buffer.create 16 in
  List.iter
    (fun c ->
      if is_vbar c then (pieces := Buffer.contents cur :: !pieces; Buffer.clear cur)
      else Buffer.add_string cur c)
    chars;
  pieces := Buffer.contents cur :: !pieces;
  List.rev !pieces

(* A rule line's junction glyphs in order, and the box widths (glyph count)
   between consecutive junctions. *)
let rule_junctions_widths chars =
  let js = ref [] and ws = ref [] and cur = ref 0 and started = ref false in
  List.iter
    (fun c ->
      if is_junction c then begin
        if !started then ws := !cur :: !ws;
        js := c :: !js;
        cur := 0;
        started := true
      end
      else if !started then incr cur)
    chars;
  (List.rev !js, List.rev !ws)

let rule_hbar chars =
  match List.find_opt is_hbar chars with Some c -> c | None -> "-"

exception Bad_table

(* Sink for table-width warnings raised deep in rendering; drained per comment
   by [format_string], which knows the comment's source line. *)
let table_warn : string list ref = ref []

(* Render a detected table at column [tcol = col + the table's own indent].
   Each logical row (the rows between two rule lines) has its cells re-flowed
   (tokenize + fill) to its column, so prose rewraps inside cells while the
   grid stays intact. Rule lines are re-emitted from their own captured
   junction / hbar glyphs, so ASCII vs box style and top / middle / bottom
   borders are reproduced.

   Column widths honour the drawn border but never clip an unbreakable atom
   (a long citation or qualified name). If the table still does not fit the
   configured width, a warning is raised and the columns are reflowed to their
   minimal required widths (the narrowest that keeps every atom whole). A block
   that is not a clean grid is emitted verbatim — never corrupted. *)
let render_table opts col lines =
  let tmin = List.fold_left (fun a l -> min a (indent_of l)) max_int lines in
  let tmin = if tmin = max_int then 0 else tmin in
  let tcol = col + tmin in
  let verbatim () =
    List.map
      (fun l ->
        let l =
          if String.length l >= tmin then String.sub l tmin (String.length l - tmin)
          else lstrip l
        in
        spaces tcol ^ l)
      lines
  in
  try
    let kinds = List.map classify_tline lines in
    let lchars = List.map (fun l -> utf8_chars (lstrip l)) lines in
    let paired = List.combine kinds lchars in
    let first_rule =
      match List.find_opt (fun (k, _) -> k = Rule) paired with
      | Some (_, cs) -> cs
      | None -> raise Bad_table
    in
    let _, ws0 = rule_junctions_widths first_rule in
    let c = List.length ws0 in
    if c < 1 then raise Bad_table;
    let border_cw = List.map (fun w -> max 1 (w - 2)) ws0 in
    let vbar =
      match
        List.find_map
          (fun (k, cs) -> if k = Row then List.find_opt is_vbar cs else None)
          paired
      with
      | Some v -> v
      | None -> "\xE2\x94\x82" (* light │ *)
    in
    (* parse the lines into an ordered list of rule lines and logical rows *)
    let items = ref [] and group = ref [] in
    let flush_group () =
      match List.rev !group with
      | [] -> ()
      | rows ->
        let cell j =
          rows
          |> List.filter_map (fun r ->
                 let s = String.trim (List.nth r j) in
                 if s = "" then None else Some s)
          |> String.concat " "
        in
        items := `Row (List.init c cell) :: !items;
        group := []
    in
    List.iter2
      (fun k cs ->
        match k with
        | Rule ->
          flush_group ();
          let js, _ = rule_junctions_widths cs in
          if List.length js <> c + 1 then raise Bad_table;
          items := `Rule (js, rule_hbar cs) :: !items
        | Row ->
          let pieces = split_on_vbar cs in
          if List.length pieces <> c + 2 then raise Bad_table;
          group := List.filteri (fun i _ -> i >= 1 && i <= c) pieces :: !group
        | NotTable -> raise Bad_table)
      kinds lchars;
    flush_group ();
    let items = List.rev !items in
    (* Minimal feasible width per column = its widest unbreakable atom (a long
       citation or qualified name cannot wrap), at least 1. *)
    let m = Array.make c 1 in
    List.iter
      (function
        | `Rule _ -> ()
        | `Row cells ->
          List.iteri
            (fun j txt ->
              List.iter
                (fun a -> if utf8_len a > m.(j) then m.(j) <- utf8_len a)
                (tokenize txt))
            cells)
      items;
    (* Preferred widths honour the drawn border but never clip an atom. *)
    let pref = Array.of_list (List.mapi (fun j bw -> max bw m.(j)) border_cw) in
    let chrome = (3 * c) + 1 in
    let total a = tcol + chrome + Array.fold_left ( + ) 0 a in
    let cw =
      if total pref <= opts.width then pref
      else begin
        (* Does not fit the configured width: warn and reflow to the minimal
           required widths (the narrowest that keeps every atom whole). *)
        table_warn :=
          Printf.sprintf
            "table needs %d cols, over the %d-col width; reflowed columns to \
             their minimal widths"
            (total m) opts.width
          :: !table_warn;
        m
      end
    in
    let emit_rule (js, hbar) =
      let b = Buffer.create 80 in
      List.iteri
        (fun j jc ->
          Buffer.add_string b jc;
          if j < c then for _ = 1 to cw.(j) + 2 do Buffer.add_string b hbar done)
        js;
      [ Buffer.contents b ]
    in
    let emit_row cells =
      let wrapped =
        Array.of_list (List.mapi (fun j txt -> fill cw.(j) (tokenize txt)) cells)
      in
      let h = Array.fold_left (fun a l -> max a (List.length l)) 1 wrapped in
      let out = ref [] in
      for k = 0 to h - 1 do
        let b = Buffer.create 80 in
        Buffer.add_string b vbar;
        for j = 0 to c - 1 do
          let cl = match List.nth_opt wrapped.(j) k with Some s -> s | None -> "" in
          Buffer.add_char b ' ';
          Buffer.add_string b cl;
          Buffer.add_string b (spaces (cw.(j) - utf8_len cl));
          Buffer.add_char b ' ';
          Buffer.add_string b vbar
        done;
        out := Buffer.contents b :: !out
      done;
      List.rev !out
    in
    let body =
      List.concat_map
        (function `Rule r -> emit_rule r | `Row cs -> emit_row cs)
        items
    in
    List.map (fun l -> spaces tcol ^ l) body
  with Bad_table -> verbatim ()

(* Render a unit's chunks with their body at column [col]. *)
let render_chunks opts col chunks =
  List.concat_map
    (function
      | CText ls ->
        let atoms = tokenize (String.concat "\n" ls) in
        List.map (fun l -> spaces col ^ l) (fill (opts.width - col) atoms)
      | CFence fl -> render_fence col fl
      | CTable tl -> render_table opts col tl)
    chunks

let render_punit opts bi = function
  | ULead chunks -> render_chunks opts bi chunks
  | UItem (marker, cind, chunks) ->
    let ci = bi + cind in
    let lines = render_chunks opts ci chunks in
    let prefix = spaces bi ^ marker ^ spaces (cind - utf8_len marker) in
    (match lines with
     | [] -> [ spaces bi ^ marker ]
     | first :: rest ->
       (* [first] has ci leading spaces; swap them for the marker prefix, which
          has the same width (bi + cind). *)
       let text =
         if String.length first >= ci then String.sub first ci (String.length first - ci)
         else lstrip first
       in
       (prefix ^ text) :: rest)

let render_para opts bi segs =
  List.concat_map (render_punit opts bi) (split_units segs)

let render_block opts indent paras =
  let bi = utf8_len indent + 2 in
  let rendered = List.map (render_para opts bi) paras in
  let body =
    match rendered with
    | [] -> []
    | first :: rest -> first @ List.concat_map (fun p -> "" :: p) rest
  in
  String.concat "\n" (("(*" :: body) @ [ indent ^ "*)" ])

(* Render the logical body (dedented lines) of one comment. The returned string
   has no leading indent on its first line (the indent already precedes the
   splice point). Returns Skip to leave the comment verbatim with a warning. *)
let render opts indent lines =
  let fits text = utf8_len indent + 6 + utf8_len text <= opts.width in
  if lines = [] || List.for_all (fun l -> l = "") lines then Done "(* *)"
  else
    match lines with
    | [ one ] ->
      (* a single logical line: collapse to one line if it fits, else block *)
      let atoms = tokenize one in
      let text = String.concat " " atoms in
      if atoms <> [] && fits text then Done ("(* " ^ text ^ " *)")
      else Done (render_block opts indent (paragraphs lines))
    | _ ->
      let paras = paragraphs lines in
      if List.exists para_ambiguous paras then
        Skip
          "leading '-' or 'N.' looks like a sentence dash/clause (one-item \
           pseudo-list with an un-indented continuation), not a list"
      else begin
        (* single-line form: one paragraph, all prose, no markers, fits *)
        let single =
          match paras with
          | [ segs ]
            when List.for_all
                   (function
                     | SLine l -> marker_split (lstrip l) = None
                     | SFence _ | STable _ -> false)
                   segs ->
            let atoms =
              tokenize
                (String.concat "\n"
                   (List.map
                      (function SLine l -> lstrip l | SFence _ | STable _ -> "")
                      segs))
            in
            if atoms <> [] && fits (String.concat " " atoms) then
              Some ("(* " ^ String.concat " " atoms ^ " *)")
            else None
          | _ -> None
        in
        match single with Some r -> Done r | None -> Done (render_block opts indent paras)
      end

(* ------------------------------------------------------------------ *)
(* Stages 1-2 + 7: group standalone comments, splice                   *)
(* ------------------------------------------------------------------ *)

let norm_dir t =
  t
  |> String.split_on_char '\t' |> String.concat ""
  |> String.split_on_char ' ' |> String.concat ""
  |> String.lowercase_ascii

let is_directive_off t = norm_dir t = "format:off"
let is_directive_on t = norm_dir t = "format:on"

let is_banner t =
  String.length t >= 4 && String.for_all (fun c -> c = '=' || c = '-' || c = '*') t

let is_coqdoc s c =
  c.start + 2 < String.length s
  && s.[c.start] = '(' && s.[c.start + 1] = '*' && s.[c.start + 2] = '*'

(* The gap s[a..b) is a single newline plus optional spaces/tabs (no blank
   line), i.e. the two comments sit on consecutive lines. *)
let gap_single_newline s a b =
  let nl = ref 0 and ok = ref true in
  for k = a to b - 1 do
    match s.[k] with
    | ' ' | '\t' | '\r' -> ()
    | '\n' -> incr nl
    | _ -> ok := false
  done;
  !ok && !nl = 1

(* Logical, dedented lines of a comment group: concatenate members' inner text,
   drop leading/trailing blank lines, and strip the common indentation so list
   structure is visible at relative column 0. *)
let body_lines s members =
  let raw = List.concat_map (fun m -> split_lines (inner_of s m)) members in
  let raw = List.map rstrip raw in
  let rec drop_blank = function "" :: t -> drop_blank t | l -> l in
  let raw = drop_blank raw in
  let raw = List.rev (drop_blank (List.rev raw)) in
  let mind =
    List.fold_left
      (fun acc l -> if l = "" then acc else min acc (indent_of l))
      max_int raw
  in
  let mind = if mind = max_int then 0 else mind in
  List.map
    (fun l ->
      if l = "" then ""
      else if String.length l >= mind then String.sub l mind (String.length l - mind)
      else l)
    raw

let format_string opts s =
  let arr = Array.of_list (scan s) in
  let len = Array.length arr in
  let skip c =
    (not c.standalone) || is_coqdoc s c
    || (opts.protect_banners && is_banner (String.trim (inner_of s c)))
  in
  let edits = ref [] and warnings = ref [] in
  let fmt_off = ref false in
  let i = ref 0 in
  while !i < len do
    let c = arr.(!i) in
    let trimmed = String.trim (inner_of s c) in
    if is_directive_off trimmed then (fmt_off := true; incr i)
    else if is_directive_on trimmed then (fmt_off := false; incr i)
    else if !fmt_off || skip c then incr i
    else begin
      (* Collect a maximal run of consecutive, groupable, standalone comments. *)
      let j = ref !i in
      let members = ref [ c ] in
      let continue = ref true in
      while !continue do
        if !j + 1 >= len then continue := false
        else begin
          let cur = arr.(!j) and nxt = arr.(!j + 1) in
          let nxt_inner = String.trim (inner_of s nxt) in
          if
            nxt.standalone
            && gap_single_newline s cur.stop nxt.start
            && (not (is_directive_off nxt_inner))
            && (not (is_directive_on nxt_inner))
            && not (skip nxt)
          then (members := nxt :: !members; incr j)
          else continue := false
        end
      done;
      let members = List.rev !members in
      let first = List.hd members in
      let last = List.nth members (List.length members - 1) in
      let ln = line_of s first.start in
      table_warn := [];
      (match render opts first.indent (body_lines s members) with
       | Done rep -> edits := (first.start, last.stop, rep) :: !edits
       | Skip reason -> warnings := (ln, "not formatted: " ^ reason) :: !warnings);
      (* surface any table-width warnings raised while rendering this comment *)
      List.iter (fun msg -> warnings := (ln, msg) :: !warnings) (List.rev !table_warn);
      table_warn := [];
      i := !j + 1
    end
  done;
  let edits = List.sort (fun (a, _, _) (b, _, _) -> compare a b) !edits in
  let out = Buffer.create (String.length s) in
  let cursor = ref 0 in
  List.iter
    (fun (st, sp, rep) ->
      Buffer.add_substring out s !cursor (st - !cursor);
      Buffer.add_string out rep;
      cursor := sp)
    edits;
  Buffer.add_substring out s !cursor (String.length s - !cursor);
  { output = Buffer.contents out; warnings = List.rev !warnings }
