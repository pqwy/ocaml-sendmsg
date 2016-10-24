/* Copyright (c) 2016 David Kaloper Meršinjak. All rights reserved.
    See LICENSE.md.  */

#include <sys/socket.h>

#define ctrl_size (sizeof (struct cmsghdr) + sizeof (int))

ssize_t sendmsg_with_sock (int fd, int s, void **data, size_t *lenv, size_t n) {

  struct iovec iov[n];
  char ctrl[ctrl_size];
  struct msghdr msg = {
    .msg_iov        = iov,
    .msg_iovlen     = n,
    .msg_control    = ctrl,
    .msg_controllen = 0,
  };

  for (size_t i = 0; i < n; i++) {
    iov[i].iov_base = data[i];
    iov[i].iov_len  = lenv[i];
  }

  if (s >= 0) {
    msg.msg_controllen = ctrl_size;

    struct cmsghdr *cmsg = (struct cmsghdr *) ctrl;
    cmsg->cmsg_len   = ctrl_size;
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type  = SCM_RIGHTS;
    int *cdata = (int *)CMSG_DATA(cmsg);
    *cdata = s;
  }

  return (sendmsg (fd, &msg, 0));
}

ssize_t recvmsg_with_sock (int fd, int *s, void **data, size_t *lenv, size_t n) {

  struct iovec iov[n];
  char ctrl[ctrl_size];
  struct msghdr msg = {
    .msg_iov        = iov,
    .msg_iovlen     = n,
    .msg_control    = ctrl,
    .msg_controllen = ctrl_size,
  };

  struct cmsghdr *cmsg = (struct cmsghdr *) ctrl;
  cmsg->cmsg_len   = ctrl_size;
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type  = SCM_RIGHTS;

  for (size_t i = 0; i < n; i++) {
    iov[i].iov_base = data[i];
    iov[i].iov_len  = lenv[i];
  }

  *s = -1;
  int res = recvmsg (fd, &msg, 0);
  if (res >= 0 && msg.msg_controllen == ctrl_size) {
    int *cdata = (int *)CMSG_DATA(cmsg);
    *s = *cdata;
  }

  return res;
}
