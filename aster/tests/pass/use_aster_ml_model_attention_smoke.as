# Expected: compile+run OK (Embedding + RMSNorm + SDPA forward smoke)

use aster_ml.nn.nn
use aster_ml.tensor
use core.io
use core.libc

def main() returns i32
    var e is Embedding
    if embedding_init(&e, 8, 4) != 0 then
        return 1

    var n is RMSNorm
    if rmsnorm_init(&n, 4, 0.00001) != 0 then
        embedding_free(&e)
        return 1

    var idx is slice of usize = malloc(2 * 8)
    if idx is null then
        rmsnorm_free(&n)
        embedding_free(&e)
        return 1
    idx[0] = 1
    idx[1] = 2

    var x is Tensor
    tensor_reset(&x)
    if embedding_forward(&x, &e, idx, 2) != 0 then
        free(idx)
        rmsnorm_free(&n)
        embedding_free(&e)
        return 1
    free(idx)

    # reshape (2,4) -> (1,2,4)
    var dims is slice of usize = malloc(3 * 8)
    if dims is null then
        tensor_free(&x)
        rmsnorm_free(&n)
        embedding_free(&e)
        return 1
    dims[0] = 1
    dims[1] = 2
    dims[2] = 4
    var x3 is Tensor
    tensor_reset(&x3)
    if tensor_reshape(&x3, &x, 3, dims) != 0 then
        free(dims)
        tensor_free(&x)
        rmsnorm_free(&n)
        embedding_free(&e)
        return 1
    free(dims)

    var xn is Tensor
    tensor_reset(&xn)
    if rmsnorm_forward(&xn, &x3, &n) != 0 then
        tensor_free(&x3)
        tensor_free(&x)
        rmsnorm_free(&n)
        embedding_free(&e)
        return 1

    var out is Tensor
    tensor_reset(&out)
    if sdpa_forward(&out, &xn, &xn, &xn) != 0 then
        tensor_free(&xn)
        tensor_free(&x3)
        tensor_free(&x)
        rmsnorm_free(&n)
        embedding_free(&e)
        return 1

    var s is Tensor
    tensor_reset(&s)
    if tensor_sum_all_f32(&s, &out) != 0 then
        tensor_free(&out)
        tensor_free(&xn)
        tensor_free(&x3)
        tensor_free(&x)
        rmsnorm_free(&n)
        embedding_free(&e)
        return 1

    var sp is slice of f32 = tensor_data_ptr(&s)
    var v is f32 = sp[0]
    # NaN check (NaN != NaN)
    if v != v then
        return 1

    # Expected is deterministic for current init + implementation; keep a loose tolerance.
    if v < 7.35 or v > 7.41 then
        return 1

    tensor_free(&s)
    tensor_free(&out)
    tensor_free(&xn)
    tensor_free(&x3)
    tensor_free(&x)
    rmsnorm_free(&n)
    embedding_free(&e)
    println("ok")
    return 0

