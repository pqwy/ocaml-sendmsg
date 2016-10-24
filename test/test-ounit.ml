open OUnit2
open Unix

let bracket ~init ~fini f =
  let x = init () in
  match f x with
  | res           -> fini x; res
  | exception exn -> fini x; raise exn

let with_socketpair f =
  bracket f
    ~init:(fun () -> socketpair PF_UNIX SOCK_STREAM 0)
    ~fini:(fun (s1, s2) -> close s1; close s2)

let b = Bytes.of_string

let () = "Sendmsg" >::: [
  "send" >:: (fun _ ->
    with_socketpair @@ fun (s1, s2) ->
      let b1 = b"abcdef" and b2 = b"......" in
      assert_equal ~msg:"send1" 4 (Sendmsg.send s1 b1 0 4);
      assert_equal ~msg:"recv1" (4, None) (Sendmsg.recv s2 b2 0 4);
      assert_equal ~msg:"send2" 2 (Sendmsg.send s1 b1 4 2);
      assert_equal ~msg:"recv2" (2, None) (Sendmsg.recv s2 b2 4 2);
      assert_equal ~msg:"final" b1 b2
  );
  "sendv" >:: (fun _ ->
    with_socketpair @@ fun (s1, s2) ->
      let b1 = [| b"."; b"." |]
      and b2 = [| b"..."; b"..." |] in
      Sendmsg.sendv s1 [| b"ab"; b"cd" |]
        |> assert_equal ~msg:"sendv1" 4;
      Sendmsg.sendv s1 [| b"e"; b"f" |]
        |> assert_equal ~msg:"sendv2" 2;
      Sendmsg.recvv s2 b1
        |> assert_equal ~msg:"recvv" (2, None);
      Sendmsg.recvv s2 b2
        |> assert_equal ~msg:"recvv" (4, None);
      assert_equal ~msg:"b1" b1 [| b"a"; b"b" |];
      assert_equal ~msg:"b2" b2 [| b"cde"; b"f.." |]
  );
  "passing sockets" >:: (fun _ ->
    with_socketpair @@ fun (s1, s2) ->
      with_socketpair @@ fun (x1, x2) ->
        let b0 = b".!!" in
        Sendmsg.send s1 ~fd:x1 b0 0 1 |> ignore;
        match Sendmsg.recv s2 b0 1 1 with
        | (1, Some fd) ->
            write fd b0 0 1 |> ignore;
            read x2 b0 2 1 |> ignore;
            close fd;
            assert_equal ~msg:"endgame" b0 (b"...")
        | _ -> assert_failure "socket not passed"
  );
  "message boundaries" >:: (fun _ ->
    with_socketpair @@ fun (s1, s2) ->
      ["x"; "y"; "z"] |> List.iter (fun str ->
        Sendmsg.send s1 ~fd:stdout (b str) 0 1 |> ignore
      );
      let resn = [();();()] |> List.map (fun () ->
        let buf = Bytes.make 64 '\000' in
        let (n, s) = Sendmsg.recv s2 buf 0 64 in
        (Bytes.sub buf 0 n, match s with Some _ -> true | _ -> false)
      ) in
      assert_equal ~msg:"res" resn [(b"x", true); (b"y", true); (b"z", true)]
  );
  "stress test" >:: (fun _ ->
    with_socketpair @@ fun (s1, s2) ->
      for _ = 1 to 100000 do
        Sendmsg.send s1 ~fd:stdout (b"x") 0 1 |> ignore;
        match Sendmsg.recv s2 (b ".") 0 1 with
        | (1, Some fd) -> close fd
        | _            -> assert_failure "nope."
      done
  );
] |> run_test_tt_main
