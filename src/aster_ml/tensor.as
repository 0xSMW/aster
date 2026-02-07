# aster_ml.tensor (v0)
#
# Bootstrapping tensor primitives (CPU, float32 only for now).

use core.libc

struct TensorF32
    # Note: struct field types currently don't accept `slice of T`, so store the
    # raw pointer and cast to `slice of f32` at use sites.
    var data is MutString
    var ndim is usize
    var d0 is usize
    var d1 is usize
    var d2 is usize

def tensor_f32_numel(t is mut ref TensorF32) returns usize
    if (*t).ndim == 0 then
        return 0
    if (*t).ndim == 1 then
        return (*t).d0
    if (*t).ndim == 2 then
        return (*t).d0 * (*t).d1
    return (*t).d0 * (*t).d1 * (*t).d2


def tensor_f32_init(t is mut ref TensorF32, ndim is usize, d0 is usize, d1 is usize, d2 is usize) returns i32
    (*t).ndim = ndim
    (*t).d0 = d0
    (*t).d1 = d1
    (*t).d2 = d2
    var n is usize = tensor_f32_numel(t)
    (*t).data = malloc(n * 4)
    if (*t).data is null then
        return 1
    return 0


def tensor_f32_free(t is mut ref TensorF32) returns ()
    if (*t).data is not null then
        free((*t).data)
    (*t).data = null
    (*t).ndim = 0
    (*t).d0 = 0
    (*t).d1 = 0
    (*t).d2 = 0
    return


def tensor_f32_fill(t is mut ref TensorF32, v is f32) returns ()
    var n is usize = tensor_f32_numel(t)
    var data is slice of f32 = (*t).data
    var i is usize = 0
    while i < n do
        data[i] = v
        i = i + 1
    return


def tensor_f32_add(out is mut ref TensorF32, a is mut ref TensorF32, b is mut ref TensorF32) returns i32
    var n is usize = tensor_f32_numel(a)
    if tensor_f32_numel(b) != n then
        return 1
    if tensor_f32_numel(out) != n then
        return 1
    var outp is slice of f32 = (*out).data
    var ap is slice of f32 = (*a).data
    var bp is slice of f32 = (*b).data
    var i is usize = 0
    while i < n do
        outp[i] = ap[i] + bp[i]
        i = i + 1
    return 0


def tensor_f32_mul(out is mut ref TensorF32, a is mut ref TensorF32, b is mut ref TensorF32) returns i32
    var n is usize = tensor_f32_numel(a)
    if tensor_f32_numel(b) != n then
        return 1
    if tensor_f32_numel(out) != n then
        return 1
    var outp is slice of f32 = (*out).data
    var ap is slice of f32 = (*a).data
    var bp is slice of f32 = (*b).data
    var i is usize = 0
    while i < n do
        outp[i] = ap[i] * bp[i]
        i = i + 1
    return 0


def tensor_f32_relu(out is mut ref TensorF32, a is mut ref TensorF32) returns i32
    var n is usize = tensor_f32_numel(a)
    if tensor_f32_numel(out) != n then
        return 1
    var outp is slice of f32 = (*out).data
    var ap is slice of f32 = (*a).data
    var i is usize = 0
    while i < n do
        var x is f32 = ap[i]
        if x < 0.0 then
            x = 0.0
        outp[i] = x
        i = i + 1
    return 0


def tensor_f32_sum1(out is mut ref f32, a is mut ref TensorF32) returns ()
    var n is usize = tensor_f32_numel(a)
    var ap is slice of f32 = (*a).data
    var s is f32 = 0.0
    var i is usize = 0
    while i < n do
        s = s + ap[i]
        i = i + 1
    *out = s
    return


def tensor_f32_matmul(out is mut ref TensorF32, a is mut ref TensorF32, b is mut ref TensorF32) returns i32
    # a: (m,k), b: (k,n), out: (m,n)
    if (*a).ndim != 2 or (*b).ndim != 2 or (*out).ndim != 2 then
        return 1
    var m is usize = (*a).d0
    var k is usize = (*a).d1
    if (*b).d0 != k then
        return 1
    var n is usize = (*b).d1
    if (*out).d0 != m or (*out).d1 != n then
        return 1

    var outp is slice of f32 = (*out).data
    var ap is slice of f32 = (*a).data
    var bp is slice of f32 = (*b).data
    var i is usize = 0
    while i < m do
        var j is usize = 0
        while j < n do
            var sum is f32 = 0.0
            var p is usize = 0
            while p < k do
                sum = sum + ap[i * k + p] * bp[p * n + j]
                p = p + 1
            outp[i * n + j] = sum
            j = j + 1
        i = i + 1
    return 0


