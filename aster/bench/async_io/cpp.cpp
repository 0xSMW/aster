#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <poll.h>
#include <unistd.h>

static constexpr size_t ITERS = 2000;
static constexpr size_t CHUNK = 4096;

int main() {
    int fds[2];
    if (pipe(fds) != 0) return 1;
    int rfd = fds[0];
    int wfd = fds[1];

    char* buf = (char*)std::malloc(CHUNK);
    if (!buf) return 1;
    for (size_t i = 0; i < CHUNK; i++) buf[i] = 'a';

    uint64_t total = 0;
    for (size_t iter = 0; iter < ITERS; iter++) {
        (void)write(wfd, buf, CHUNK);
        struct pollfd pfd;
        pfd.fd = rfd;
        pfd.events = POLLIN;
        pfd.revents = 0;
        if (poll(&pfd, 1, -1) > 0) {
            ssize_t n = read(rfd, buf, CHUNK);
            if (n > 0) total += (uint64_t)n;
        }
    }

    std::printf("%llu\n", static_cast<unsigned long long>(total));
    std::free(buf);
    close(rfd);
    close(wfd);
    return 0;
}
