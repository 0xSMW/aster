# Aster stencil benchmark (Aster0 subset)

const W is usize = 512
const H is usize = 512
const REPS is usize = 3
const SCALE is usize = 20

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is f64) returns i32
extern def getenv(name is String) returns String
extern def atoi(s is String) returns i32
extern def aster_stencil_mt(inp is slice of f64, outp is slice of f64, steps is usize) returns slice of f64


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
    var size is usize = W * H
    var bytes is usize = size * 8

    var input is slice of f64 = malloc(bytes)
    var output is slice of f64 = malloc(bytes)
    if input is null or output is null then
        return 1

    var i is usize = 0
    while i < size do
        input[i] = 1.0
        output[i] = 0.0
        i = i + 1

    var in_buf is slice of f64 = input
    var out_buf is slice of f64 = output

    var iters is usize = bench_iters()
    var total_reps is usize = REPS * iters * SCALE
    # Run the full stencil loop via a runtime helper so we can exploit
    # multithreading even before the Aster MVP has first-class fn pointers.
    var result is slice of f64 = aster_stencil_mt(in_buf, out_buf, total_reps)
    printf("%f\n", result[0])
    free(input)
    free(output)
    return 0
