# Aster GEMM benchmark (Aster0 subset)

const N is usize = 128
const REPS is usize = 2

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is f64) returns i32

# kernel

def gemm(a is slice of f64, b is slice of f64, c is slice of f64, n is usize)
    var i is usize = 0
    while i < n do
        var k is usize = 0
        while k < n do
            var a_val is f64 = a[i * n + k]
            var j is usize = 0
            while j < n do
                c[i * n + j] = c[i * n + j] + a_val * b[k * n + j]
                j = j + 1
            k = k + 1
        i = i + 1

# entry point for bench harness

def main() returns i32
    var n is usize = N
    var size is usize = n * n
    var bytes is usize = size * 8

    var a is slice of f64 = malloc(bytes)
    var b is slice of f64 = malloc(bytes)
    var c is slice of f64 = malloc(bytes)
    if a is null or b is null or c is null then
        return 1

    var i is usize = 0
    while i < size do
        a[i] = 1.0
        b[i] = 2.0
        c[i] = 0.0
        i = i + 1

    var rep is usize = 0
    while rep < REPS do
        gemm(a, b, c, n)
        rep = rep + 1

    printf("%f\n", c[0])
    free(a)
    free(b)
    free(c)
    return 0