def tensor_f32_permute_3(out is mut ref TensorF32, a is mut ref TensorF32, ax0 is usize, ax1 is usize, ax2 is usize) returns i32
    # Only supports 3D tensors for now.
    if (*a).ndim != 3 or (*out).ndim != 3 then
        return 1
    var ad0 is usize = (*a).d0
    var ad1 is usize = (*a).d1
    var ad2 is usize = (*a).d2

    # axes must be a permutation of {0,1,2}
    if ax0 > 2 or ax1 > 2 or ax2 > 2 then
        return 1
    if ax0 == ax1 or ax0 == ax2 or ax1 == ax2 then
        return 1

    var dims is slice of usize = malloc(3 * 8)
    if dims is null then
        return 1
    dims[0] = ad0
    dims[1] = ad1
    dims[2] = ad2

    var od0 is usize = dims[ax0]
    var od1 is usize = dims[ax1]
    var od2 is usize = dims[ax2]
    free(dims)

    if (*out).d0 != od0 or (*out).d1 != od1 or (*out).d2 != od2 then
        return 1

    var outp is slice of f32 = (*out).data
    var ap is slice of f32 = (*a).data
    var i is usize = 0
    while i < od0 do
        var j is usize = 0
        while j < od1 do
            var k is usize = 0
            while k < od2 do
                # Map output index (i,j,k) back to input (ia,ja,ka)
                var ia is usize = 0
                var ja is usize = 0
                var ka is usize = 0
                if ax0 == 0 then
                    ia = i
                else if ax0 == 1 then
                    ja = i
                else
                    ka = i
                if ax1 == 0 then
                    ia = j
                else if ax1 == 1 then
                    ja = j
                else
                    ka = j
                if ax2 == 0 then
                    ia = k
                else if ax2 == 1 then
                    ja = k
                else
                    ka = k
                outp[(i * od1 + j) * od2 + k] = ap[(ia * ad1 + ja) * ad2 + ka]
                k = k + 1
            j = j + 1
        i = i + 1
    return 0


# -----------------------------
# Extras (v0): helpers for autograd bring-up
# -----------------------------

def tensor_f32_add_inplace(dst is mut ref TensorF32, src is mut ref TensorF32) returns i32
    var n is usize = tensor_f32_numel(dst)
    if tensor_f32_numel(src) != n then
        return 1
    var dp is slice of f32 = (*dst).data
    var sp is slice of f32 = (*src).data
    var i is usize = 0
    while i < n do
        dp[i] = dp[i] + sp[i]
        i = i + 1
    return 0


def tensor_f32_add_scalar_inplace(dst is mut ref TensorF32, v is f32) returns ()
    var n is usize = tensor_f32_numel(dst)
    var dp is slice of f32 = (*dst).data
    var i is usize = 0
    while i < n do
        dp[i] = dp[i] + v
        i = i + 1
    return


def tensor_f32_transpose_2(out is mut ref TensorF32, a is mut ref TensorF32) returns i32
    # out: (n,m), a: (m,n)
    if (*a).ndim != 2 or (*out).ndim != 2 then
        return 1
    var m is usize = (*a).d0
    var n is usize = (*a).d1
    if (*out).d0 != n or (*out).d1 != m then
        return 1
    var ap is slice of f32 = (*a).data
    var op is slice of f32 = (*out).data
    var i is usize = 0
    while i < m do
        var j is usize = 0
        while j < n do
            op[j * m + i] = ap[i * n + j]
            j = j + 1
        i = i + 1
    return 0


# -----------------------------
# High-level Tensor (v0): minimal graph nodes for autograd bootstrap
# -----------------------------

const ML_NODE_NONE is i32 = 0
const ML_NODE_ADD is i32 = 1
const ML_NODE_SUM is i32 = 2
const ML_NODE_MATMUL is i32 = 3
const ML_NODE_PERMUTE3 is i32 = 4
const ML_NODE_MUL is i32 = 5
const ML_NODE_RELU is i32 = 6

struct Tensor
    var data is TensorF32
    var grad is TensorF32
    var requires_grad is i32
    var grad_ready is i32
    var node is MutString  # nullable `GradNode*`


struct GradNode
    var op is i32
    var a is mut ref Tensor
    var b is mut ref Tensor
    var ax0 is usize
    var ax1 is usize
    var ax2 is usize


def tensor_init_leaf(out is mut ref Tensor, ndim is usize, d0 is usize, d1 is usize, d2 is usize, requires_grad is i32) returns i32
    (*out).requires_grad = requires_grad
    (*out).grad_ready = 0
    (*out).node = null
    # init data
    if tensor_f32_init(&(*out).data, ndim, d0, d1, d2) != 0 then
        return 1
    # init grad (empty)
    (*out).grad.data = null
    (*out).grad.ndim = 0
    (*out).grad.d0 = 0
    (*out).grad.d1 = 0
    (*out).grad.d2 = 0
    return 0


def tensor_free(out is mut ref Tensor) returns ()
    tensor_f32_free(&(*out).data)
    if (*out).grad_ready != 0 then
        tensor_f32_free(&(*out).grad)
    (*out).grad_ready = 0
    (*out).requires_grad = 0
    if (*out).node is not null then
        free((*out).node)
    (*out).node = null
    return


def tensor_alloc_grad(t is mut ref Tensor) returns i32
    if (*t).requires_grad == 0 then
        return 0
    if (*t).grad_ready != 0 then
        return 0
    if tensor_f32_init(&(*t).grad, (*t).data.ndim, (*t).data.d0, (*t).data.d1, (*t).data.d2) != 0 then
        return 1
    tensor_f32_fill(&(*t).grad, 0.0)
    (*t).grad_ready = 1
    return 0


