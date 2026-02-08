# Expected: compile+run OK (NN forward smoke + tiny deterministic training with AdamW)

use aster_ml.tensor
use aster_ml.gradient
use aster_ml.nn.nn
use aster_ml.dtype
use aster_ml.device
use core.io
use core.libc


def abs_f32(x is f32) returns f32
    if x < 0.0 then
        return 0.0 - x
    return x


def nn_forward_smoke() returns i32
    # Embedding smoke (forward-only).
    var e is Embedding
    if embedding_init(&e, 4, 3) != 0 then
        return 1
    var idx is slice of usize = malloc(3 * 8)
    if idx is null then
        embedding_free(&e)
        return 1
    idx[0] = 3
    idx[1] = 1
    idx[2] = 0
    var emb is Tensor
    tensor_reset(&emb)
    if embedding_forward(&emb, &e, idx, 3) != 0 then
        free(idx)
        embedding_free(&e)
        return 1
    var ep is slice of f32 = tensor_data_ptr(&emb)
    # weight[3,*] => indices 9..11 => 0.010,0.011,0.012
    if abs_f32(ep[0] - 0.010) > 0.000001 then
        return 1
    if abs_f32(ep[1] - 0.011) > 0.000001 then
        return 1
    if abs_f32(ep[2] - 0.012) > 0.000001 then
        return 1
    tensor_free(&emb)
    free(idx)
    embedding_free(&e)

    # RMSNorm smoke (forward-only, uses sqrtf).
    var rn is RMSNorm
    if rmsnorm_init(&rn, 4, 0.00001) != 0 then
        return 1
    var dims is slice of usize = malloc(2 * 8)
    if dims is null then
        rmsnorm_free(&rn)
        return 1
    dims[0] = 2
    dims[1] = 4
    var rx is Tensor
    var ro is Tensor
    tensor_reset(&rx)
    tensor_reset(&ro)
    if tensor_init_contiguous(&rx, DT_F32, DEV_CPU, 2, dims) != 0 then
        free(dims)
        rmsnorm_free(&rn)
        return 1
    free(dims)
    var rxp is slice of f32 = tensor_data_ptr(&rx)
    rxp[0] = 1.0
    rxp[1] = 2.0
    rxp[2] = 3.0
    rxp[3] = 4.0
    rxp[4] = 2.0
    rxp[5] = 0.0
    rxp[6] = 1.0
    rxp[7] = 3.0
    if rmsnorm_forward(&ro, &rx, &rn) != 0 then
        tensor_free(&rx)
        rmsnorm_free(&rn)
        return 1
    var rop is slice of f32 = tensor_data_ptr(&ro)
    # sanity: first output is finite and in a reasonable range.
    if rop[0] != rop[0] then
        return 1
    if rop[0] < 0.35 or rop[0] > 0.38 then
        return 1
    tensor_free(&ro)
    tensor_free(&rx)
    rmsnorm_free(&rn)

    # SDPA smoke (forward-only, uses expf + sqrtf).
    var dims3 is slice of usize = malloc(3 * 8)
    if dims3 is null then
        return 1
    dims3[0] = 1
    dims3[1] = 2
    dims3[2] = 2
    var q is Tensor
    var k is Tensor
    var v is Tensor
    var ao is Tensor
    tensor_reset(&q)
    tensor_reset(&k)
    tensor_reset(&v)
    tensor_reset(&ao)
    if tensor_init_contiguous(&q, DT_F32, DEV_CPU, 3, dims3) != 0 then
        free(dims3)
        return 1
    if tensor_init_contiguous(&k, DT_F32, DEV_CPU, 3, dims3) != 0 then
        free(dims3)
        tensor_free(&q)
        return 1
    if tensor_init_contiguous(&v, DT_F32, DEV_CPU, 3, dims3) != 0 then
        free(dims3)
        tensor_free(&k)
        tensor_free(&q)
        return 1
    free(dims3)
    var qp is slice of f32 = tensor_data_ptr(&q)
    var kp is slice of f32 = tensor_data_ptr(&k)
    var vp is slice of f32 = tensor_data_ptr(&v)
    # q = [[1,0],[0,1]]
    qp[0] = 1.0
    qp[1] = 0.0
    qp[2] = 0.0
    qp[3] = 1.0
    # k = [[1,0],[0,1]]
    kp[0] = 1.0
    kp[1] = 0.0
    kp[2] = 0.0
    kp[3] = 1.0
    # v = [[1,2],[3,4]]
    vp[0] = 1.0
    vp[1] = 2.0
    vp[2] = 3.0
    vp[3] = 4.0
    if sdpa_forward(&ao, &q, &k, &v) != 0 then
        return 1
    var aop is slice of f32 = tensor_data_ptr(&ao)
    # expected approx: [1.662,2.662, 2.338,3.338]
    if abs_f32(aop[0] - 1.662) > 0.02 then
        return 1
    if abs_f32(aop[1] - 2.662) > 0.02 then
        return 1
    if abs_f32(aop[2] - 2.338) > 0.02 then
        return 1
    if abs_f32(aop[3] - 3.338) > 0.02 then
        return 1
    tensor_free(&ao)
    tensor_free(&v)
    tensor_free(&k)
    tensor_free(&q)
    return 0


