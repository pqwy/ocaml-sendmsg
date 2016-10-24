#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
#require "ocb-stubblr.topkg"
open Topkg
open Ocb_stubblr_topkg

let opams = [Pkg.opam_file ~lint_deps_excluding:(Some ["ocb-stubblr"]) "opam"]

let lwt = Conf.with_pkg ~default:true "lwt"

let () = Pkg.(describe "sendmsg" ~build:(build ~cmd ()) ~opams) @@ fun c ->
  let lwt = Conf.value c lwt in
  Ok [ Pkg.mllib "src/sendmsg.mllib";
       Pkg.clib "src/libsendmsg_stubs.clib";
       Pkg.mllib ~cond:lwt "lwt/sendmsg_lwt.mllib";
       Pkg.test "test/test";
       Pkg.test ~cond:lwt "test/test_lwt"; ]
