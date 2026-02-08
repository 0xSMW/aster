# ML bench: tiny MLP training step (float32, CPU)
#
# Prints: elapsed nanoseconds as a single integer line.
#
# Workload:
# - forward: l2(relu(l1(x)))
# - loss: sum((yhat - y)^2)
# - backward + AdamW step

use core.libc
use core.time
use core.io
use aster_ml.gradient
use aster_ml.nn.nn
use aster_ml.tensor


def fill_linspace_f32(p is slice of f32, n is usize, scale is f32) returns ()
    var i is usize = 0
    while i < n do
        p[i] = (0.0 + i) * scale
        i = i + 1
    return


def main() returns i32
    var batch is usize = 32
    var in_dim is usize = 64
    var hid_dim is usize = 64
    var out_dim is usize = 32
    var iters is usize = 10

    # Inputs (no grad).
    var dimsx is slice of usize = malloc(2 * 8)
    if dimsx is null then
        return 1
    dimsx[0] = batch
    dimsx[1] = in_dim
    var x is GradTensor
    if grad_tensor_init_leaf(&x, 2, dimsx, 0) != 0 then
        free(dimsx)
        return 1
    free(dimsx)
    fill_linspace_f32(tensor_data_ptr(&x.data), batch * in_dim, 0.001)

    # Target (store -y so diff = yhat + yneg).
    var dimsy is slice of usize = malloc(2 * 8)
    if dimsy is null then
        grad_tensor_free(&x)
        return 1
    dimsy[0] = batch
    dimsy[1] = out_dim
    var yneg is GradTensor
    if grad_tensor_init_leaf(&yneg, 2, dimsy, 0) != 0 then
        free(dimsy)
        grad_tensor_free(&x)
        return 1
    free(dimsy)
    var yp is slice of f32 = tensor_data_ptr(&yneg.data)
    var i0 is usize = 0
    while i0 < batch * out_dim do
        yp[i0] = 0.0 - ((0.0 + i0) * 0.0005)
        i0 = i0 + 1

    # Model params.
    var l1 is Linear
    var l2 is Linear
    if linear_init(&l1, in_dim, hid_dim, 1) != 0 then
        grad_tensor_free(&yneg)
        grad_tensor_free(&x)
        return 1
    if linear_init(&l2, hid_dim, out_dim, 1) != 0 then
        linear_free(&l1)
        grad_tensor_free(&yneg)
        grad_tensor_free(&x)
        return 1

    var opt is AdamW
    adamw_init(&opt, 0.01, 0.90, 0.999, 0.00000001, 0.0)
    var st1 is AdamWParam
    var st2 is AdamWParam
    if adamw_param_init(&st1, &l1.w.data) != 0 then
        linear_free(&l2)
        linear_free(&l1)
        grad_tensor_free(&yneg)
        grad_tensor_free(&x)
        return 1
    if adamw_param_init(&st2, &l2.w.data) != 0 then
        adamw_param_free(&st1)
        linear_free(&l2)
        linear_free(&l1)
        grad_tensor_free(&yneg)
        grad_tensor_free(&x)
        return 1

    var checksum is f32 = 0.0
    var t0 is u64 = now_ns()

    var step is usize = 0
    while step < iters do
        if grad_tensor_zero_grad(&l1.w) != 0 then
            return 1
        if grad_tensor_zero_grad(&l2.w) != 0 then
            return 1

        var h is GradTensor
        var h2 is GradTensor
        var yhat is GradTensor
        var diff is GradTensor
        var diff2 is GradTensor
        var loss is GradTensor

        if linear_forward(&h, &x, &l1) != 0 then
            return 1
        if grad_tensor_relu(&h2, &h) != 0 then
            return 1
        if linear_forward(&yhat, &h2, &l2) != 0 then
            return 1
        if grad_tensor_add(&diff, &yhat, &yneg) != 0 then
            return 1
        if grad_tensor_mul(&diff2, &diff, &diff) != 0 then
            return 1
        if grad_tensor_sum_all(&loss, &diff2) != 0 then
            return 1
        if grad_tensor_backward(&loss) != 0 then
            return 1

        var lp is slice of f32 = tensor_data_ptr(&loss.data)
        checksum = checksum + lp[0]

        adamw_tick(&opt)
        if adamw_step(&opt, &l1.w, &st1) != 0 then
            return 1
        if adamw_step(&opt, &l2.w, &st2) != 0 then
            return 1

        grad_tensor_free(&loss)
        grad_tensor_free(&diff2)
        grad_tensor_free(&diff)
        grad_tensor_free(&yhat)
        grad_tensor_free(&h2)
        grad_tensor_free(&h)

        step = step + 1

    var t1 is u64 = now_ns()
    print_u64(t1 - t0)

    # Prevent extreme dead-code elimination.
    if checksum == 1234567.0 then
        return 1

    adamw_param_free(&st2)
    adamw_param_free(&st1)
    linear_free(&l2)
    linear_free(&l1)
    grad_tensor_free(&yneg)
    grad_tensor_free(&x)
    return 0

