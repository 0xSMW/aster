# Aster sort benchmark (Aster0 subset)

const N is usize = 200000
const LCG_A is u64 = 6364136223846793005
const LCG_C is u64 = 1

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is u64) returns i32

# LCG

def lcg_next(seed is u64) returns u64
    return seed * LCG_A + LCG_C

# radix sort (LSD, 8-bit digits)

def radix_sort(a is slice of u64, n is usize)
    if n < 2 then
        return

    var tmp is slice of u64 = malloc(n * 8)
    var counts is slice of u64 = malloc(256 * 8)
    if tmp is null or counts is null then
        if tmp is not null then
            free(tmp)
        if counts is not null then
            free(counts)
        return

    var pass is usize = 0
    var shift is u64 = 0
    var src is slice of u64 = a
    var dst is slice of u64 = tmp

    while pass < 8 do
        var i is usize = 0
        while i < 256 do
            counts[i] = 0
            i = i + 1

        i = 0
        while i < n do
            var key is u64 = src[i]
            var idx is usize = (key >> shift) & 255
            counts[idx] = counts[idx] + 1
            i = i + 1

        var sum is u64 = 0
        i = 0
        while i < 256 do
            sum = sum + counts[i]
            counts[i] = sum
            i = i + 1

        var j is usize = n
        while j > 0 do
            j = j - 1
            var key2 is u64 = src[j]
            var idx2 is usize = (key2 >> shift) & 255
            counts[idx2] = counts[idx2] - 1
            dst[counts[idx2]] = key2

        var swap is slice of u64 = src
        src = dst
        dst = swap

        shift = shift + 8
        pass = pass + 1

    if src is not a then
        var k is usize = 0
        while k < n do
            a[k] = src[k]
            k = k + 1

    free(tmp)
    free(counts)

def sort(a is slice of u64, n is usize)
    radix_sort(a, n)

# entry point

def main() returns i32
    var n is usize = N
    var bytes is usize = n * 8
    var data is slice of u64 = malloc(bytes)
    if data is null then
        return 1

    var seed is u64 = 1
    var i is usize = 0
    while i < n do
        seed = lcg_next(seed)
        data[i] = seed
        i = i + 1

    sort(data, n)

    printf("%llu\n", data[0])
    free(data)
    return 0
