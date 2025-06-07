#include <sys/event.h>


int create_kqueue();

int register_event(int kq, int fd, short filter, void *udata);

int poll_events(int kq, struct kevent *events, int max_events, int timeout);