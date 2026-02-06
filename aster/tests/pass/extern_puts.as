# Aster1 test: extern call arity + string literal

extern def puts(s is String) returns i32

def main() returns i32
    puts("hi")
    return 0

