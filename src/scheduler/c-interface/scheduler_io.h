#include <sys/event.h>
#include <fcntl.h>
#include <unistd.h>


int create_kqueue();

int register_event(int kq, int fd, short filter, void *udata);
int unregister_event(int kq, int fd, short filter);

int poll_events(int kq, struct kevent *events, int max_events);

void advise_sequencial(int fd);

int listen_socket (unsigned char ip[4], int port, int backlog);
int accept_socket (int lfd);
int close_listener_socket (int lfd);
int close_socket (int sfd);

void call_perror(const char *msg);