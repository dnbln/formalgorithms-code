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
    EV_SET(&event, fd, filter, EV_ADD | EV_ENABLE | EV_ONESHOT, 0, 0, udata);
    return kevent(kq, &event, 1, NULL, 0, NULL);
}

int poll_events(int kq, struct kevent *events, int max_events)
{
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 0;
    return kevent(kq, NULL, 0, events, max_events, &ts);
}