open Alcotest
open Lwt.Infix

let closepair f1 f2 = Lwt_unix.(close f1 >>= fun _ -> close f2)

let with_socketpair a =
  let (s1, s2) = Lwt_unix.(socketpair PF_UNIX SOCK_STREAM 0) in
  let close () = closepair s1 s2 in
  Lwt.catch (fun () -> a s1 s2 >>= fun res -> close () >|= fun _ -> res)
    (fun exn -> close () >>= fun _ -> Lwt.fail exn)

let lim = 1024

let wr fd buf =
  Lwt_unix.write fd (Bytes.unsafe_of_string buf) 0 (String.length buf)
let rd fd =
  let buf = Bytes.create lim in
  Lwt_unix.read fd buf 0 lim >|= fun n ->
    Bytes.(sub buf 0 n |> unsafe_to_string)

let sendmsg f ?fd buf =
  Sendmsg_lwt.send f ?fd (Bytes.unsafe_of_string buf) 0 (String.length buf)
let recvmsg f =
  let buf = Bytes.create 1024 in
  Sendmsg_lwt.recv f buf 0 lim >|= fun (n, x) ->
    (Bytes.(sub buf 0 n |> unsafe_to_string), x)

let pass n s1 s2 =
  let msg = "message-" ^ string_of_int n in
  let a1 =
    let (p2, p1) = Lwt_unix.pipe () in
    wr p1 "tag" >>= fun _ ->
      sendmsg s1 ~fd:p2 msg >>= fun _ ->
        closepair p1 p2
  and a2 = recvmsg s2 >>= function
    | (msg', Some p) ->
        check string "socket msg" msg msg';
        rd p >>= fun msg ->
          check string "pipe msg" "tag" msg; Lwt_unix.close p
    | _ -> fail "didn't recv pipe" in
  a1 <&> a2

let rec l1 s1 s2 = function
  | 0 -> Lwt.return_unit
  | n -> pass n s1 s2 >>= fun _ -> l1 s1 s2 (pred n)

let rec l2 k = function
  | 0 -> Lwt.return_unit
  | n -> with_socketpair (fun s1 s2 -> l1 s1 s2 k) >>= fun _ -> l2 k (pred n)

let pingpong () = Lwt_main.run (l2 100 100)

let () = Alcotest.run "sendmsg lwt" [
  "stress", [ "pingpong", `Slow, pingpong ]
]