def train_once(loss0_out is mut ref f32, loss_last_out is mut ref f32) returns i32
    # x: (4,3)
    var dimsx is slice of usize = malloc(2 * 8)
    if dimsx is null then
        return 1
    dimsx[0] = 4
    dimsx[1] = 3
    var x is GradTensor
    if grad_tensor_init_leaf(&x, 2, dimsx, 0) != 0 then
        free(dimsx)
        return 1
    free(dimsx)
    var xp is slice of f32 = tensor_data_ptr(&x.data)
    xp[0] = 0.10
    xp[1] = 0.20
    xp[2] = 0.30
    xp[3] = 0.00
    xp[4] = 0.40
    xp[5] = 0.10
    xp[6] = 0.30
    xp[7] = 0.00
    xp[8] = 0.20
    xp[9] = 0.50
    xp[10] = 0.10
    xp[11] = 0.00

    # target y: (4,2) fixed (deterministic constants)
    var dimsy is slice of usize = malloc(2 * 8)
    if dimsy is null then
        grad_tensor_free(&x)
        return 1
    dimsy[0] = 4
    dimsy[1] = 2
    var yneg is GradTensor
    if grad_tensor_init_leaf(&yneg, 2, dimsy, 0) != 0 then
        free(dimsy)
        grad_tensor_free(&x)
        return 1
    free(dimsy)
    var ynp is slice of f32 = tensor_data_ptr(&yneg.data)
    # store -y directly so diff = pred + yneg
    ynp[0] = 0.0 - 0.10
    ynp[1] = 0.0 - 0.20
    ynp[2] = 0.0
    ynp[3] = 0.0 - 0.30
    ynp[4] = 0.0 - 0.20
    ynp[5] = 0.0 - 0.10
    ynp[6] = 0.0 - 0.40
    ynp[7] = 0.0

    # student network
    var l1 is Linear
    var l2 is Linear
    if linear_init(&l1, 3, 4, 1) != 0 then
        grad_tensor_free(&yneg)
        grad_tensor_free(&x)
        return 1
    if linear_init(&l2, 4, 2, 1) != 0 then
        linear_free(&l1)
        grad_tensor_free(&yneg)
        grad_tensor_free(&x)
        return 1

    var opt is AdamW
    adamw_init(&opt, 0.05, 0.90, 0.999, 0.00000001, 0.0)
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

    var step is usize = 0
    var loss0 is f32 = 0.0
    var loss_last is f32 = 0.0
    while step < 6 do
        # zero grads
        if grad_tensor_zero_grad(&l1.w) != 0 then
            return 1
        if grad_tensor_zero_grad(&l2.w) != 0 then
            return 1

        # forward: yhat = l2(relu(l1(x)))
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

        # diff = yhat - y = yhat + (-y)
        if grad_tensor_add(&diff, &yhat, &yneg) != 0 then
            return 1
        # squared error
        if grad_tensor_mul(&diff2, &diff, &diff) != 0 then
            return 1
        if grad_tensor_sum_all(&loss, &diff2) != 0 then
            return 1

        if grad_tensor_backward(&loss) != 0 then
            return 1

        var lp is slice of f32 = tensor_data_ptr(&loss.data)
        if step == 0 then
            loss0 = lp[0]
        loss_last = lp[0]

        # update
        adamw_tick(&opt)
        if adamw_step(&opt, &l1.w, &st1) != 0 then
            return 1
        if adamw_step(&opt, &l2.w, &st2) != 0 then
            return 1

        # Free intermediates only after backward (they carry autograd state).
        grad_tensor_free(&loss)
        grad_tensor_free(&diff2)
        grad_tensor_free(&diff)
        grad_tensor_free(&yhat)
        grad_tensor_free(&h2)
        grad_tensor_free(&h)
        step = step + 1

    *loss0_out = loss0
    *loss_last_out = loss_last

    adamw_param_free(&st2)
    adamw_param_free(&st1)
    linear_free(&l2)
    linear_free(&l1)
    grad_tensor_free(&yneg)
    grad_tensor_free(&x)
    return 0


def main() returns i32
    if nn_forward_smoke() != 0 then
        return 1

    var loss0 is f32 = 0.0
    var loss_last is f32 = 0.0
    if train_once(&loss0, &loss_last) != 0 then
        return 1
    if loss_last >= loss0 then
        return 1

    println("ok")
    return 0
