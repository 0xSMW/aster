# Seed: pointers + indexing + pointer arithmetic.

extern def malloc(n is usize) returns MutString
extern def free(p is MutString) returns ()

def main() returns i32
    var buf is MutString = malloc(4)
    if buf is null then
        return 1

    buf[0] = 7
    buf[1] = 8
    buf[2] = 9
    buf[3] = 10

    var p is MutString = buf + 2
    var v is u8 = p[1]

    free(buf)
    if v == 10 then
        return 0
    return 1

