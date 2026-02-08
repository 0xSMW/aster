# Seed: structs + field access.

struct Pair
    var a is i32
    var b is i32

def main() returns i32
    var p is Pair
    p.a = 40
    p.b = 2
    var x is i32 = p.a + p.b
    if x == 42 then
        return 0
    return 1

