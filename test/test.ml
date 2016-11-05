(* open OUnit2 *)
open Unix
open Alcotest


let fd : file_descr testable =
  testable (fun ppf fd -> Fmt.pf ppf "fd:%d" (Obj.magic fd)) (=)

let ret = pair int (option fd)

let bracket ~init ~fini f =
  let x = init () in
  match f x with
  | res           -> fini x; res
  | exception exn -> fini x; raise exn

let with_socketpair f = bracket f
  ~init:(fun () -> socketpair PF_UNIX SOCK_STREAM 0)
  ~fini:(fun (s1, s2) -> close s1; close s2)

let send ?fd s buf = Sendmsg.send ?fd s buf 0 (Bytes.length buf)

let recv s =
  let buf = Bytes.create 64 in
  let (n, so) = Sendmsg.recv s buf 0 64 in
  (Bytes.sub buf 0 n, so)

let t_send () = with_socketpair @@ fun (s1, s2) ->
  let b1 = "abcdef" and b2 = "......" in
  check int "send1" 4 (Sendmsg.send s1 b1 0 4);
  check ret "recv1" (4, None) (Sendmsg.recv s2 b2 0 4);
  check int "send2" 2 (Sendmsg.send s1 b1 4 2);
  check ret "recv2" (2, None) (Sendmsg.recv s2 b2 4 2);
  check string "final" b1 b2

let t_sendv () = with_socketpair @@ fun (s1, s2) ->
  let b1 = [| "."; "." |]
  and b2 = [| "..."; "..." |] in
  Sendmsg.sendv s1 [| "ab"; "cd" |] |> check int "sendv1" 4;
  Sendmsg.sendv s1 [| "e"; "f" |] |> check int "sendv2" 2;
  Sendmsg.recvv s2 b1 |> check ret "recvv1" (2, None);
  Sendmsg.recvv s2 b2 |> check ret "recvv2" (4, None);
  check (array string) "b1" b1 [| "a"; "b" |];
  check (array string) "b2" b2 [| "cde"; "f.." |]

let pass_sock () =
  with_socketpair @@ fun (s1, s2) ->
  with_socketpair @@ fun (x1, x2) ->
    let b0 = "x.." in
    Sendmsg.send s1 ~fd:x1 b0 0 1 |> ignore;
    match Sendmsg.recv s2 b0 1 1 with
    | (n, Some fd) ->
        check int "recv 1" n 1;
        write fd b0 0 1 |> ignore;
        read x2 b0 2 1 |> ignore;
        close fd;
        check string "endgame" b0 ("xxx")
    | _ -> fail "socket not passed"

let msg_boundaries () = with_socketpair @@ fun (s1, s2) ->
  let msgs = ["x"; "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"; "z"] in
  msgs |> List.map (send s1 ~fd:stdout) |> ignore;
  msgs |> List.iter @@ fun msg ->
    match recv s2 with
    | (msg', Some s) -> close s; check string "recv" msg msg'
    | _ -> fail "no socket"

let stress () = with_socketpair @@ fun (s1, s2) ->
  for _ = 1 to 100000 do
    Sendmsg.send s1 ~fd:stdout ("x") 0 1 |> ignore;
    match Sendmsg.recv s2 "." 0 1 with
    | (1, Some fd) -> close fd
    | _            -> Alcotest.fail "nope."
  done

let () = run "sendmsg" [
  "sendmsg", [
    "send", `Quick, t_send;
    "sendv", `Quick, t_sendv;
    "passing sockets", `Quick, pass_sock;
    "message boundaries", `Quick, msg_boundaries;
    "stress", `Quick, stress;
  ]
]
