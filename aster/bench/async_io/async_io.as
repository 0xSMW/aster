# Aster async IO benchmark (Aster0 subset)

const ITERS is usize = 2000
const CHUNK is usize = 4096
const POLLIN_CONST is i16 = 0x0001

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def pipe(fds is slice of i32) returns i32
extern def poll(fds is mut ref PollFd, nfds is usize, timeout is i32) returns i32
extern def read(fd is i32, buf is String, count is usize) returns isize
extern def write(fd is i32, buf is String, count is usize) returns isize
extern def close(fd is i32) returns i32
extern def printf(fmt is String, a is u64) returns i32

# entry

def main() returns i32
    var fds is slice of i32 = malloc(8)
    if fds is null then
        return 1
    if pipe(fds) != 0 then
        free(fds)
        return 1

    var rfd is i32 = fds[0]
    var wfd is i32 = fds[1]

    var buf is String = malloc(CHUNK)
    if buf is null then
        close(rfd)
        close(wfd)
        free(fds)
        return 1

    var i is usize = 0
    while i < CHUNK do
        buf[i] = 97
        i = i + 1

    var total is u64 = 0
    var iter is usize = 0
    while iter < ITERS do
        write(wfd, buf, CHUNK)
        var pfd is PollFd
        pfd.fd = rfd
        pfd.events = POLLIN_CONST
        pfd.revents = 0
        if poll(&pfd, 1, -1) > 0 then
            var n is isize = read(rfd, buf, CHUNK)
            if n > 0 then
                total = total + n
        iter = iter + 1

    printf("%llu\n", total)
    free(buf)
    close(rfd)
    close(wfd)
    free(fds)
    return 0
