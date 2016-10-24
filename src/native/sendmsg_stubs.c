/* Copyright (c) 2016 David Kaloper Meršinjak. All rights reserved.
    See LICENSE.md. */

#include "sendmsg.h"

#include <caml/memory.h>
#include <caml/custom.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/unixsupport.h>

#define __fid(name) static char fid[] = name;

static inline int err (char *name, int res) {
  if (res == -1) { uerror (name, Nothing); }
  return res;
}

static inline value pair (value p1, value p2) {
  CAMLparam2 (p1, p2);
  CAMLlocal1 (res);
  res = caml_alloc_tuple (2);
  Field (res, 0) = p1;
  Field (res, 1) = p2;
  CAMLreturn (res);
}

static inline void from_buff_off_n (char *name, void **data, size_t *lenv, value buf, value voff, value vn) {
  int off = Int_val (voff), n = Int_val (vn);
  if (off < 0 || n < 0 || caml_string_length (buf) < (size_t) (off + n)) {
    caml_invalid_argument (name);
  }
  *data = String_val (buf) + off;
  *lenv = n;
}

static inline int Osock_val (value ofd) {
  return Is_block (ofd) ? Int_val (Field (ofd, 0)) : -1;
}

static inline value Val_osock (int fd) {
  CAMLparam0 ();
  CAMLlocal1 (ret);
  if (fd != -1)
    Field (ret = caml_alloc_tuple (1), 0) = Val_int (fd);
  CAMLreturn (ret);
}

CAMLprim value caml_sendmsg_send (value fd, value sock, value buf, value off, value n) {
  CAMLparam5 (fd, sock, buf, off, n);
  void *data;
  size_t lenv;
  __fid ("Sendmsg.send");
  from_buff_off_n (fid, &data, &lenv, buf, off, n);
  int res = err (fid, sendmsg_with_sock (
    Int_val (fd), Osock_val (sock), &data, &lenv, 1));
  CAMLreturn (Val_int (res));
}

CAMLprim value caml_sendmsg_recv (value fd, value buf, value off, value n) {
  CAMLparam4 (fd, buf, off, n);
  CAMLlocal1 (ret);
  void *data;
  size_t lenv;
  __fid ("Sendmsg.recv");
  from_buff_off_n (fid, &data, &lenv, buf, off, n);
  int s, res = err (fid, recvmsg_with_sock (
    Int_val (fd), &s, &data, &lenv, 1));
  ret = pair (Val_int (res), Val_osock (s));
  CAMLreturn (ret);
}

CAMLprim value caml_sendmsg_sendv (value fd, value sock, value bufv) {
  CAMLparam3 (fd, sock, bufv);
  size_t n = (size_t) caml_array_length (bufv);
  size_t lenv[n];
  void *data[n];
  __fid ("Sendmsg.sendv");
  for (size_t i = 0; i < n; i++) {
    lenv[i] = caml_string_length (*((value *)bufv + i));
    data[i] = String_val (*((value *)bufv + i));
  }
  int res = err (fid, sendmsg_with_sock (
    Int_val (fd), Osock_val (sock), data, lenv, n));
  CAMLreturn (Val_int (res));
}

CAMLprim value caml_sendmsg_recvv (value fd, value bufv) {
  CAMLparam2 (fd, bufv);
  CAMLlocal1 (ret);
  size_t n = (size_t) caml_array_length (bufv);
  size_t lenv[n];
  void *data[n];
  __fid ("Sendmsg.recvv");
  for (size_t i = 0; i < n; i++) {
    lenv[i] = caml_string_length (*((value *)bufv + i));
    data[i] = String_val (*((value *)bufv + i));
  }
  int s, res = err (fid, recvmsg_with_sock (Int_val (fd), &s, data, lenv, n));
  ret = pair (Val_int (res), Val_osock (s));
  CAMLreturn (ret);
}
