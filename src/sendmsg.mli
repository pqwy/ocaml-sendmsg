(* Copyright (c) 2016 David Kaloper Meršinjak. All rights reserved.
   See LICENSE.md. *)

(** sendmsg(3) / recvmsg(3) with socket-passing

    {e %%VERSION%% — {{:%%PKG_HOMEPAGE%% }homepage}} *)

(** {1 Sendmsg}

    For detailed semantics of these functions, consult the
    {{: https://linux.die.net/man/3/sendmsg}{b sendmsg (3)}} and
    {{: https://linux.die.net/man/3/recvmsg}{b recvmsg (3)}}
    man pages. *)

val send : Unix.file_descr -> ?fd:Unix.file_descr -> bytes -> int -> int -> int
(** [send sock ?fd buf off n] sends up to [n] bytes of [buf], starting from
    [off], over [sock]. [fs] is attached as ancillary data. Returns the number
    of bytes sent.

    @raise Unix_error on {b ERRNO}. *)

val recv : Unix.file_descr -> bytes -> int -> int -> int * Unix.file_descr option
(** [recv sock ?fd off n] reads up to [n] bytes into [buf], starting from
    [off], from [sock]. Returns [(n, fd)], where [n] is the number of bytes
    read, and [fd] is the optional file descriptor attached to the message.

    @raise Unix_error on {b ERRNO}. *)

val sendv : Unix.file_descr -> ?fd:Unix.file_descr -> bytes array -> int
(** [sendv sock ?fd bytesv] is the scatter-gather version of {{!send}[send]}.
    It sends the contents of all bytes in [bytesv], in order. Returns the
    number of bytes sent.

    @raise Unix_error on {b ERRNO}. *)

val recvv : Unix.file_descr -> bytes array -> int * Unix.file_descr option
(** [recvv sock bytesv] is the scatter-gather version of {{!recv}[recv]}.
    Input is gathered into the arrays in [bytesv], in order. Returns the
    total number of bytes read, and an optional file descriptor.

    @raise Unix_error on {b ERRNO}. *)
