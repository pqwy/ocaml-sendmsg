/* Copyright (c) 2016 David Kaloper Meršinjak. All rights reserved.
    See LICENSE.md. */

#include <sys/types.h>

/* Send a message, adding a socket to ancillary data, unless the socket is -1.
 * See sendmsg(3) for other parameters and the return. */
ssize_t sendmsg_with_sock (int fd, int s, void **data, size_t *lenv, size_t n);

/* Send a message, adding a socket to ancillary data, unless the socket is -1.
 * See recvmsg(3) for other parameters and the return. */
ssize_t recvmsg_with_sock (int fd, int *s, void **data, size_t *lenv, size_t n);
