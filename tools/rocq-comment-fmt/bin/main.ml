let usage =
  "rocq-comment-fmt [--write] [--check] [--width N] [--protect-banners] \
   <files-or-dirs...>\n\n\
   Default: print formatted result to stdout.\n\
   --write            edit files in place.\n\
   --check            exit 1 if any file would change (prints nothing).\n\
   --protect-banners  leave (* ==== *) banner comments untouched.\n\
   Coqdoc (** ... *) comments are always preserved verbatim.\n"

let read_file path =
  let ic = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr ic)
    (fun () -> really_input_string ic (in_channel_length ic))

let write_file path s =
  let oc = open_out_bin path in
  Fun.protect ~finally:(fun () -> close_out_noerr oc) (fun () -> output_string oc s)

let rec collect path acc =
  if not (Sys.file_exists path) then (
    Printf.eprintf "rocq-comment-fmt: no such path: %s\n" path;
    acc)
  else if Sys.is_directory path then
    Sys.readdir path |> Array.to_list |> List.sort compare
    |> List.fold_left (fun acc e -> collect (Filename.concat path e) acc) acc
  else if Filename.check_suffix path ".v" then path :: acc
  else acc

let () =
  let width = ref 80
  and write = ref false
  and check = ref false
  and protect_banners = ref false
  and paths = ref [] in
  let rec parse = function
    | [] -> ()
    | "--write" :: r -> write := true; parse r
    | "--check" :: r -> check := true; parse r
    | "--protect-banners" :: r -> protect_banners := true; parse r
    | "--width" :: n :: r -> width := int_of_string n; parse r
    | ("-h" | "--help") :: _ -> print_string usage; exit 0
    | p :: r -> paths := p :: !paths; parse r
  in
  parse (List.tl (Array.to_list Sys.argv));
  if !paths = [] then (print_string usage; exit 2);
  let opts = Rcf.{ width = !width; protect_banners = !protect_banners } in
  let files = List.fold_left (fun acc p -> collect p acc) [] (List.rev !paths) in
  let files = List.rev files in
  let changed = ref false and bad = ref false in
  List.iter
    (fun f ->
      let s = read_file f in
      let r = Rcf.format_string opts s in
      let out = r.Rcf.output in
      List.iter
        (fun (ln, msg) -> Printf.eprintf "%s:%d: %s\n" f ln msg)
        r.Rcf.warnings;
      if Rcf.code_sig s <> Rcf.code_sig out then begin
        bad := true;
        Printf.eprintf
          "rocq-comment-fmt: INTERNAL ERROR: code changed in %s; refusing to \
           touch it\n"
          f
      end
      else begin
        if out <> s then begin
          changed := true;
          if !write then (write_file f out; Printf.eprintf "formatted %s\n" f)
          else if !check then Printf.eprintf "would format %s\n" f
        end;
        if (not !write) && not !check then print_string out
      end)
    files;
  if !bad then exit 3;
  if !check && !changed then exit 1
