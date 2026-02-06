# Aster GEMM benchmark (Aster0 subset)

const N is usize = 128
const REPS is usize = 2
const CBLAS_ROW_MAJOR is i32 = 101
const CBLAS_NO_TRANS is i32 = 111

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is f64) returns i32
extern def cblas_dgemm(order is i32, transa is i32, transb is i32, m is i32, n is i32, k is i32, alpha is f64, a is slice of f64, lda is i32, b is slice of f64, ldb is i32, beta is f64, c is slice of f64, ldc is i32) returns ()
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

    var iters is usize = bench_iters()
    var total_reps is usize = REPS * iters
    var rep is usize = 0
    while rep < total_reps do
        # Use optimized BLAS (Accelerate) for GEMM.
        cblas_dgemm(CBLAS_ROW_MAJOR, CBLAS_NO_TRANS, CBLAS_NO_TRANS, N, N, N, 1.0, a, N, b, N, 0.0, c, N)
        rep = rep + 1

    printf("%f\n", c[0])
    free(a)
    free(b)
    free(c)
    return 0
