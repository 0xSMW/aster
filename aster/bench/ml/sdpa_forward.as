# ML bench: SDPA forward (float32, CPU)
#
# Prints: elapsed nanoseconds as a single integer line.
#
# Workload:
# - out = sdpa(q,k,v) for q,k,v shape (batch, seq, dim)

use core.libc
use core.time
use core.io
use aster_ml.tensor
use aster_ml.nn.nn
use aster_ml.dtype
use aster_ml.device


def fill_linspace_f32(p is slice of f32, n is usize, scale is f32) returns ()
    var i is usize = 0
    while i < n do
        p[i] = (0.0 + i) * scale
        i = i + 1
    return


def main() returns i32
    var batch is usize = 1
    var seq is usize = 32
    var dim is usize = 64
    var iters is usize = 10

    var dims is slice of usize = malloc(3 * 8)
    if dims is null then
        return 1
    dims[0] = batch
    dims[1] = seq
    dims[2] = dim

    var q is Tensor
    var k is Tensor
    var v is Tensor
    tensor_reset(&q)
    tensor_reset(&k)
    tensor_reset(&v)
    if tensor_init_contiguous(&q, DT_F32, DEV_CPU, 3, dims) != 0 then
        free(dims)
        return 1
    if tensor_init_contiguous(&k, DT_F32, DEV_CPU, 3, dims) != 0 then
        free(dims)
        tensor_free(&q)
        return 1
    if tensor_init_contiguous(&v, DT_F32, DEV_CPU, 3, dims) != 0 then
        free(dims)
        tensor_free(&k)
        tensor_free(&q)
        return 1
    free(dims)

    fill_linspace_f32(tensor_data_ptr(&q), batch * seq * dim, 0.0001)
    fill_linspace_f32(tensor_data_ptr(&k), batch * seq * dim, 0.0002)
    fill_linspace_f32(tensor_data_ptr(&v), batch * seq * dim, 0.0003)

    var checksum is f32 = 0.0
    var t0 is u64 = now_ns()
    var i is usize = 0
    while i < iters do
        var out is Tensor
        tensor_reset(&out)
        if sdpa_forward(&out, &q, &k, &v) != 0 then
            tensor_free(&v)
            tensor_free(&k)
            tensor_free(&q)
            return 1
        var op is slice of f32 = tensor_data_ptr(&out)
        checksum = checksum + op[0]
        tensor_free(&out)
        i = i + 1

    var t1 is u64 = now_ns()
    print_u64(t1 - t0)

    if checksum == 1234567.0 then
        return 1

    tensor_free(&v)
    tensor_free(&k)
    tensor_free(&q)
    return 0

