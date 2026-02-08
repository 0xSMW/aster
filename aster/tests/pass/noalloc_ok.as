# noalloc function that does not allocate

noalloc def add1(x is i32) returns i32
    return x + 1


def main() returns i32
    var v is i32 = add1(41)
    if v != 42 then
        return 1
    return 0
