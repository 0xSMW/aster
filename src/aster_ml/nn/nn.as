# aster_ml.nn.nn (v1)
#
# Minimal NN layers + optimizers for the Aster ML bring-up.
#
# v1 scope:
# - float32, CPU-first
# - Linear layer (autograd-friendly via `aster_ml.gradient.GradTensor`)
# - Embedding/RMSNorm/SDPA forward-only utilities (descriptor `Tensor`)
# - SGD + AdamW (per-parameter state)

use core.libc
use aster_ml.tensor
use aster_ml.gradient
use aster_ml.dtype
use aster_ml.device

# libm (macOS: in libSystem; Linux may require -lm)
extern def expf(x is f32) returns f32
extern def sqrtf(x is f32) returns f32


def abs_f32(x is f32) returns f32
    if x < 0.0 then
        return 0.0 - x
    return x


# -----------------------------
# Linear (GradTensor)
# -----------------------------

struct Linear
    var w is GradTensor  # (in_dim, out_dim)
    var in_dim is usize
    var out_dim is usize


def linear_init(l is mut ref Linear, in_dim is usize, out_dim is usize, requires_grad is i32) returns i32
    (*l).in_dim = in_dim
    (*l).out_dim = out_dim
    var dims is slice of usize = malloc(2 * 8)
    if dims is null then
        return 1
    dims[0] = in_dim
    dims[1] = out_dim
    var rc is i32 = grad_tensor_init_leaf(&(*l).w, 2, dims, requires_grad)
    free(dims)
    if rc != 0 then
        return 1
    # Deterministic small init: w[i] = (i+1)*0.01
    var wp is slice of f32 = tensor_data_ptr(&(*l).w.data)
    var n is usize = in_dim * out_dim
    var i is usize = 0
    while i < n do
        wp[i] = (1.0 + i) * 0.01
        i = i + 1
    return 0


def linear_free(l is mut ref Linear) returns ()
    grad_tensor_free(&(*l).w)
    (*l).in_dim = 0
    (*l).out_dim = 0
    return


def linear_forward(out is mut ref GradTensor, x is mut ref GradTensor, l is mut ref Linear) returns i32
    # x: (batch, in_dim)
    return grad_tensor_matmul(out, x, &(*l).w)


# -----------------------------
# Embedding (forward-only, Tensor)
# -----------------------------

struct Embedding
    var weight is Tensor  # (vocab, dim)
    var vocab is usize
    var dim is usize


def embedding_init(e is mut ref Embedding, vocab is usize, dim is usize) returns i32
    (*e).vocab = vocab
    (*e).dim = dim
    var dims is slice of usize = malloc(2 * 8)
    if dims is null then
        return 1
    dims[0] = vocab
    dims[1] = dim
    var rc is i32 = tensor_init_contiguous(&(*e).weight, DT_F32, DEV_CPU, 2, dims)
    free(dims)
    if rc != 0 then
        return 1
    # Deterministic init: weight[row,col] = (row*dim+col+1)*0.001
    var wp is slice of f32 = tensor_data_ptr(&(*e).weight)
    var n is usize = vocab * dim
    var i is usize = 0
    while i < n do
        wp[i] = (1.0 + i) * 0.001
        i = i + 1
    return 0


def embedding_free(e is mut ref Embedding) returns ()
    tensor_free(&(*e).weight)
    (*e).vocab = 0
    (*e).dim = 0
    return


def embedding_forward(out is mut ref Tensor, e is mut ref Embedding, idx is slice of usize, n_idx is usize) returns i32
    # out: (n_idx, dim), weight: (vocab, dim)
    if (*e).weight.ndim != 2 then
        return 1
    if tensor_is_contiguous(&(*e).weight) == 0 then
        return 1
    var wsh is slice of usize = (*e).weight.shape
    if wsh[0] != (*e).vocab or wsh[1] != (*e).dim then
        return 1

    var dims is slice of usize = malloc(2 * 8)
    if dims is null then
        return 1
    dims[0] = n_idx
    dims[1] = (*e).dim
    if tensor_init_contiguous(out, DT_F32, DEV_CPU, 2, dims) != 0 then
        free(dims)
        return 1
    free(dims)

    var outp is slice of f32 = tensor_data_ptr(out)
    var wp is slice of f32 = tensor_data_ptr(&(*e).weight)
    var dim is usize = (*e).dim
    var vocab is usize = (*e).vocab
    var i is usize = 0
    while i < n_idx do
        var id is usize = idx[i]
        if id >= vocab then
            return 1
        var src_base is usize = id * dim
        var dst_base is usize = i * dim
        var j is usize = 0
        while j < dim do
            outp[dst_base + j] = wp[src_base + j]
            j = j + 1
        i = i + 1
    return 0


