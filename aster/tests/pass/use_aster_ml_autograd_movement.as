# Expected: compile+run OK (autograd through reshape + permute views)

use aster_ml.gradient
use aster_ml.tensor
use core.io
use core.libc

def main() returns i32
    # raw: 1D(24) -> reshape(2,3,4) -> permute(2,0,1) -> sum -> backward
    var dims1 is slice of usize = malloc(1 * 8)
    if dims1 is null then
        return 1
    dims1[0] = 24

    var raw is GradTensor
    var a is GradTensor
    var p is GradTensor
    var s is GradTensor

    if grad_tensor_init_leaf(&raw, 1, dims1, 1) != 0 then
        free(dims1)
        return 1
    free(dims1)

    var rp is slice of f32 = tensor_data_ptr(&raw.data)
    var i is usize = 0
    while i < 24 do
        rp[i] = 1.0 + i
        i = i + 1

    var dims3 is slice of usize = malloc(3 * 8)
    if dims3 is null then
        grad_tensor_free(&raw)
        return 1
    dims3[0] = 2
    dims3[1] = 3
    dims3[2] = 4
    if grad_tensor_reshape(&a, &raw, 3, dims3) != 0 then
        free(dims3)
        grad_tensor_free(&raw)
        return 1
    free(dims3)

    var perm is slice of usize = malloc(3 * 8)
    if perm is null then
        grad_tensor_free(&a)
        grad_tensor_free(&raw)
        return 1
    perm[0] = 2
    perm[1] = 0
    perm[2] = 1
    if grad_tensor_permute(&p, &a, perm) != 0 then
        free(perm)
        grad_tensor_free(&a)
        grad_tensor_free(&raw)
        return 1
    free(perm)

    if grad_tensor_sum_all(&s, &p) != 0 then
        grad_tensor_free(&p)
        grad_tensor_free(&a)
        grad_tensor_free(&raw)
        return 1
    if grad_tensor_backward(&s) != 0 then
        grad_tensor_free(&s)
        grad_tensor_free(&p)
        grad_tensor_free(&a)
        grad_tensor_free(&raw)
        return 1

    # output sum of 1..24 = 300
    var sp is slice of f32 = tensor_data_ptr(&s.data)
    if sp[0] < 299.99 or sp[0] > 300.01 then
        return 1

    # grads for `a` (reshape view) and `raw` (leaf) should be all ones.
    var agp is slice of f32 = tensor_data_ptr(&a.grad)
    var rgp is slice of f32 = tensor_data_ptr(&raw.grad)
    var j is usize = 0
    while j < 24 do
        if agp[j] < 0.99 or agp[j] > 1.01 then
            return 1
        if rgp[j] < 0.99 or rgp[j] > 1.01 then
            return 1
        j = j + 1

    grad_tensor_free(&s)
    grad_tensor_free(&p)
    grad_tensor_free(&a)
    grad_tensor_free(&raw)
    println("ok")
    return 0

