# aster_ml.gradient (v1)
#
# Minimal reverse-mode autograd over a small float32 Tensor subset.
#
# v1 scope:
# - supports: add, mul, relu, matmul (2D), sum_all (to scalar)
# - gradient accumulation semantics (+= into existing grad buffers)
# - deterministic, CPU-first (Metal is used in matmul forward when tensors are on DEV_METAL)
#
# Note: this is intentionally simple and will be replaced by UOp-based rules
# once the lazy IR/scheduler stack is wired end-to-end.

use core.libc
use aster_ml.tensor
use aster_ml.dtype
use aster_ml.device


const GT_NODE_NONE is i32 = 0
const GT_NODE_ADD is i32 = 1
const GT_NODE_MUL is i32 = 2
const GT_NODE_RELU is i32 = 3
const GT_NODE_MATMUL is i32 = 4
const GT_NODE_SUM_ALL is i32 = 5
const GT_NODE_RESHAPE is i32 = 6
const GT_NODE_PERMUTE is i32 = 7


struct GradTensor
    var data is Tensor
    var grad is Tensor
    var requires_grad is i32
    var grad_ready is i32
    var node is MutString  # nullable `GradNode*`


struct GradNode
    var op is i32
    var a is mut ref GradTensor
    var b is mut ref GradTensor
    # For movement ops, store auxiliary metadata (owned via the node allocation).
    # - PERMUTE: `perm` is a `slice of usize` with length `perm_ndim`.
    var perm_ndim is usize
    var perm is MutString


def grad_tensor_reset(t is mut ref GradTensor) returns ()
    tensor_reset(&(*t).data)
    tensor_reset(&(*t).grad)
    (*t).requires_grad = 0
    (*t).grad_ready = 0
    (*t).node = null
    return


def grad_tensor_free(t is mut ref GradTensor) returns ()
    tensor_free(&(*t).data)
    if (*t).grad_ready != 0 then
        tensor_free(&(*t).grad)
    (*t).grad_ready = 0
    (*t).requires_grad = 0
    if (*t).node is not null then
        free((*t).node)
    (*t).node = null
    return


def grad_tensor_alloc_grad(t is mut ref GradTensor) returns i32
    if (*t).requires_grad == 0 then
        return 0
    if (*t).grad_ready != 0 then
        return 0
    if tensor_init_contiguous(&(*t).grad, (*t).data.dtype, (*t).data.device, (*t).data.ndim, (*t).data.shape) != 0 then
        return 1
    if tensor_fill_f32(&(*t).grad, 0.0) != 0 then
        tensor_free(&(*t).grad)
        tensor_reset(&(*t).grad)
        return 1
    (*t).grad_ready = 1
    return 0


def grad_tensor_zero_grad(t is mut ref GradTensor) returns i32
    if (*t).grad_ready == 0 then
        return 0
    return tensor_fill_f32(&(*t).grad, 0.0)


def tensor_add_inplace_f32(dst is mut ref Tensor, src is mut ref Tensor) returns i32
    if (*dst).dtype != DT_F32 or (*src).dtype != DT_F32 then
        return 1
    if (*dst).device != (*src).device then
        return 1
    if tensor_is_contiguous(dst) == 0 or tensor_is_contiguous(src) == 0 then
        return 1
    if tensor_numel(dst) != tensor_numel(src) then
        return 1
    var n is usize = tensor_numel(dst)
    var dp is slice of f32 = tensor_data_ptr(dst)
    var sp is slice of f32 = tensor_data_ptr(src)
    var i is usize = 0
    while i < n do
        dp[i] = dp[i] + sp[i]
        i = i + 1
    return 0


def tensor_add_scalar_inplace_f32(dst is mut ref Tensor, v is f32) returns i32
    if (*dst).dtype != DT_F32 then
        return 1
    if tensor_is_contiguous(dst) == 0 then
        return 1
    var n is usize = tensor_numel(dst)
    var dp is slice of f32 = tensor_data_ptr(dst)
    var i is usize = 0
    while i < n do
        dp[i] = dp[i] + v
        i = i + 1
    return 0


