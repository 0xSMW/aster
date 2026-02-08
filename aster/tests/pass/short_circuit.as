# Conformance: `and` / `or` short-circuit semantics.

extern def malloc(n is usize) returns MutString
extern def free(p is MutString) returns ()

def touch(p is MutString) returns i32
    p[0] = 1
    return 1

def main() returns i32
    var buf is MutString = malloc(1)
    if buf is null then
        return 1

    buf[0] = 0

    # false && touch => touch must not run
    if (0 == 1) and touch(buf) then
        free(buf)
        return 1
    if buf[0] != 0 then
        free(buf)
        return 1

    # true || touch => touch must not run
    if (0 == 0) or touch(buf) then
        var dummy is i32 = 0
        dummy = dummy + 1
    if buf[0] != 0 then
        free(buf)
        return 1

    # true && touch => touch must run
    if (0 == 0) and touch(buf) then
        var dummy2 is i32 = 0
        dummy2 = dummy2 + 1
    else
        free(buf)
        return 1
    if buf[0] != 1 then
        free(buf)
        return 1

    free(buf)
    return 0

