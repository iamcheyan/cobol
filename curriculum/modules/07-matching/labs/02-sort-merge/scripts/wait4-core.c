#define _GNU_SOURCE
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    struct rusage usage;
    int status = 0;
    pid_t child;
    if (argc < 2) return 125;
    child = fork();
    if (child < 0) return 125;
    if (child == 0) {
        execv(argv[1], &argv[1]);
        perror("execv");
        _exit(127);
    }
    if (wait4(child, &status, 0, &usage) < 0) return 125;
    printf("CHILD_PID=%ld WAIT_STATUS=%d MAX_RSS_KIB=%ld\n",
           (long)child, status, usage.ru_maxrss);
    fflush(stdout);
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
    return 125;
}