def grad_tensor_init_leaf(out is mut ref GradTensor, ndim is usize, dims is slice of usize, requires_grad is i32) returns i32
    grad_tensor_reset(out)
    (*out).requires_grad = requires_grad
    if tensor_init_contiguous(&(*out).data, DT_F32, DEV_CPU, ndim, dims) != 0 then
        grad_tensor_free(out)
        grad_tensor_reset(out)
        return 1
    return 0


def grad_tensor_from_tensor(out is mut ref GradTensor, t is mut ref Tensor, requires_grad is i32) returns i32
    # Take ownership of an already-initialized tensor descriptor.
    grad_tensor_reset(out)
    (*out).requires_grad = requires_grad
    (*out).data = *t
    # Caller should not use `t` after this.
    tensor_reset(t)
    return 0


def grad_tensor_add(out is mut ref GradTensor, a is mut ref GradTensor, b is mut ref GradTensor) returns i32
    grad_tensor_reset(out)
    (*out).requires_grad = ((*a).requires_grad != 0) or ((*b).requires_grad != 0)

    if tensor_add_f32(&(*out).data, &(*a).data, &(*b).data) != 0 then
        grad_tensor_free(out)
        grad_tensor_reset(out)
        return 1

    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            grad_tensor_free(out)
            grad_tensor_reset(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = GT_NODE_ADD
        (*n).a = a
        (*n).b = b
        (*n).perm_ndim = 0
        (*n).perm = null
        (*out).node = p
    return 0


def grad_tensor_mul(out is mut ref GradTensor, a is mut ref GradTensor, b is mut ref GradTensor) returns i32
    grad_tensor_reset(out)
    (*out).requires_grad = ((*a).requires_grad != 0) or ((*b).requires_grad != 0)

    if tensor_mul_f32(&(*out).data, &(*a).data, &(*b).data) != 0 then
        grad_tensor_free(out)
        grad_tensor_reset(out)
        return 1

    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            grad_tensor_free(out)
            grad_tensor_reset(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = GT_NODE_MUL
        (*n).a = a
        (*n).b = b
        (*n).perm_ndim = 0
        (*n).perm = null
        (*out).node = p
    return 0


def grad_tensor_relu(out is mut ref GradTensor, a is mut ref GradTensor) returns i32
    grad_tensor_reset(out)
    (*out).requires_grad = (*a).requires_grad

    if tensor_relu_f32(&(*out).data, &(*a).data) != 0 then
        grad_tensor_free(out)
        grad_tensor_reset(out)
        return 1

    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            grad_tensor_free(out)
            grad_tensor_reset(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = GT_NODE_RELU
        (*n).a = a
        (*n).b = null
        (*n).perm_ndim = 0
        (*n).perm = null
        (*out).node = p
    return 0


def grad_tensor_matmul(out is mut ref GradTensor, a is mut ref GradTensor, b is mut ref GradTensor) returns i32
    grad_tensor_reset(out)
    (*out).requires_grad = ((*a).requires_grad != 0) or ((*b).requires_grad != 0)

    if tensor_matmul_f32(&(*out).data, &(*a).data, &(*b).data) != 0 then
        grad_tensor_free(out)
        grad_tensor_reset(out)
        return 1

    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            grad_tensor_free(out)
            grad_tensor_reset(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = GT_NODE_MATMUL
        (*n).a = a
        (*n).b = b
        (*n).perm_ndim = 0
        (*n).perm = null
        (*out).node = p
    return 0


def grad_tensor_sum_all(out is mut ref GradTensor, a is mut ref GradTensor) returns i32
    grad_tensor_reset(out)
    (*out).requires_grad = (*a).requires_grad

    if tensor_sum_all_f32(&(*out).data, &(*a).data) != 0 then
        grad_tensor_free(out)
        grad_tensor_reset(out)
        return 1

    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            grad_tensor_free(out)
            grad_tensor_reset(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = GT_NODE_SUM_ALL
        (*n).a = a
        (*n).b = null
        (*n).perm_ndim = 0
        (*n).perm = null
        (*out).node = p
    return 0


def grad_tensor_reshape(out is mut ref GradTensor, a is mut ref GradTensor, ndim is usize, dims is slice of usize) returns i32
    grad_tensor_reset(out)
    (*out).requires_grad = (*a).requires_grad

    if tensor_reshape(&(*out).data, &(*a).data, ndim, dims) != 0 then
        grad_tensor_free(out)
        grad_tensor_reset(out)
        return 1

    if (*out).requires_grad != 0 then
        var p is MutString = malloc(64)
        if p is null then
            grad_tensor_free(out)
            grad_tensor_reset(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = GT_NODE_RESHAPE
        (*n).a = a
        (*n).b = null
        (*n).perm_ndim = 0
        (*n).perm = null
        (*out).node = p
    return 0


def grad_tensor_permute(out is mut ref GradTensor, a is mut ref GradTensor, perm is slice of usize) returns i32
    grad_tensor_reset(out)
    (*out).requires_grad = (*a).requires_grad

    if tensor_permute(&(*out).data, &(*a).data, perm) != 0 then
        grad_tensor_free(out)
        grad_tensor_reset(out)
        return 1

    if (*out).requires_grad != 0 then
        var nperm is usize = (*a).data.ndim
        var bytes is usize = 64 + (nperm * 8)
        var p is MutString = malloc(bytes)
        if p is null then
            grad_tensor_free(out)
            grad_tensor_reset(out)
            return 1
        var n is mut ref GradNode = p
        (*n).op = GT_NODE_PERMUTE
        (*n).a = a
        (*n).b = null
        (*n).perm_ndim = nperm
        (*n).perm = p + 64
        var dst is slice of usize = (*n).perm
        var i is usize = 0
        while i < nperm do
            dst[i] = perm[i]
            i = i + 1
        (*out).node = p
    return 0


def tensor_copy_any_to_contig_f32(dst is mut ref Tensor, src is mut ref Tensor) returns i32
    # Copy from an arbitrary strided f32 tensor into a contiguous tensor.
    if (*dst).dtype != DT_F32 or (*src).dtype != DT_F32 then
        return 1
    if (*dst).device != (*src).device then
        return 1
    if tensor_is_contiguous(dst) == 0 then
        return 1
    if (*dst).ndim != (*src).ndim then
        return 1
    if (*dst).ndim != 0 then
        var dsh is slice of usize = (*dst).shape
        var ssh is slice of usize = (*src).shape
        var i is usize = 0
        while i < (*dst).ndim do
            if dsh[i] != ssh[i] then
                return 1
            i = i + 1

    var n is usize = tensor_numel(dst)
    if n == 0 then
        return 0

    if (*dst).ndim == 0 then
        var v is f32 = 0.0
        var idx0 is slice of usize = null
        if tensor_get_f32(src, idx0, &v) != 0 then
            return 1
        var p0 is slice of f32 = tensor_data_ptr(dst)
        p0[0] = v
        return 0

    var idx is slice of usize = malloc((*dst).ndim * 8)
    if idx is null then
        return 1
    var sh is slice of usize = (*dst).shape
    var i0 is usize = 0
    while i0 < (*dst).ndim do
        idx[i0] = 0
        i0 = i0 + 1

    var k is usize = 0
    while k < n do
        var v is f32 = 0.0
        if tensor_get_f32(src, idx, &v) != 0 then
            free(idx)
            return 1
        var p is MutString = tensor_elem_ptr(dst, idx)
        if p is null then
            free(idx)
            return 1
        var fp is slice of f32 = p
        fp[0] = v

        # increment idx (odometer)
        var d is usize = (*dst).ndim
        while d > 0 do
            d = d - 1
            idx[d] = idx[d] + 1
            if idx[d] < sh[d] then
                break
            idx[d] = 0
        k = k + 1

    free(idx)
    return 0


def tensor_transpose_2d_contig_f32(out is mut ref Tensor, a is mut ref Tensor) returns i32
    if (*a).dtype != DT_F32 then
        return 1
    if (*a).ndim != 2 then
        return 1
    if tensor_is_contiguous(a) == 0 then
        return 1
    var sh is slice of usize = (*a).shape
    var m is usize = sh[0]
    var n is usize = sh[1]
    var dims is slice of usize = malloc(2 * 8)
    if dims is null then
        return 1
    dims[0] = n
    dims[1] = m
    if tensor_init_contiguous(out, DT_F32, (*a).device, 2, dims) != 0 then
        free(dims)
        return 1
    free(dims)
    var ap is slice of f32 = tensor_data_ptr(a)
    var op is slice of f32 = tensor_data_ptr(out)
    var i is usize = 0
    while i < m do
        var j is usize = 0
        while j < n do
            op[j * m + i] = ap[i * n + j]
            j = j + 1
        i = i + 1
    return 0


def grad_tensor_backward_visit(t is mut ref GradTensor) returns i32
    if (*t).node is null then
        return 0
    var n is mut ref GradNode = (*t).node

    if (*n).op == GT_NODE_ADD then
        var a is mut ref GradTensor = (*n).a
        var b is mut ref GradTensor = (*n).b
        var ra is i32 = (*a).requires_grad
        var rb is i32 = (*b).requires_grad
        if ra != 0 then
            if grad_tensor_alloc_grad(a) != 0 then
                return 1
            if tensor_add_inplace_f32(&(*a).grad, &(*t).grad) != 0 then
                return 1
        if rb != 0 then
            if grad_tensor_alloc_grad(b) != 0 then
                return 1
            if tensor_add_inplace_f32(&(*b).grad, &(*t).grad) != 0 then
                return 1
        if ra != 0 then
            if grad_tensor_backward_visit(a) != 0 then
                return 1
        if rb != 0 and b != a then
            if grad_tensor_backward_visit(b) != 0 then
                return 1
        return 0

    if (*n).op == GT_NODE_SUM_ALL then
        var a is mut ref GradTensor = (*n).a
        if (*a).requires_grad == 0 then
            return 0
        if grad_tensor_alloc_grad(a) != 0 then
            return 1
        # scalar grad broadcast
        var gp is slice of f32 = tensor_data_ptr(&(*t).grad)
        if tensor_add_scalar_inplace_f32(&(*a).grad, gp[0]) != 0 then
            return 1
        return grad_tensor_backward_visit(a)

    if (*n).op == GT_NODE_MUL then
        var a is mut ref GradTensor = (*n).a
        var b is mut ref GradTensor = (*n).b

        var ra is i32 = (*a).requires_grad
        var rb is i32 = (*b).requires_grad
        if ra != 0 then
            if grad_tensor_alloc_grad(a) != 0 then
                return 1
        if rb != 0 then
            if grad_tensor_alloc_grad(b) != 0 then
                return 1

        if tensor_is_contiguous(&(*t).grad) == 0 or tensor_is_contiguous(&(*a).data) == 0 or tensor_is_contiguous(&(*b).data) == 0 then
            return 1

        var n_elems is usize = tensor_numel(&(*t).grad)
        var gop is slice of f32 = tensor_data_ptr(&(*t).grad)
        var ap is slice of f32 = tensor_data_ptr(&(*a).data)
        var bp is slice of f32 = tensor_data_ptr(&(*b).data)
        if ra != 0 then
            var agp is slice of f32 = tensor_data_ptr(&(*a).grad)
            var i is usize = 0
            while i < n_elems do
                agp[i] = agp[i] + gop[i] * bp[i]
                i = i + 1
        if rb != 0 then
            var bgp is slice of f32 = tensor_data_ptr(&(*b).grad)
            var j is usize = 0
            while j < n_elems do
                bgp[j] = bgp[j] + gop[j] * ap[j]
                j = j + 1

        if ra != 0 then
            if grad_tensor_backward_visit(a) != 0 then
                return 1
        if rb != 0 and b != a then
            if grad_tensor_backward_visit(b) != 0 then
                return 1
        return 0

    if (*n).op == GT_NODE_RELU then
        var a is mut ref GradTensor = (*n).a
        if (*a).requires_grad == 0 then
            return 0
        if grad_tensor_alloc_grad(a) != 0 then
            return 1

        if tensor_is_contiguous(&(*t).grad) == 0 or tensor_is_contiguous(&(*a).data) == 0 then
            return 1

        var n_elems is usize = tensor_numel(&(*t).grad)
        var gop is slice of f32 = tensor_data_ptr(&(*t).grad)
        var ap is slice of f32 = tensor_data_ptr(&(*a).data)
        var agp is slice of f32 = tensor_data_ptr(&(*a).grad)
        var i is usize = 0
        while i < n_elems do
            if ap[i] > 0.0 then
                agp[i] = agp[i] + gop[i]
            i = i + 1
        return grad_tensor_backward_visit(a)

    if (*n).op == GT_NODE_MATMUL then
        var a is mut ref GradTensor = (*n).a
        var b is mut ref GradTensor = (*n).b

        var ra is i32 = (*a).requires_grad
        var rb is i32 = (*b).requires_grad
        if ra != 0 then
            if grad_tensor_alloc_grad(a) != 0 then
                return 1
        if rb != 0 then
            if grad_tensor_alloc_grad(b) != 0 then
                return 1

        # grad_a += grad_out.matmul(b^T)
        if ra != 0 then
            var bt is Tensor
            tensor_reset(&bt)
            if tensor_transpose_2d_contig_f32(&bt, &(*b).data) != 0 then
                return 1
            var ga is Tensor
            tensor_reset(&ga)
            if tensor_matmul_f32(&ga, &(*t).grad, &bt) != 0 then
                tensor_free(&bt)
                return 1
            if tensor_add_inplace_f32(&(*a).grad, &ga) != 0 then
                tensor_free(&ga)
                tensor_free(&bt)
                return 1
            tensor_free(&ga)
            tensor_free(&bt)

        # grad_b += a^T.matmul(grad_out)
        if rb != 0 then
            var at is Tensor
            tensor_reset(&at)
            if tensor_transpose_2d_contig_f32(&at, &(*a).data) != 0 then
                return 1
            var gb is Tensor
            tensor_reset(&gb)
            if tensor_matmul_f32(&gb, &at, &(*t).grad) != 0 then
                tensor_free(&at)
                return 1
            if tensor_add_inplace_f32(&(*b).grad, &gb) != 0 then
                tensor_free(&gb)
                tensor_free(&at)
                return 1
            tensor_free(&gb)
            tensor_free(&at)

        if ra != 0 then
            if grad_tensor_backward_visit(a) != 0 then
                return 1
        if rb != 0 and b != a then
            if grad_tensor_backward_visit(b) != 0 then
                return 1
        return 0

    if (*n).op == GT_NODE_RESHAPE then
        var a is mut ref GradTensor = (*n).a
        if (*a).requires_grad == 0 then
            return 0
        if grad_tensor_alloc_grad(a) != 0 then
            return 1
        var gv is Tensor
        tensor_reset(&gv)
        if tensor_reshape(&gv, &(*t).grad, (*a).data.ndim, (*a).data.shape) != 0 then
            return 1
        if tensor_add_inplace_f32(&(*a).grad, &gv) != 0 then
            tensor_free(&gv)
            return 1
        tensor_free(&gv)
        return grad_tensor_backward_visit(a)

    if (*n).op == GT_NODE_PERMUTE then
        var a is mut ref GradTensor = (*n).a
        if (*a).requires_grad == 0 then
            return 0
        if grad_tensor_alloc_grad(a) != 0 then
            return 1
        var nperm is usize = (*n).perm_ndim
        if nperm != (*a).data.ndim then
            return 1
        var perm is slice of usize = (*n).perm
        var inv is slice of usize = malloc(nperm * 8)
        if inv is null then
            return 1
        var i is usize = 0
        while i < nperm do
            inv[perm[i]] = i
            i = i + 1
        var gv is Tensor
        tensor_reset(&gv)
        if tensor_permute(&gv, &(*t).grad, inv) != 0 then
            free(inv)
            return 1
        free(inv)

        var tmp is Tensor
        tensor_reset(&tmp)
        if tensor_init_contiguous(&tmp, DT_F32, (*a).data.device, (*a).data.ndim, (*a).data.shape) != 0 then
            tensor_free(&gv)
            return 1
        if tensor_copy_any_to_contig_f32(&tmp, &gv) != 0 then
            tensor_free(&tmp)
            tensor_free(&gv)
            return 1
        tensor_free(&gv)
        if tensor_add_inplace_f32(&(*a).grad, &tmp) != 0 then
            tensor_free(&tmp)
            return 1
        tensor_free(&tmp)
        return grad_tensor_backward_visit(a)

    return 1


def grad_tensor_backward(t is mut ref GradTensor) returns i32
    # v1: scalar outputs only (use grad_tensor_sum_all first).
    if tensor_numel(&(*t).data) != 1 then
        return 1
    if (*t).requires_grad == 0 then
        return 0
    if grad_tensor_alloc_grad(t) != 0 then
        return 1
    if tensor_fill_f32(&(*t).grad, 1.0) != 0 then
        return 1
    return grad_tensor_backward_visit(t)
