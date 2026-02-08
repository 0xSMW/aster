# Expected: compile+run OK (tensor IO: raw f32 load from disk)

use aster_ml.tensor
use aster_ml.tensor_io
use core.io
use core.libc

extern def fwrite(ptr is String, size is usize, count is usize, fp is File) returns usize
extern def unlink(path is String) returns i32

def abs_f32(x is f32) returns f32
    if x < 0.0 then
        return 0.0 - x
    return x

def main() returns i32
    var path is String = "/tmp/aster_ml_raw_f32.bin"

    # Write 4 float32 values.
    var xs is slice of f32 = malloc(16)
    if xs is null then
        return 1
    xs[0] = 1.25
    xs[1] = 2.0
    xs[2] = 3.5
    xs[3] = 4.75
    var fp is File = fopen(path, "wb")
    if fp is null then
        free(xs)
        return 1
    var wrote is usize = fwrite(xs, 4, 4, fp)
    fclose(fp)
    if wrote != 4 then
        free(xs)
        unlink(path)
        return 1

    var t is Tensor
    tensor_reset(&t)
    var rc is i32 = tensor_load_raw_f32(&t, path)
    if rc != 0 then
        free(xs)
        unlink(path)
        return 1

    if t.ndim != 1 then
        tensor_free(&t)
        free(xs)
        unlink(path)
        return 1
    var sh is slice of usize = t.shape
    if sh[0] != 4 then
        tensor_free(&t)
        free(xs)
        unlink(path)
        return 1

    var tp is slice of f32 = tensor_data_ptr(&t)
    if abs_f32(tp[0] - 1.25) > 0.000001 then
        return 1
    if abs_f32(tp[1] - 2.0) > 0.000001 then
        return 1
    if abs_f32(tp[2] - 3.5) > 0.000001 then
        return 1
    if abs_f32(tp[3] - 4.75) > 0.000001 then
        return 1

    tensor_free(&t)
    free(xs)
    unlink(path)
    println("ok")
    return 0
