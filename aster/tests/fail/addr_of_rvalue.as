# Expected: compile failure (address-of requires an lvalue)

def main() returns i32
    var x is i32 = 1
    var p is ptr of i32 = &(x + 1)
    p = p
    return 0

