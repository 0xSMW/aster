use core.libc

def println(s is String) returns ()
    printf("%s\n", s)
    return


def print_u64(x is u64) returns ()
    printf("%llu\n", x)
    return