# -----------------------------
# RMSNorm (forward-only, Tensor)
# -----------------------------

struct RMSNorm
    var weight is Tensor  # (dim)
    var dim is usize
    var eps is f32


def rmsnorm_init(n is mut ref RMSNorm, dim is usize, eps is f32) returns i32
    (*n).dim = dim
    (*n).eps = eps
    var dims is slice of usize = malloc(1 * 8)
    if dims is null then
        return 1
    dims[0] = dim
    var rc is i32 = tensor_init_contiguous(&(*n).weight, DT_F32, DEV_CPU, 1, dims)
    free(dims)
    if rc != 0 then
        return 1
    if tensor_fill_f32(&(*n).weight, 1.0) != 0 then
        tensor_free(&(*n).weight)
        return 1
    return 0


def rmsnorm_free(n is mut ref RMSNorm) returns ()
    tensor_free(&(*n).weight)
    (*n).dim = 0
    (*n).eps = 0.0
    return


def rmsnorm_forward(out is mut ref Tensor, x is mut ref Tensor, n is mut ref RMSNorm) returns i32
    # Supports x.ndim in {2,3}; normalizes across last dim only.
    if (*x).dtype != DT_F32 then
        return 1
    if ((*x).ndim != 2 and (*x).ndim != 3) then
        return 1
    if tensor_is_contiguous(x) == 0 then
        return 1
    if tensor_is_contiguous(&(*n).weight) == 0 then
        return 1

    var dim is usize = (*n).dim
    var xsh is slice of usize = (*x).shape
    if (*x).ndim == 2 then
        if xsh[1] != dim then
            return 1
    else
        if xsh[2] != dim then
            return 1

    # out = same shape
    if tensor_init_contiguous(out, DT_F32, DEV_CPU, (*x).ndim, (*x).shape) != 0 then
        return 1

    var xp is slice of f32 = tensor_data_ptr(x)
    var op is slice of f32 = tensor_data_ptr(out)
    var wp is slice of f32 = tensor_data_ptr(&(*n).weight)

    var rows is usize = 0
    if (*x).ndim == 2 then
        rows = xsh[0]
    else
        rows = xsh[0] * xsh[1]

    var r is usize = 0
    while r < rows do
        var base is usize = r * dim
        var ms is f32 = 0.0
        var j is usize = 0
        while j < dim do
            var v is f32 = xp[base + j]
            ms = ms + (v * v)
            j = j + 1
        ms = ms / dim
        var inv_rms is f32 = 1.0 / sqrtf(ms + (*n).eps)
        var k is usize = 0
        while k < dim do
            op[base + k] = xp[base + k] * inv_rms * wp[k]
            k = k + 1
        r = r + 1
    return 0


# -----------------------------
# SDPA (forward-only, Tensor)
# -----------------------------

def softmax_inplace_f32(buf is slice of f32, n is usize) returns ()
    if n == 0 then
        return
    var i is usize = 0
    var m is f32 = buf[0]
    i = 1
    while i < n do
        var v is f32 = buf[i]
        if v > m then
            m = v
        i = i + 1
    var sum is f32 = 0.0
    i = 0
    while i < n do
        var e is f32 = expf(buf[i] - m)
        buf[i] = e
        sum = sum + e
        i = i + 1
    if sum == 0.0 then
        var inv is f32 = 1.0 / n
        i = 0
        while i < n do
            buf[i] = inv
            i = i + 1
        return
    var inv_sum is f32 = 1.0 / sum
    i = 0
    while i < n do
        buf[i] = buf[i] * inv_sum
        i = i + 1
    return


