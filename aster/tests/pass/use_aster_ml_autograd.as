# Expected: compile+run OK (basic autograd on aster_ml)

use aster_ml.gradient
use aster_ml.tensor
use core.io
use core.libc

def main() returns i32
    var dims is slice of usize = malloc(2 * 8)
    if dims is null then
        return 1
    dims[0] = 2
    dims[1] = 3

    var a is GradTensor
    var b is GradTensor
    var c is GradTensor
    var s is GradTensor

    if grad_tensor_init_leaf(&a, 2, dims, 1) != 0 then
        free(dims)
        return 1
    if grad_tensor_init_leaf(&b, 2, dims, 1) != 0 then
        free(dims)
        grad_tensor_free(&a)
        return 1
    free(dims)

    var ap is slice of f32 = tensor_data_ptr(&a.data)
    var bp is slice of f32 = tensor_data_ptr(&b.data)

    ap[0] = 1.0
    ap[1] = 2.0
    ap[2] = 3.0
    ap[3] = 4.0
    ap[4] = 5.0
    ap[5] = 6.0

    bp[0] = 10.0
    bp[1] = 20.0
    bp[2] = 30.0
    bp[3] = 40.0
    bp[4] = 50.0
    bp[5] = 60.0

    if grad_tensor_add(&c, &a, &b) != 0 then
        grad_tensor_free(&b)
        grad_tensor_free(&a)
        return 1
    if grad_tensor_sum_all(&s, &c) != 0 then
        grad_tensor_free(&c)
        grad_tensor_free(&b)
        grad_tensor_free(&a)
        return 1
    if grad_tensor_backward(&s) != 0 then
        grad_tensor_free(&s)
        grad_tensor_free(&c)
        grad_tensor_free(&b)
        grad_tensor_free(&a)
        return 1

    var gap is slice of f32 = tensor_data_ptr(&a.grad)
    var gbp is slice of f32 = tensor_data_ptr(&b.grad)
    var i is usize = 0
    while i < 6 do
        if gap[i] < 0.99 or gap[i] > 1.01 then
            return 1
        if gbp[i] < 0.99 or gbp[i] > 1.01 then
            return 1
        i = i + 1

    grad_tensor_free(&s)
    grad_tensor_free(&c)
    grad_tensor_free(&b)
    grad_tensor_free(&a)
    println("ok")
    return 0
