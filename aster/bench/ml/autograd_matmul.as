# ML bench: matmul + sum + backward (float32, CPU)
#
# Prints: elapsed nanoseconds as a single integer line.

use core.libc
use core.time
use core.io
use aster_ml.gradient
use aster_ml.tensor

def fill_linspace_f32(p is slice of f32, n is usize, scale is f32) returns ()
    var i is usize = 0
    while i < n do
        p[i] = (0.0 + i) * scale
        i = i + 1
    return

def main() returns i32
    var m is usize = 32
    var k is usize = 32
    var n is usize = 32
    var iters is usize = 25

    var dims_a is slice of usize = malloc(2 * 8)
    var dims_b is slice of usize = malloc(2 * 8)
    if dims_a is null or dims_b is null then
        if dims_a is not null then
            free(dims_a)
        if dims_b is not null then
            free(dims_b)
        return 1
    dims_a[0] = m
    dims_a[1] = k
    dims_b[0] = k
    dims_b[1] = n

    var a is GradTensor
    var b is GradTensor
    if grad_tensor_init_leaf(&a, 2, dims_a, 1) != 0 then
        free(dims_a)
        free(dims_b)
        return 1
    if grad_tensor_init_leaf(&b, 2, dims_b, 1) != 0 then
        free(dims_a)
        free(dims_b)
        grad_tensor_free(&a)
        return 1
    free(dims_a)
    free(dims_b)

    # Deterministic init.
    fill_linspace_f32(tensor_data_ptr(&a.data), m * k, 0.001)
    fill_linspace_f32(tensor_data_ptr(&b.data), k * n, 0.002)

    var checksum is f32 = 0.0
    var t0 is u64 = now_ns()

    var i is usize = 0
    while i < iters do
        if grad_tensor_zero_grad(&a) != 0 then
            return 1
        if grad_tensor_zero_grad(&b) != 0 then
            return 1

        var tmp is GradTensor
        var s is GradTensor
        if grad_tensor_matmul(&tmp, &a, &b) != 0 then
            return 1
        if grad_tensor_sum_all(&s, &tmp) != 0 then
            grad_tensor_free(&tmp)
            return 1
        if grad_tensor_backward(&s) != 0 then
            grad_tensor_free(&s)
            grad_tensor_free(&tmp)
            return 1

        var ap is slice of f32 = tensor_data_ptr(&a.grad)
        checksum = checksum + ap[0]

        grad_tensor_free(&s)
        grad_tensor_free(&tmp)
        i = i + 1

    var t1 is u64 = now_ns()
    print_u64(t1 - t0)

    # Prevent dead-code elimination of the loop in extreme optimizer scenarios.
    if checksum == 1234567.0 then
        return 1

    grad_tensor_free(&b)
    grad_tensor_free(&a)
    return 0

