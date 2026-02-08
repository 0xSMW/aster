# Expected: compile failure (call arity mismatch)

extern def puts(s is String) returns i32

def main() returns i32
    puts()
    return 0

