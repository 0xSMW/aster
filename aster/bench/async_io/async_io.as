# Aster async IO benchmark (Aster0 subset)

const ITERS is usize = 2000
const CHUNK is usize = 4096

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def pipe(fds is slice of i32) returns i32
extern def read(fd is i32, buf is String, count is usize) returns isize
extern def write(fd is i32, buf is String, count is usize) returns isize
extern def close(fd is i32) returns i32
extern def printf(fmt is String, a is u64) returns i32
extern def getenv(name is String) returns String
extern def atoi(s is String) returns i32

struct FdPair
    var rfd is i32
    var wfd is i32

# BENCH_ITERS controls how many times to repeat the core loop (to amortize process startup).
def bench_iters() returns usize
    var s is String = getenv("BENCH_ITERS")
    if s is null then
        return 1
    var n is i32 = atoi(s)
    if n <= 0 then
        return 1
    return n

# entry

def main() returns i32
    var fds is FdPair
    if pipe(&fds.rfd) != 0 then
        return 1

    var rfd is i32 = fds.rfd
    var wfd is i32 = fds.wfd

    var buf is MutString = malloc(CHUNK)
    if buf is null then
        close(rfd)
        close(wfd)
        return 1

    var i is usize = 0
    while i < CHUNK do
        buf[i] = 97
        i = i + 1

    var total is u64 = 0
    var iters is usize = bench_iters()
    var total_iters is usize = ITERS * iters
    var iter is usize = 0
    while iter + 3 < total_iters do
        write(wfd, buf, CHUNK)
        read(rfd, buf, CHUNK)
        write(wfd, buf, CHUNK)
        read(rfd, buf, CHUNK)
        write(wfd, buf, CHUNK)
        read(rfd, buf, CHUNK)
        write(wfd, buf, CHUNK)
        read(rfd, buf, CHUNK)
        total = total + (CHUNK * 4)
        iter = iter + 4

    while iter < total_iters do
        write(wfd, buf, CHUNK)
        read(rfd, buf, CHUNK)
        total = total + CHUNK
        iter = iter + 1

    printf("%llu\n", total)
    free(buf)
    close(rfd)
    close(wfd)
    return 0
