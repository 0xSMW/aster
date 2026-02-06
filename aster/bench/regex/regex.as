# Aster regex benchmark (Aster0 subset)

const N is usize = 1000000
const LCG_A is u64 = 6364136223846793005
const LCG_C is u64 = 1

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is u64) returns i32

# pattern: a b* c

def count_matches(buf is String, len is usize) returns u64
    var count is u64 = 0
    var p is String = buf
    var end is String = buf + len
    while p < end do
        var c is u8 = p[0]
        if c != 97 then
            p = p + 1
            continue
        var q is String = p + 1
        while q < end and q[0] == 98 do
            q = q + 1
        if q < end and q[0] == 99 then
            count = count + 1
            p = q + 1
        else
            p = q
    return count

# entry

def main() returns i32
    var buf is String = malloc(N)
    if buf is null then
        return 1

    var seed is u64 = 1
    var i is usize = 0
    while i < N do
        seed = seed * LCG_A + LCG_C
        var r is u8 = seed & 3
        var ch is u8 = 120
        if r == 0 then
            ch = 97
        else if r == 1 then
            ch = 98
        else if r == 2 then
            ch = 99
        buf[i] = ch
        i = i + 1

    var matches is u64 = count_matches(buf, N)
    printf("%llu\n", matches)
    free(buf)
    return 0
