# Borrow rules: cannot take a mutable ref to an immutable (`let`) local.

def inc(p is mut ref i32) returns ()
    *p = *p + 1
    return

def main() returns i32
    let x is i32 = 1
    inc(&x)
    return 0

