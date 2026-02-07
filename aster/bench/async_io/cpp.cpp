#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>

static constexpr size_t ITERS = 2000;
static constexpr size_t CHUNK = 4096;

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

int main() {
    int fds[2];
    if (pipe(fds) != 0) return 1;
    int rfd = fds[0];
    int wfd = fds[1];

    char* buf = (char*)std::malloc(CHUNK);
    if (!buf) return 1;
    for (size_t i = 0; i < CHUNK; i++) buf[i] = 'a';

    uint64_t total = 0;
    const size_t total_iters = ITERS * bench_iters();
    for (size_t iter = 0; iter < total_iters; iter++) {
        (void)write(wfd, buf, CHUNK);
        ssize_t n = read(rfd, buf, CHUNK);
        if (n > 0) total += (uint64_t)n;
    }

    std::printf("%llu\n", static_cast<unsigned long long>(total));
    std::free(buf);
    close(rfd);
    close(wfd);
    return 0;
}
