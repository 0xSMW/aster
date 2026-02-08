# Expected: compile+run OK (tensor descriptor + movement semantics)

use aster_ml.tensor
use aster_ml.dtype
use aster_ml.device
use core.io
use core.libc

def abs_f32(x is f32) returns f32
    if x < 0.0 then
        return 0.0 - x
    return x

def main() returns i32
    # a: (2,3) contiguous, fill with 1..6
    var dims is slice of usize = malloc(2 * 8)
    if dims is null then
        return 1
    dims[0] = 2
    dims[1] = 3

    var a is Tensor
    if tensor_init_contiguous(&a, DT_F32, DEV_CPU, 2, dims) != 0 then
        free(dims)
        return 1
    free(dims)

    var ap is slice of f32 = tensor_data_ptr(&a)
    ap[0] = 1.0
    ap[1] = 2.0
    ap[2] = 3.0
    ap[3] = 4.0
    ap[4] = 5.0
    ap[5] = 6.0

    # reshape view: (3,2)
    var rd is slice of usize = malloc(2 * 8)
    if rd is null then
        tensor_free(&a)
        return 1
    rd[0] = 3
    rd[1] = 2
    var r is Tensor
    if tensor_reshape(&r, &a, 2, rd) != 0 then
        free(rd)
        tensor_free(&a)
        return 1
    free(rd)

    # permute view: swap dims back to (2,3)
    var perm is slice of usize = malloc(2 * 8)
    if perm is null then
        tensor_free(&r)
        tensor_free(&a)
        return 1
    perm[0] = 1
    perm[1] = 0
    var p is Tensor
    if tensor_permute(&p, &r, perm) != 0 then
        free(perm)
        tensor_free(&r)
        tensor_free(&a)
        return 1
    free(perm)

    var want is slice of usize = malloc(2 * 8)
    if want is null then
        tensor_free(&p)
        tensor_free(&r)
        tensor_free(&a)
        return 1
    want[0] = 2
    want[1] = 3
    var starts is slice of usize = malloc(2 * 8)
    var ends is slice of usize = malloc(2 * 8)
    if starts is null or ends is null then
        if starts is not null then
            free(starts)
        if ends is not null then
            free(ends)
        free(want)
        tensor_free(&p)
        tensor_free(&r)
        tensor_free(&a)
        return 1
    starts[0] = 0
    starts[1] = 0
    ends[0] = 2
    ends[1] = 3

    # p should still index like a (just a view chain)
    var idx is slice of usize = malloc(2 * 8)
    if idx is null then
        free(ends)
        free(starts)
        free(want)
        tensor_free(&p)
        tensor_free(&r)
        tensor_free(&a)
        return 1
    idx[0] = 1
    idx[1] = 2
    var v is f32 = 0.0
    if tensor_get_f32(&p, idx, &v) != 0 then
        free(idx)
        free(ends)
        free(starts)
        free(want)
        tensor_free(&p)
        tensor_free(&r)
        tensor_free(&a)
        return 1
    if abs_f32(v - 6.0) > 0.0001 then
        return 1
    free(idx)

    # shrink: take [:, 1:3] => (2,2)
    starts[0] = 0
    starts[1] = 1
    ends[0] = 2
    ends[1] = 3
    var s is Tensor
    if tensor_shrink(&s, &a, starts, ends) != 0 then
        free(ends)
        free(starts)
        free(want)
        tensor_free(&p)
        tensor_free(&r)
        tensor_free(&a)
        return 1
    free(ends)
    free(starts)
    free(want)

    # tolist on non-contiguous view should work
    var outp is MutString = null
    var outn is usize = 0
    if tensor_tolist_f32(&outp, &outn, &s) != 0 then
        tensor_free(&s)
        tensor_free(&p)
        tensor_free(&r)
        tensor_free(&a)
        return 1
    if outn != 4 then
        free(outp)
        return 1
    var flat is slice of f32 = outp
    # expected [[2,3],[5,6]]
    if abs_f32(flat[0] - 2.0) > 0.0001 then
        return 1
    if abs_f32(flat[1] - 3.0) > 0.0001 then
        return 1
    if abs_f32(flat[2] - 5.0) > 0.0001 then
        return 1
    if abs_f32(flat[3] - 6.0) > 0.0001 then
        return 1
    free(outp)

    # reduction axis behavior: sum over axis=1 => [6,15]
    var sum1 is Tensor
    tensor_reset(&sum1)
    if tensor_sum_axis_f32(&sum1, &a, 1, 0) != 0 then
        return 1
    var sump is slice of f32 = tensor_data_ptr(&sum1)
    if abs_f32(sump[0] - 6.0) > 0.0001 then
        return 1
    if abs_f32(sump[1] - 15.0) > 0.0001 then
        return 1
    tensor_free(&sum1)

    # flip + pad movement ops (1D)
    var dims1 is slice of usize = malloc(1 * 8)
    if dims1 is null then
        return 1
    dims1[0] = 3
    var t is Tensor
    tensor_reset(&t)
    if tensor_init_contiguous(&t, DT_F32, DEV_CPU, 1, dims1) != 0 then
        free(dims1)
        return 1
    free(dims1)
    var tp0 is slice of f32 = tensor_data_ptr(&t)
    tp0[0] = 1.0
    tp0[1] = 2.0
    tp0[2] = 3.0

    var tf is Tensor
    tensor_reset(&tf)
    if tensor_flip(&tf, &t, 0) != 0 then
        tensor_free(&t)
        return 1
    var tfp is MutString = null
    var tfn is usize = 0
    if tensor_tolist_f32(&tfp, &tfn, &tf) != 0 then
        tensor_free(&tf)
        tensor_free(&t)
        return 1
    if tfn != 3 then
        free(tfp)
        tensor_free(&tf)
        tensor_free(&t)
        return 1
    var tff is slice of f32 = tfp
    if abs_f32(tff[0] - 3.0) > 0.0001 then
        return 1
    if abs_f32(tff[1] - 2.0) > 0.0001 then
        return 1
    if abs_f32(tff[2] - 1.0) > 0.0001 then
        return 1
    free(tfp)
    tensor_free(&tf)

    var pads is slice of usize = malloc(2 * 8)
    if pads is null then
        tensor_free(&t)
        return 1
    pads[0] = 2
    pads[1] = 1
    var tpad is Tensor
    tensor_reset(&tpad)
    if tensor_pad_f32(&tpad, &t, pads) != 0 then
        free(pads)
        tensor_free(&t)
        return 1
    free(pads)
    var pp is MutString = null
    var pn is usize = 0
    if tensor_tolist_f32(&pp, &pn, &tpad) != 0 then
        tensor_free(&tpad)
        tensor_free(&t)
        return 1
    if pn != 6 then
        free(pp)
        tensor_free(&tpad)
        tensor_free(&t)
        return 1
    var pf is slice of f32 = pp
    # expected: [0,0,1,2,3,0]
    if abs_f32(pf[0] - 0.0) > 0.0001 then
        return 1
    if abs_f32(pf[1] - 0.0) > 0.0001 then
        return 1
    if abs_f32(pf[2] - 1.0) > 0.0001 then
        return 1
    if abs_f32(pf[3] - 2.0) > 0.0001 then
        return 1
    if abs_f32(pf[4] - 3.0) > 0.0001 then
        return 1
    if abs_f32(pf[5] - 0.0) > 0.0001 then
        return 1
    free(pp)
    tensor_free(&tpad)
    tensor_free(&t)

    tensor_free(&s)
    tensor_free(&p)
    tensor_free(&r)
    tensor_free(&a)
    println("ok")
    return 0
