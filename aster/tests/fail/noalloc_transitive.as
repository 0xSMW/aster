# `noalloc` must reject transitive allocator calls.

extern def malloc(n is usize) returns String

def alloc() returns String
    return malloc(8)

noalloc def caller() returns String
    return alloc()

def main() returns i32
    var p is String = caller()
    if p is null then
        return 0
    return 1

