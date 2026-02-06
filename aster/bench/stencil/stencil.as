# Aster stencil benchmark (Aster0 subset)

const W is usize = 512
const H is usize = 512
const REPS is usize = 3

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is f64) returns i32

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
    var w0 is f64 = 0.5
    var w1 is f64 = 0.125
    var rep is usize = 0
    while rep < REPS do
        var h1 is usize = H - 1
        var w2 is usize = W
        var w_end is usize = W - 1
        var i is usize = 1
        while i < h1 do
            var rowp is slice of f64 = in_buf + i * w2
            var rowm is slice of f64 = rowp - w2
            var rowpp is slice of f64 = rowp + w2
            var out_row is slice of f64 = out_buf + i * w2
            var j is usize = 1
            while j < w_end do
                var center is f64 = rowp[j] * w0
                var sum is f64 = rowm[j] + rowpp[j] + rowp[j - 1] + rowp[j + 1]
                out_row[j] = center + sum * w1
                j = j + 1
            i = i + 1
        var tmp is slice of f64 = in_buf
        in_buf = out_buf
        out_buf = tmp
        rep = rep + 1

    printf("%f\n", in_buf[0])
    free(input)
    free(output)
    return 0
