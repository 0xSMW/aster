# Conformance: address-of + deref + `mut ref` parameter.

def inc(p is mut ref i32) returns ()
    *p = *p + 1
    return

def main() returns i32
    var x is i32 = 41
    inc(&x)
    if x != 42 then
        return 1
    return 0

