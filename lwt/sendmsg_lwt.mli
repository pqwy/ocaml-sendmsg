(* Copyright (c) 2016 David Kaloper Meršinjak. All rights reserved.
   See LICENSE.md. *)

(** sendmsg(3) / recvmsg(3) with socket-passing for {!Lwt}

    This module mirrors {!Sendmsg}. Consult that interface for details.

    {e %%VERSION%% — {{:%%PKG_HOMEPAGE%% }homepage}} *)

(** {1 Sendmsg_lwt} *)


open Lwt_unix

val send  : file_descr -> ?fd:file_descr -> bytes -> int -> int -> int Lwt.t

val recv  : file_descr -> bytes -> int -> int -> (int * file_descr option) Lwt.t

val sendv : file_descr -> ?fd:file_descr -> bytes array -> int Lwt.t

val recvv : file_descr -> bytes array -> (int * file_descr option) Lwt.t
