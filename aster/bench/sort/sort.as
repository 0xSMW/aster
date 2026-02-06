# Aster sort benchmark (Aster0 subset)

const N is usize = 200000
const LCG_A is u64 = 6364136223846793005
const LCG_C is u64 = 1

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

# LCG

def lcg_next(seed is u64) returns u64
    return seed * LCG_A + LCG_C

# radix sort (LSD, 11-bit digits)

const RADIX_BITS is u64 = 11
const RADIX is usize = 2048
const RADIX_MASK is u64 = 2047
const PASSES is usize = 6

def radix_sort_ws(a is slice of u64, n is usize, tmp is slice of u64, counts is slice of u32)
    if n < 2 then
        return

    var pass is usize = 0
    var shift is u64 = 0
    var src is slice of u64 = a
    var dst is slice of u64 = tmp

    while pass < PASSES do
        var i is usize = 0
        while i < RADIX do
            counts[i] = 0
            i = i + 1

        i = 0
        while i < n do
            var key is u64 = src[i]
            var idx is usize = (key >> shift) & RADIX_MASK
            counts[idx] = counts[idx] + 1
            i = i + 1

        var sum is u32 = 0
        i = 0
        while i < RADIX do
            sum = sum + counts[i]
            counts[i] = sum
            i = i + 1

        var j is usize = n
        while j > 0 do
            j = j - 1
            var key2 is u64 = src[j]
            var idx2 is usize = (key2 >> shift) & RADIX_MASK
            counts[idx2] = counts[idx2] - 1
            dst[counts[idx2]] = key2

        var swap is slice of u64 = src
        src = dst
        dst = swap

        shift = shift + RADIX_BITS
        pass = pass + 1

    if src is not a then
        var k is usize = 0
        while k < n do
            a[k] = src[k]
            k = k + 1

def sort(a is slice of u64, n is usize)
    var tmp is slice of u64 = malloc(n * 8)
    var counts is slice of u32 = malloc(RADIX * 4)
    if tmp is null or counts is null then
        if tmp is not null then
            free(tmp)
        if counts is not null then
            free(counts)
        return
    radix_sort_ws(a, n, tmp, counts)
    free(tmp)
    free(counts)

# entry point

def main() returns i32
    var n is usize = N
    var bytes is usize = n * 8
    var data is slice of u64 = malloc(bytes)
    var tmp is slice of u64 = malloc(bytes)
    var counts is slice of u32 = malloc(RADIX * 4)
    if data is null or tmp is null or counts is null then
        if data is not null then
            free(data)
        if tmp is not null then
            free(tmp)
        if counts is not null then
            free(counts)
        return 1

    var iters is usize = bench_iters()
    var total is u64 = 0
    var iter is usize = 0
    while iter < iters do
        var seed is u64 = 1
        var i is usize = 0
        while i < n do
            seed = lcg_next(seed)
            data[i] = seed
            i = i + 1

        radix_sort_ws(data, n, tmp, counts)
        total = total + data[0]
        iter = iter + 1

    printf("%llu\n", total)
    free(data)
    free(tmp)
    free(counts)
    return 0
