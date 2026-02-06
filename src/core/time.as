use core.libc

def now_ns() returns u64
    var ts is TimeSpec
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return (ts.tv_sec * 1000000000) + ts.tv_nsec

