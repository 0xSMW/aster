# Aster regex benchmark (Aster0 subset)

const N is usize = 1000000
const LCG_A is u64 = 6364136223846793005
const LCG_C is u64 = 1
const LUT_PACK is u64 = 0x78636261  # bytes: 'a','b','c','x' (little-endian)

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is u64) returns i32

# pattern: a b* c

def count_matches(buf is String, len is usize) returns u64
    var count is u64 = 0
    var p is String = buf
    var end is String = buf + len
    while p < end do
        if p[0] != 'a' then
            p = p + 1
            continue
        var q is String = p + 1
        while q < end and q[0] == 'b' do
            q = q + 1
        if q < end and q[0] == 'c' then
            count = count + 1
            p = q + 1
        else
            p = q
    return count

# entry

def main() returns i32
    var buf is MutString = malloc(N)
    if buf is null then
        return 1

    var seed is u64 = 1
    var i is usize = 0
    while i < N do
        seed = seed * LCG_A + LCG_C
        var r is u64 = seed & 3
        var shift is u64 = r << 3
        buf[i] = (LUT_PACK >> shift) & 255
        i = i + 1

    var matches is u64 = count_matches(buf, N)
    printf("%llu\n", matches)
    free(buf)
    return 0