def sdpa_forward(out is mut ref Tensor, q is mut ref Tensor, k is mut ref Tensor, v is mut ref Tensor) returns i32
    # q,k,v: (batch, seq, dim), out: (batch, seq, dim)
    if (*q).dtype != DT_F32 or (*k).dtype != DT_F32 or (*v).dtype != DT_F32 then
        return 1
    if (*q).ndim != 3 or (*k).ndim != 3 or (*v).ndim != 3 then
        return 1
    if tensor_is_contiguous(q) == 0 or tensor_is_contiguous(k) == 0 or tensor_is_contiguous(v) == 0 then
        return 1

    var qsh is slice of usize = (*q).shape
    var ksh is slice of usize = (*k).shape
    var vsh is slice of usize = (*v).shape
    if ksh[0] != qsh[0] or vsh[0] != qsh[0] then
        return 1
    if ksh[1] != qsh[1] or vsh[1] != qsh[1] then
        return 1
    if ksh[2] != qsh[2] or vsh[2] != qsh[2] then
        return 1

    if tensor_init_contiguous(out, DT_F32, DEV_CPU, 3, qsh) != 0 then
        return 1

    var batch is usize = qsh[0]
    var seq is usize = qsh[1]
    var dim is usize = qsh[2]
    if dim == 0 then
        return 1
    var scale is f32 = 1.0 / sqrtf(dim)

    var tmp is slice of f32 = malloc(seq * 4)
    if tmp is null then
        tensor_free(out)
        return 1

    var qp is slice of f32 = tensor_data_ptr(q)
    var kp is slice of f32 = tensor_data_ptr(k)
    var vp is slice of f32 = tensor_data_ptr(v)
    var op is slice of f32 = tensor_data_ptr(out)

    var b0 is usize = 0
    while b0 < batch do
        var i0 is usize = 0
        while i0 < seq do
            # scores[j] = dot(q[b,i,:], k[b,j,:]) * scale
            var j0 is usize = 0
            while j0 < seq do
                var dot is f32 = 0.0
                var d0 is usize = 0
                var qbase is usize = ((b0 * seq + i0) * dim)
                var kbase is usize = ((b0 * seq + j0) * dim)
                while d0 < dim do
                    dot = dot + qp[qbase + d0] * kp[kbase + d0]
                    d0 = d0 + 1
                tmp[j0] = dot * scale
                j0 = j0 + 1
            softmax_inplace_f32(tmp, seq)
            # out[b,i,:] = sum_j tmp[j] * v[b,j,:]
            var d1 is usize = 0
            var obase is usize = ((b0 * seq + i0) * dim)
            while d1 < dim do
                var acc is f32 = 0.0
                var jj is usize = 0
                while jj < seq do
                    var vbase is usize = ((b0 * seq + jj) * dim)
                    acc = acc + tmp[jj] * vp[vbase + d1]
                    jj = jj + 1
                op[obase + d1] = acc
                d1 = d1 + 1
            i0 = i0 + 1
        b0 = b0 + 1

    free(tmp)
    return 0


# -----------------------------
# Optimizers (per-parameter)
# -----------------------------

struct SGD
    var lr is f32
    var weight_decay is f32


def sgd_init(opt is mut ref SGD, lr is f32, weight_decay is f32) returns ()
    (*opt).lr = lr
    (*opt).weight_decay = weight_decay
    return


def sgd_step(opt is mut ref SGD, p is mut ref GradTensor) returns i32
    if (*p).grad_ready == 0 then
        return 0
    if tensor_is_contiguous(&(*p).data) == 0 or tensor_is_contiguous(&(*p).grad) == 0 then
        return 1
    var n is usize = tensor_numel(&(*p).data)
    var w is slice of f32 = tensor_data_ptr(&(*p).data)
    var g is slice of f32 = tensor_data_ptr(&(*p).grad)
    var lr is f32 = (*opt).lr
    var wd is f32 = (*opt).weight_decay
    var i is usize = 0
    while i < n do
        var gg is f32 = g[i]
        if wd != 0.0 then
            gg = gg + wd * w[i]
        w[i] = w[i] - lr * gg
        i = i + 1
    return 0


