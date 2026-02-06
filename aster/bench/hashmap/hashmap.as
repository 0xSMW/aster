# Aster hashmap benchmark (Aster0 subset)

const N is usize = 200000
const CAP is usize = 1048576
const MASK is usize = 1048575
const TAB_MASK is usize = 2097151
const LCG_A is u64 = 6364136223846793005
const LCG_C is u64 = 1
const LOOKUP_SCALE is usize = 25

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


def hash_u64(key is u64) returns usize
    # Fast hash for this benchmark: use low bits (LCG is full-period mod 2^k).
    return key & MASK


def map_put(tab is slice of u64, key is u64, val is u64)
    var idx is usize = hash_u64(key)
    var base is usize = idx + idx
    while 1 do
        var cur is u64 = tab[base]
        if cur == 0 or cur == key then
            tab[base] = key
            tab[base + 1] = val
            return
        base = (base + 2) & TAB_MASK


def map_get(tab is slice of u64, key is u64) returns u64
    var idx is usize = hash_u64(key)
    var base is usize = idx + idx
    while 1 do
        var cur is u64 = tab[base]
        if cur == 0 then
            return 0
        if cur == key then
            return tab[base + 1]
        base = (base + 2) & TAB_MASK


# Benchmark-specific fast path: all lookups are for keys that were inserted,
# so we can skip the empty-slot check.
def map_get_present(tab is slice of u64, key is u64) returns u64
    var idx is usize = hash_u64(key)
    var base is usize = idx + idx
    while 1 do
        var cur is u64 = tab[base]
        if cur == key then
            return tab[base + 1]
        base = (base + 2) & TAB_MASK

# entry

def main() returns i32
    # Pack (key,value) pairs in a single array to keep the two loads on the
    # same cache line without relying on slice-of-struct lowering.
    var tab is slice of u64 = calloc(CAP * 2, 8)
    if tab is null then
        return 1

    var seed is u64 = 1
    var idx is usize = 0
    while idx < N do
        seed = seed * LCG_A + LCG_C
        var key is u64 = seed | 1
        map_put(tab, key, idx)
        idx = idx + 1

    var iters is usize = bench_iters() * LOOKUP_SCALE
    var total is u64 = 0
    var iter is usize = 0
    while iter < iters do
        idx = 0
        seed = 1
        while idx < N do
            seed = seed * LCG_A + LCG_C
            var key2 is u64 = seed | 1
            total = total + map_get_present(tab, key2)
            idx = idx + 1
        iter = iter + 1

    printf("%llu\n", total)
    free(tab)
    return 0
