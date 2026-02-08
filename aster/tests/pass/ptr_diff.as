# Pointer difference sanity: `ptr - ptr` yields an element-count (ptrdiff_t).

extern def malloc(n is usize) returns MutString
extern def free(p is MutString) returns ()

def main() returns i32
    # u8 pointers: units are bytes.
    var buf is MutString = malloc(10)
    if buf is null then
        return 1
    let d0 is isize = (buf + 7) - (buf + 2)
    free(buf)
    if d0 != 5 then
        return 1

    # f64 pointers: units are elements (8-byte scale).
    var a is slice of f64 = malloc(4 * 8)
    if a is null then
        return 1
    let d1 is isize = (a + 3) - (a + 1)
    free(a)
    if d1 == 2 then
        return 0
    return 1

