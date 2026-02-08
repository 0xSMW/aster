# Expected: compile failure (deref requires a pointer type)

def main() returns i32
    var x is i32 = 0
    var y is i32 = *x
    return y

