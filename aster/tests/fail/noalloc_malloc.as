# `noalloc` must reject direct allocator calls.

extern def malloc(n is usize) returns String

noalloc def bad() returns i32
    var p is String = malloc(8)
    if p is null then
        return 0
    return 1

def main() returns i32
    return bad()

