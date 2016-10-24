(* Copyright (c) 2016 David Kaloper Meršinjak. All rights reserved.
   See LICENSE.md. *)

open Lwt
open Lwt_unix

let result = function
  | (n, Some fd) -> (n, Some (of_unix_file_descr fd))
  | (n, None)    -> (n, None)

let usock = unix_file_descr

let usocko = function Some fd -> Some (unix_file_descr fd) | _ -> None

let send s ?fd buf i n =
  wrap_syscall Write s @@ fun () ->
    Sendmsg.send (usock s) ?fd:(usocko fd) buf i n

let recv s buf i n =
  wrap_syscall Read s @@ fun () ->
    Sendmsg.recv (usock s) buf i n |> result

let sendv s ?fd bufs =
  wrap_syscall Write s @@ fun () ->
    Sendmsg.sendv (usock s) ?fd:(usocko fd) bufs

let recvv s bufs =
  wrap_syscall Read s @@ fun () ->
    Sendmsg.recvv (usock s) bufs |> result
