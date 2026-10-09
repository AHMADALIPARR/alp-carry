(* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 *)

(* owl_bridge.ml — register the Owl surface for the Janet side *)
open Owl

let attention query key value =
  let scores = Arr.(query *@ transpose key) in
  let weights = Arr.(softmax scores) in
  Arr.(weights *@ value)

let register_functions () =
  Callback.register "create_tensor" (fun dims -> Arr.zeros dims);
  Callback.register "linear" (fun x w b -> Arr.(x *@ w + b));
  Callback.register "attention" attention;
  Callback.register "matmul" (fun a b -> Arr.(a *@ b));
  Callback.register "transpose" Arr.transpose;
  Callback.register "softmax" Arr.softmax;
  Callback.register "relu" (Arr.map (fun v -> if v > 0. then v else 0.));
  Callback.register "sigmoid" (Arr.map (fun v -> 1. /. (1. +. exp (-.v))));
  Callback.register "tanh" Arr.tanh

let () =
  register_functions ();
  print_endline "Owl-Janet bridge initialized"
