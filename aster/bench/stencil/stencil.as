# Aster stencil benchmark (Aster0 subset)

const W is usize = 512
const H is usize = 512
const REPS is usize = 3
const TILE_I is usize = 32
const TILE_J is usize = 64

extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def printf(fmt is String, a is f64) returns i32

# kernel

def stencil(input is slice of f64, output is slice of f64, w is usize, h is usize)
    var h1 is usize = h - 1
    var w1 is usize = w - 1
    var i0 is usize = 1
    while i0 < h1 do
        var iend is usize = i0 + TILE_I
        if iend > h1 then
            iend = h1
        var j0 is usize = 1
        while j0 < w1 do
            var jend is usize = j0 + TILE_J
            if jend > w1 then
                jend = w1
            var i is usize = i0
            while i < iend do
                var row is usize = i * w
                var rowm is usize = row - w
                var rowp is usize = row + w
                var j is usize = j0
                while j < jend do
                    let idx is usize = row + j
                    let center is f64 = input[idx] * 0.5
                    let sum is f64 = input[rowm + j] + input[rowp + j] + input[idx - 1] + input[idx + 1]
                    output[idx] = center + sum * 0.125
                    j = j + 1
                i = i + 1
            j0 = j0 + TILE_J
        i0 = i0 + TILE_I

# entry point for bench harness

def main() returns i32
    var w is usize = W
    var h is usize = H
    var size is usize = w * h
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
    var rep is usize = 0
    while rep < REPS do
        stencil(in_buf, out_buf, w, h)
        var tmp is slice of f64 = in_buf
        in_buf = out_buf
        out_buf = tmp
        rep = rep + 1

    printf("%f\n", in_buf[0])
    free(input)
    free(output)
    return 0
