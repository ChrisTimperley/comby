open Core

module Data = struct
  type t =
    { value : string
    ; range : Range.t
    }
  [@@deriving yojson, eq, sexp]
end

open Data
type data = Data.t
[@@deriving yojson, eq, sexp]

type t = data Core.String.Map.t

let create () : t =
  String.Map.empty

let vars (env : t) : string list =
  Map.keys env

let add ?(range = Range.default) (env : t) (var : string) (value : string) : t =
  Map.add env ~key:var ~data:{ value; range }
  |> function
  | `Duplicate -> env
  | `Ok env -> env

let lookup (env : t) (var : string) : string option =
  Map.find env var
  |> Option.map ~f:(fun { value; _ } -> value)

let lookup_range (env : t) (var : string) : Range.t option =
  Map.find env var
  |> Option.map ~f:(fun { range; _ } -> range)

let fold (env : t) =
  Map.fold env

let update env var value =
  Map.change env var ~f:(Option.map ~f:(fun result -> { result with value }))

let update_range env var range =
  Map.change env var ~f:(Option.map ~f:(fun result -> { result with range }))

let to_string env =
  Map.fold env ~init:"" ~f:(fun ~key:variable ~data:{ value; _ } acc ->
      Format.sprintf "%s |-> %s\n%s" variable value acc)

let furthest_match env =
  Map.fold
    env
    ~init:0
    ~f:(fun ~key:_ ~data:{ range = { match_start = { offset; _ }; _ }; _ } max ->
        Int.max offset max)

let equal env1 env2 =
  Map.equal Data.equal env1 env2

let merge env1 env2 =
  Map.merge_skewed env1 env2 ~combine:(fun ~key:_ v1 _ -> v1)

let copy env =
  fold env ~init:(create ()) ~f:(fun ~key ~data:{ value; range } env' ->
      add ~range env' key value)

let to_yojson env : Yojson.Safe.json =
  let s =
    Map.fold_right env ~init:[] ~f:(fun ~key:variable ~data:{value; range} acc ->
        let item =
          `Assoc
            [ ("variable", `String variable)
            ; ("value", `String value)
            ; ("range", Range.to_yojson range)
            ]
        in
        item::acc)
  in
  `List s

let of_yojson _ = assert false
