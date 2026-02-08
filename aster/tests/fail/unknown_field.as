# Expected: compile failure (unknown struct field)

struct Pair
    var a is i32
    var b is i32

def main() returns i32
    var p is Pair
    p.c = 1
    return 0

