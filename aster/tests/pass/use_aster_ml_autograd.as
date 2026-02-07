# Expected: compile+run OK (basic autograd on aster_ml)

use aster_ml.tensor
use aster_ml.gradient
use core.io

def main() returns i32
    var a is Tensor
    var b is Tensor
    var c is Tensor
    var s is Tensor

    if tensor_init_leaf(&a, 2, 2, 3, 1, 1) != 0 then
        return 1
    if tensor_init_leaf(&b, 2, 2, 3, 1, 1) != 0 then
        tensor_free(&a)
        return 1

    var ap is slice of f32 = a.data.data
    var bp is slice of f32 = b.data.data

    # deterministic fill (small)
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

    if tensor_add(&c, &a, &b) != 0 then
        tensor_free(&a)
        tensor_free(&b)
        return 1
    if tensor_sum(&s, &c) != 0 then
        tensor_free(&a)
        tensor_free(&b)
        tensor_free(&c)
        return 1
    if tensor_backward(&s) != 0 then
        tensor_free(&a)
        tensor_free(&b)
        tensor_free(&c)
        tensor_free(&s)
        return 1

    var gap is slice of f32 = a.grad.data
    var gbp is slice of f32 = b.grad.data

    var i is usize = 0
    while i < 6 do
        # gradients should be ones (within a loose tolerance)
        if gap[i] < 0.99 or gap[i] > 1.01 then
            return 1
        if gbp[i] < 0.99 or gbp[i] > 1.01 then
            return 1
        i = i + 1

    tensor_free(&s)
    tensor_free(&c)
    tensor_free(&b)
    tensor_free(&a)
    println("ok")
    return 0

