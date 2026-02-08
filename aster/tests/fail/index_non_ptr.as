# Expected: compile failure (indexing requires pointer/slice type)

def main() returns i32
    var x is i32 = 0
    var y is i32 = x[0]
    return y

