# Expected: compile failure (struct rvalue load is unsupported in MVP)

struct Pair
    var a is i32
    var b is i32

def main() returns i32
    var p is Pair
    var x is i32 = p
    return x

