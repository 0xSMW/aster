# Aster GEMM benchmark (Aster0 subset)

const N is usize = 128
const REPS is usize = 2

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is f64) returns i32

# entry point for bench harness

def main() returns i32
    var size is usize = N * N
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
        i = i + 1

    var rep is usize = 0
    while rep < REPS do
        # Match C++ structure: clear C each rep, then GEMM with row pointers.
        var idx is usize = 0
        while idx < size do
            c[idx] = 0.0
            idx = idx + 1

        i = 0
        while i < N do
            var c_row is slice of f64 = c + i * N
            var a_row is slice of f64 = a + i * N
            var k is usize = 0
            while k < N do
                var a_val is f64 = a_row[k]
                var b_row is slice of f64 = b + k * N
                var j is usize = 0
                while j < N do
                    c_row[j] = c_row[j] + a_val * b_row[j]
                    j = j + 1
                k = k + 1
            i = i + 1
        rep = rep + 1

    printf("%f\n", c[0])
    free(a)
    free(b)
    free(c)
    return 0
