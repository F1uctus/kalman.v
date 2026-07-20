(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  The float ring instantiation of the generic figure documents.
*)

let zero : float = 0.
let one : float = 1.
let opp : float -> float = (~-.)
let add : float -> float -> float = ( +. )
let mul : float -> float -> float = ( *. )
let inv : float -> float = fun x -> 1. /. x