struct AdamW
    var lr is f32
    var beta1 is f32
    var beta2 is f32
    var eps is f32
    var weight_decay is f32
    var step is u64


struct AdamWParam
    var m is Tensor
    var v is Tensor


def adamw_init(opt is mut ref AdamW, lr is f32, beta1 is f32, beta2 is f32, eps is f32, weight_decay is f32) returns ()
    (*opt).lr = lr
    (*opt).beta1 = beta1
    (*opt).beta2 = beta2
    (*opt).eps = eps
    (*opt).weight_decay = weight_decay
    (*opt).step = 0
    return


def adamw_tick(opt is mut ref AdamW) returns ()
    (*opt).step = (*opt).step + 1
    return


def adamw_param_init(st is mut ref AdamWParam, like is mut ref Tensor) returns i32
    tensor_reset(&(*st).m)
    tensor_reset(&(*st).v)
    if tensor_init_contiguous(&(*st).m, DT_F32, DEV_CPU, (*like).ndim, (*like).shape) != 0 then
        return 1
    if tensor_init_contiguous(&(*st).v, DT_F32, DEV_CPU, (*like).ndim, (*like).shape) != 0 then
        tensor_free(&(*st).m)
        return 1
    if tensor_fill_f32(&(*st).m, 0.0) != 0 then
        tensor_free(&(*st).v)
        tensor_free(&(*st).m)
        return 1
    if tensor_fill_f32(&(*st).v, 0.0) != 0 then
        tensor_free(&(*st).v)
        tensor_free(&(*st).m)
        return 1
    return 0


def adamw_param_free(st is mut ref AdamWParam) returns ()
    tensor_free(&(*st).m)
    tensor_free(&(*st).v)
    return


def adamw_step(opt is mut ref AdamW, p is mut ref GradTensor, st is mut ref AdamWParam) returns i32
    if (*p).grad_ready == 0 then
        return 0
    if (*opt).step == 0 then
        return 1
    if tensor_is_contiguous(&(*p).data) == 0 or tensor_is_contiguous(&(*p).grad) == 0 then
        return 1
    if tensor_is_contiguous(&(*st).m) == 0 or tensor_is_contiguous(&(*st).v) == 0 then
        return 1
    if tensor_numel(&(*st).m) != tensor_numel(&(*p).data) then
        return 1
    if tensor_numel(&(*st).v) != tensor_numel(&(*p).data) then
        return 1

    var n is usize = tensor_numel(&(*p).data)
    var w is slice of f32 = tensor_data_ptr(&(*p).data)
    var g is slice of f32 = tensor_data_ptr(&(*p).grad)
    var m is slice of f32 = tensor_data_ptr(&(*st).m)
    var v is slice of f32 = tensor_data_ptr(&(*st).v)

    var lr is f32 = (*opt).lr
    var b1 is f32 = (*opt).beta1
    var b2 is f32 = (*opt).beta2
    var eps is f32 = (*opt).eps
    var wd is f32 = (*opt).weight_decay

    # Bias correction (scalar, step small in tests).
    var b1t is f32 = 1.0
    var b2t is f32 = 1.0
    var i0 is u64 = 0
    while i0 < (*opt).step do
        b1t = b1t * b1
        b2t = b2t * b2
        i0 = i0 + 1
    var bc1 is f32 = 1.0 - b1t
    var bc2 is f32 = 1.0 - b2t
    if bc1 == 0.0 or bc2 == 0.0 then
        return 1

    var i is usize = 0
    while i < n do
        var gg is f32 = g[i]
        if wd != 0.0 then
            gg = gg + wd * w[i]
        m[i] = b1 * m[i] + (1.0 - b1) * gg
        v[i] = b2 * v[i] + (1.0 - b2) * (gg * gg)
        var mh is f32 = m[i] / bc1
        var vh is f32 = v[i] / bc2
        w[i] = w[i] - lr * (mh / (sqrtf(vh) + eps))
        i = i + 1
    return 0
