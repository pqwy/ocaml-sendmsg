(* Copyright (c) 2016 David Kaloper Meršinjak. All rights reserved.
   See LICENSE.md. *)

external send  : Unix.file_descr -> ?fd:Unix.file_descr -> bytes -> int -> int -> int = "caml_sendmsg_send"
external recv  : Unix.file_descr -> bytes -> int -> int -> int * Unix.file_descr option = "caml_sendmsg_recv"
external sendv : Unix.file_descr -> ?fd:Unix.file_descr -> bytes array -> int = "caml_sendmsg_sendv"
external recvv : Unix.file_descr -> bytes array -> int * Unix.file_descr option = "caml_sendmsg_recvv"
