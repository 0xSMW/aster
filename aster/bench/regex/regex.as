# Aster regex benchmark (Aster0 subset)

const N is usize = 1000000
const LCG_A is u64 = 6364136223846793005
const LCG_C is u64 = 1
const LUT_PACK is u64 = 0x78636261  # bytes: 'a','b','c','x' (little-endian)

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is u64) returns i32
extern def getenv(name is String) returns String
extern def atoi(s is String) returns i32


def bench_iters() returns usize
    var s is String = getenv("BENCH_ITERS")
    if s is null then
        return 1
    var n is i32 = atoi(s)
    if n <= 0 then
        return 1
    return n

# entry

def main() returns i32
    var iters is usize = bench_iters()
    var total is u64 = 0
    var iter is usize = 0
    while iter < iters do
        var seed is u64 = 1
        var matches is u64 = 0
        # 0 = seek 'a'; 1 = after 'a' (consume b* then expect 'c' for a match).
        var state is i32 = 0
        var i is usize = 0
        while i < N do
            seed = seed * LCG_A + LCG_C
            # Use higher bits; low bits of an LCG modulo 2^k are not random.
            var r is u64 = (seed >> 32) & 3
            var shift is u64 = r << 3
            var ch is u64 = (LUT_PACK >> shift) & 255
            if state == 0 then
                if ch == 'a' then
                    state = 1
            else
                if ch == 'c' then
                    matches = matches + 1
                    state = 0
                else if ch == 'x' then
                    state = 0
            i = i + 1
        total = total + matches
        iter = iter + 1

    printf("%llu\n", total)
    return 0
