(* owl_constraints.ml — CHC-style refine over neural outputs.
   Compiled to a C-callable object and linked into the host.
   Constraint spec is a line-oriented program:
     clamp <i> <lo> <hi>
     proj  <i> <eps>
     ident
   Clause heads are disjoined; identity is the forced-totality default. *)

type lit =
  | Clamp of int * float * float
  | Proj of int * float
  | Ident

type clause = lit list

let parse_spec (spec : string) : clause list =
  let clauses = ref [] in
  let cur = ref [] in
  let flush () =
    if !cur <> [] then begin
      clauses := List.rev !cur :: !clauses;
      cur := []
    end
  in
  String.split_on_char '\n' spec
  |> List.iter (fun raw ->
         let line = String.trim raw in
         if line = "" || String.get line 0 = '%' then ()
         else if line = "clause" || line = "." then flush ()
         else
           match String.split_on_char ' ' line |> List.filter ((<>) "") with
           | [ "clamp"; i; lo; hi ] ->
               cur := Clamp (int_of_string i, float_of_string lo, float_of_string hi) :: !cur
           | [ "proj"; i; eps ] ->
               cur := Proj (int_of_string i, float_of_string eps) :: !cur
           | [ "ident" ] -> cur := Ident :: !cur
           | _ -> ());
  flush ();
  List.rev !clauses

let apply_lit neural refined = function
  | Clamp (i, lo, hi) ->
      let v = neural.(i) in
      refined.(i) <- min hi (max lo v);
      true
  | Proj (i, eps) ->
      let v = neural.(i) in
      let r = refined.(i) in
      refined.(i) <- min (v +. eps) (max (v -. eps) r);
      true
  | Ident ->
      Array.blit neural 0 refined 0 (Array.length neural);
      true

let solve (neural_out : float array) (constraint_spec : string) : float array =
  let refined = Array.copy neural_out in
  let clauses = parse_spec constraint_spec in
  let any = ref false in
  List.iter
    (fun clause ->
      let trial = Array.copy refined in
      let ok = List.for_all (apply_lit neural_out trial) clause in
      if ok then begin
        Array.blit trial 0 refined 0 (Array.length trial);
        any := true
      end)
    clauses;
  if not !any then Array.blit neural_out 0 refined 0 (Array.length neural_out);
  refined

let owl_init () = ()

let () =
  Callback.register "owl_init" owl_init;
  Callback.register "owl_constraint_solve" solve
