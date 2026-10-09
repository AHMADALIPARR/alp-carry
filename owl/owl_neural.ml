(* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 *)

(* owl_neural.ml — tensor surface used by the Janet bridge and the DSPy loop *)
open Owl

let create_tensor dims = Arr.zeros dims

let linear (x : Arr.arr) (w : Arr.arr) (b : Arr.arr) =
  Arr.(x *@ w + b)

let attention (query : Arr.arr) (key : Arr.arr) (value : Arr.arr) =
  let scores = Arr.(query *@ transpose key) in
  let weights = Arr.(softmax scores) in
  Arr.(weights *@ value)

let gradient (loss_fn : unit -> float) =
  Grad.grad loss_fn

let relu x = Arr.map (fun v -> if v > 0. then v else 0.) x
let sigmoid x = Arr.map (fun v -> 1. /. (1. +. exp (-.v))) x
let tanh_act x = Arr.tanh x
