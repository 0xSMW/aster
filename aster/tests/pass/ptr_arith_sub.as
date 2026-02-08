# Pointer arithmetic sanity: `ptr - n` must subtract.

extern def malloc(n is usize) returns MutString
extern def free(p is MutString) returns ()

def main() returns i32
    var buf is MutString = malloc(4)
    if buf is null then
        return 1

    buf[0] = 1
    buf[1] = 2
    buf[2] = 3
    buf[3] = 4

    var p is MutString = buf + 3
    p = p - 2
    let v is u8 = p[0]

    free(buf)
    if v == 2 then
        return 0
    return 1

