#include "./scheduler_io.h"
#include <stddef.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <unistd.h>

int create_kqueue()
{
    return kqueue();
}

int register_event(int kq, int fd, short filter, void *udata)
{
    struct kevent event;
    EV_SET(&event, fd, filter, EV_ADD | EV_ONESHOT, 0, 0, udata);
    return kevent(kq, &event, 1, NULL, 0, NULL);
}

int unregister_event(int kq, int fd, short filter)
{
    struct kevent event;
    EV_SET(&event, fd, filter, EV_DELETE, 0, 0, NULL);
    return kevent(kq, &event, 1, NULL, 0, NULL);
}

int poll_events(int kq, struct kevent *events, int max_events)
{
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 0;
    return kevent(kq, NULL, 0, events, max_events, &ts);
}

void advise_sequencial(int fd)
{
#ifndef __APPLE__
    (void)posix_fadvise(fd, 0, 0, POSIX_FADV_SEQUENTIAL);
#endif
}

int listen_socket(unsigned char ip[4], int port, int backlog)
{
    struct sockaddr_in addr;
    int lfd = socket(AF_INET, SOCK_STREAM, 0);
    if (lfd < 0)
        return -1;

    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = *(uint32_t *)ip;

    if (bind(lfd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
    {
        close(lfd);
        return -1;
    }

    if (listen(lfd, backlog) < 0)
    {
        close(lfd);
        return -1;
    }

    return lfd;
}

int accept_socket(int lfd)
{
    struct sockaddr_in addr;
    socklen_t addr_len = sizeof(addr);
    int fd = accept(lfd, (struct sockaddr *)&addr, &addr_len);
    if (fd < 0)
        return -1;

    return fd;
}

int close_listener_socket(int lfd)
{
    return close(lfd);
}

int close_socket(int sfd)
{
    return close(sfd);
}

void call_perror(const char *msg)
{
    perror(msg);
}