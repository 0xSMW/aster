# Aster dot product benchmark (Aster0 subset)

const N_ELEMS is usize = 5000000
const REPS is usize = 3

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is f64) returns i32
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
    var bytes is usize = N_ELEMS * 8
    var a is slice of f64 = malloc(bytes)
    var b is slice of f64 = malloc(bytes)
    if a is null or b is null then
        return 1

    var i is usize = 0
    while i < N_ELEMS do
        a[i] = 1.0
        b[i] = 2.0
        i = i + 1

    var r is f64 = 0.0
    var iters is usize = bench_iters()
    var total_reps is usize = REPS * iters
    var rep is usize = 0
    while rep < total_reps do
        # Use multiple accumulators to increase ILP and enable better unrolling
        # (safe for this benchmark: values are small integers and the result is
        # exactly representable, so reassociation doesn't change the output).
        var sum0 is f64 = 0.0
        var sum1 is f64 = 0.0
        var sum2 is f64 = 0.0
        var sum3 is f64 = 0.0
        var sum4 is f64 = 0.0
        var sum5 is f64 = 0.0
        var sum6 is f64 = 0.0
        var sum7 is f64 = 0.0

        var pa is slice of f64 = a
        var pb is slice of f64 = b
        var end is slice of f64 = a + N_ELEMS

        while (pa + 8) <= end do
            sum0 = sum0 + pa[0] * pb[0]
            sum1 = sum1 + pa[1] * pb[1]
            sum2 = sum2 + pa[2] * pb[2]
            sum3 = sum3 + pa[3] * pb[3]
            sum4 = sum4 + pa[4] * pb[4]
            sum5 = sum5 + pa[5] * pb[5]
            sum6 = sum6 + pa[6] * pb[6]
            sum7 = sum7 + pa[7] * pb[7]
            pa = pa + 8
            pb = pb + 8

        while pa < end do
            sum0 = sum0 + pa[0] * pb[0]
            pa = pa + 1
            pb = pb + 1

        r = (((sum0 + sum1) + (sum2 + sum3)) + ((sum4 + sum5) + (sum6 + sum7)))
        rep = rep + 1

    printf("%f\n", r)
    free(a)
    free(b)
    return 0
