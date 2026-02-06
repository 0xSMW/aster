# Aster hashmap benchmark (Aster0 subset)

const N is usize = 200000
const CAP is usize = 1048576
const MASK is usize = 1048575
const LCG_A is u64 = 6364136223846793005
const LCG_C is u64 = 1

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is u64) returns i32


def hash_u64(key is u64) returns usize
    var x is u64 = key
    x = x ^ (x >> 33)
    x = x * 0xff51afd7ed558ccd
    x = x ^ (x >> 33)
    return x & MASK


def map_put(keys is slice of u64, vals is slice of u64, key is u64, val is u64)
    var idx is usize = hash_u64(key)
    while 1 do
        var cur is u64 = keys[idx]
        if cur == 0 or cur == key then
            keys[idx] = key
            vals[idx] = val
            return
        idx = (idx + 1) & MASK


def map_get(keys is slice of u64, vals is slice of u64, key is u64) returns u64
    var idx is usize = hash_u64(key)
    while 1 do
        var cur is u64 = keys[idx]
        if cur == 0 then
            return 0
        if cur == key then
            return vals[idx]
        idx = (idx + 1) & MASK

# entry

def main() returns i32
    var keys is slice of u64 = calloc(CAP, 8)
    var vals is slice of u64 = calloc(CAP, 8)
    if keys is null or vals is null then
        return 1

    var seed is u64 = 1
    var idx is usize = 0
    while idx < N do
        seed = seed * LCG_A + LCG_C
        var key is u64 = seed | 1
        map_put(keys, vals, key, idx)
        idx = idx + 1

    var total is u64 = 0
    idx = 0
    seed = 1
    while idx < N do
        seed = seed * LCG_A + LCG_C
        var key2 is u64 = seed | 1
        total = total + map_get(keys, vals, key2)
        idx = idx + 1

    printf("%llu\n", total)
    free(keys)
    free(vals)
    return 0
