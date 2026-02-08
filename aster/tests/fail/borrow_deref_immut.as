# Borrow rules: cannot mutate through an immutable ref.

def main() returns i32
    let x is i32 = 0
    let p is ref i32 = &x
    *p = 1
    return 0

