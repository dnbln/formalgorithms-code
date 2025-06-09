#include "./scheduler_io.h"
#include <stddef.h>
#include <sys/time.h>

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
