use util.math

extern def add(a is i64, b is i64) returns i64
extern def printf(fmt is String, a is i64) returns i32

def main() returns i32
    var x is i64 = add(1, 2)
    printf("%lld\n", x)
    return 0
