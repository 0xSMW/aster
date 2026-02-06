# Aster dot product benchmark (Aster0 subset)

const N_ELEMS is usize = 5000000
const REPS is usize = 3

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is f64) returns i32

# kernel

def dot(a is slice of f64, b is slice of f64, n is usize) returns f64
    var sum is f64 = 0.0
    var i is usize = 0
    while i < n do
        sum = sum + a[i] * b[i]
        i = i + 1
    return sum

# entry point for bench harness

def main() returns i32
    var n is usize = N_ELEMS
    var bytes is usize = n * 8
    var a is slice of f64 = malloc(bytes)
    var b is slice of f64 = malloc(bytes)
    if a is null or b is null then
        return 1

    var i is usize = 0
    while i < n do
        a[i] = 1.0
        b[i] = 2.0
        i = i + 1

    var r is f64 = 0.0
    var rep is usize = 0
    while rep < REPS do
        r = dot(a, b, n)
        rep = rep + 1

    printf("%f\n", r)
    free(a)
    free(b)
    return 0