def tensor_zero_grad(t is mut ref Tensor) returns ()
    if (*t).grad_ready != 0 then
        tensor_f32_fill(&(*t).grad, 0.0)
    return


def tensor_add(out is mut ref Tensor, a is mut ref Tensor, b is mut ref Tensor) returns i32
    if tensor_init_leaf(out, (*a).data.ndim, (*a).data.d0, (*a).data.d1, (*a).data.d2, ((*a).requires_grad != 0) or ((*b).requires_grad != 0)) != 0 then
        return 1
    if tensor_f32_add(&(*out).data, &(*a).data, &(*b).data) != 0 then
        tensor_free(out)
        return 1
    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            tensor_free(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = ML_NODE_ADD
        (*n).a = a
        (*n).b = b
        (*n).ax0 = 0
        (*n).ax1 = 0
        (*n).ax2 = 0
        (*out).node = p
    return 0


def tensor_mul(out is mut ref Tensor, a is mut ref Tensor, b is mut ref Tensor) returns i32
    if tensor_init_leaf(out, (*a).data.ndim, (*a).data.d0, (*a).data.d1, (*a).data.d2, ((*a).requires_grad != 0) or ((*b).requires_grad != 0)) != 0 then
        return 1
    if tensor_f32_mul(&(*out).data, &(*a).data, &(*b).data) != 0 then
        tensor_free(out)
        return 1
    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            tensor_free(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = ML_NODE_MUL
        (*n).a = a
        (*n).b = b
        (*n).ax0 = 0
        (*n).ax1 = 0
        (*n).ax2 = 0
        (*out).node = p
    return 0


def tensor_relu(out is mut ref Tensor, a is mut ref Tensor) returns i32
    if tensor_init_leaf(out, (*a).data.ndim, (*a).data.d0, (*a).data.d1, (*a).data.d2, (*a).requires_grad) != 0 then
        return 1
    if tensor_f32_relu(&(*out).data, &(*a).data) != 0 then
        tensor_free(out)
        return 1
    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            tensor_free(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = ML_NODE_RELU
        (*n).a = a
        (*n).b = null
        (*n).ax0 = 0
        (*n).ax1 = 0
        (*n).ax2 = 0
        (*out).node = p
    return 0


def tensor_sum(out is mut ref Tensor, a is mut ref Tensor) returns i32
    # Scalar output modeled as 1D(1).
    if tensor_init_leaf(out, 1, 1, 1, 1, (*a).requires_grad) != 0 then
        return 1
    var s is f32 = 0.0
    tensor_f32_sum1(&s, &(*a).data)
    var op is slice of f32 = (*out).data.data
    op[0] = s
    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            tensor_free(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = ML_NODE_SUM
        (*n).a = a
        (*n).b = null
        (*n).ax0 = 0
        (*n).ax1 = 0
        (*n).ax2 = 0
        (*out).node = p
    return 0


def tensor_matmul(out is mut ref Tensor, a is mut ref Tensor, b is mut ref Tensor) returns i32
    if (*a).data.ndim != 2 or (*b).data.ndim != 2 then
        return 1
    var m is usize = (*a).data.d0
    var k is usize = (*a).data.d1
    if (*b).data.d0 != k then
        return 1
    var n is usize = (*b).data.d1
    if tensor_init_leaf(out, 2, m, n, 1, ((*a).requires_grad != 0) or ((*b).requires_grad != 0)) != 0 then
        return 1
    if tensor_f32_matmul(&(*out).data, &(*a).data, &(*b).data) != 0 then
        tensor_free(out)
        return 1
    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            tensor_free(out)
            return 1
        var nn is mut ref GradNode = p
        (*nn).op = ML_NODE_MATMUL
        (*nn).a = a
        (*nn).b = b
        (*nn).ax0 = 0
        (*nn).ax1 = 0
        (*nn).ax2 = 0
        (*out).node = p
    return 0


def tensor_permute_3(out is mut ref Tensor, a is mut ref Tensor, ax0 is usize, ax1 is usize, ax2 is usize) returns i32
    if (*a).data.ndim != 3 then
        return 1
    # compute output dims
    var dims is slice of usize = malloc(3 * 8)
    if dims is null then
        return 1
    dims[0] = (*a).data.d0
    dims[1] = (*a).data.d1
    dims[2] = (*a).data.d2
    var od0 is usize = dims[ax0]
    var od1 is usize = dims[ax1]
    var od2 is usize = dims[ax2]
    free(dims)

    if tensor_init_leaf(out, 3, od0, od1, od2, (*a).requires_grad) != 0 then
        return 1
    if tensor_f32_permute_3(&(*out).data, &(*a).data, ax0, ax1, ax2) != 0 then
        tensor_free(out)
        return 1
    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            tensor_free(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = ML_NODE_PERMUTE3
        (*n).a = a
        (*n).b = null
        (*n).ax0 = ax0
        (*n).ax1 = ax1
        (*n).ax2 = ax2
        (*out).node = p
    return 0
