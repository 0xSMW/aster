# aster_ml.gradient (v0)
#
# Minimal reverse-mode autograd over the tiny subset implemented in
# `aster_ml.tensor` (add/sum/matmul/permute3). This is a bootstrap layer to get
# golden-vector gradient parity online; it will be replaced by UOp-based rules.

use aster_ml.tensor


def tensor_backward_visit(t is mut ref Tensor) returns i32
    if (*t).node is null then
        return 0
    var n is mut ref GradNode = (*t).node

    if (*n).op == ML_NODE_ADD then
        var a is mut ref Tensor = (*n).a
        var b is mut ref Tensor = (*n).b
        if (*a).requires_grad != 0 then
            if tensor_alloc_grad(a) != 0 then
                return 1
            if tensor_f32_add_inplace(&(*a).grad, &(*t).grad) != 0 then
                return 1
            if tensor_backward_visit(a) != 0 then
                return 1
        if (*b).requires_grad != 0 then
            if tensor_alloc_grad(b) != 0 then
                return 1
            if tensor_f32_add_inplace(&(*b).grad, &(*t).grad) != 0 then
                return 1
            if tensor_backward_visit(b) != 0 then
                return 1
        return 0

    if (*n).op == ML_NODE_SUM then
        var a is mut ref Tensor = (*n).a
        if (*a).requires_grad == 0 then
            return 0
        if tensor_alloc_grad(a) != 0 then
            return 1
        # scalar grad broadcast
        var gp is slice of f32 = (*t).grad.data
        tensor_f32_add_scalar_inplace(&(*a).grad, gp[0])
        return tensor_backward_visit(a)

    if (*n).op == ML_NODE_MUL then
        var a is mut ref Tensor = (*n).a
        var b is mut ref Tensor = (*n).b

        if (*a).requires_grad != 0 then
            if tensor_alloc_grad(a) != 0 then
                return 1
        if (*b).requires_grad != 0 then
            if tensor_alloc_grad(b) != 0 then
                return 1

        var n_elems is usize = tensor_f32_numel(&(*t).grad)
        var gop is slice of f32 = (*t).grad.data
        var ap is slice of f32 = (*a).data.data
        var bp is slice of f32 = (*b).data.data
        if (*a).requires_grad != 0 then
            var agp is slice of f32 = (*a).grad.data
            var i is usize = 0
            while i < n_elems do
                agp[i] = agp[i] + gop[i] * bp[i]
                i = i + 1
        if (*b).requires_grad != 0 then
            var bgp is slice of f32 = (*b).grad.data
            var j is usize = 0
            while j < n_elems do
                bgp[j] = bgp[j] + gop[j] * ap[j]
                j = j + 1

        if (*a).requires_grad != 0 then
            if tensor_backward_visit(a) != 0 then
                return 1
        if (*b).requires_grad != 0 then
            if tensor_backward_visit(b) != 0 then
                return 1
        return 0

    if (*n).op == ML_NODE_RELU then
        var a is mut ref Tensor = (*n).a
        if (*a).requires_grad == 0 then
            return 0
        if tensor_alloc_grad(a) != 0 then
            return 1
        var n_elems is usize = tensor_f32_numel(&(*t).grad)
        var gop is slice of f32 = (*t).grad.data
        var ap is slice of f32 = (*a).data.data
        var agp is slice of f32 = (*a).grad.data
        var i is usize = 0
        while i < n_elems do
            if ap[i] > 0.0 then
                agp[i] = agp[i] + gop[i]
            i = i + 1
        return tensor_backward_visit(a)

    if (*n).op == ML_NODE_MATMUL then
        var a is mut ref Tensor = (*n).a
        var b is mut ref Tensor = (*n).b

        if (*a).requires_grad != 0 then
            if tensor_alloc_grad(a) != 0 then
                return 1
        if (*b).requires_grad != 0 then
            if tensor_alloc_grad(b) != 0 then
                return 1

        # grad_a += grad_out.matmul(b^T)
        if (*a).requires_grad != 0 then
            var bt is TensorF32
            if tensor_f32_init(&bt, 2, (*b).data.d1, (*b).data.d0, 1) != 0 then
                return 1
            if tensor_f32_transpose_2(&bt, &(*b).data) != 0 then
                tensor_f32_free(&bt)
                return 1
            var ga is TensorF32
            if tensor_f32_init(&ga, 2, (*a).data.d0, (*a).data.d1, 1) != 0 then
                tensor_f32_free(&bt)
                return 1
            if tensor_f32_matmul(&ga, &(*t).grad, &bt) != 0 then
                tensor_f32_free(&ga)
                tensor_f32_free(&bt)
                return 1
            if tensor_f32_add_inplace(&(*a).grad, &ga) != 0 then
                tensor_f32_free(&ga)
                tensor_f32_free(&bt)
                return 1
            tensor_f32_free(&ga)
            tensor_f32_free(&bt)

        # grad_b += a^T.matmul(grad_out)
        if (*b).requires_grad != 0 then
            var at is TensorF32
            if tensor_f32_init(&at, 2, (*a).data.d1, (*a).data.d0, 1) != 0 then
                return 1
            if tensor_f32_transpose_2(&at, &(*a).data) != 0 then
                tensor_f32_free(&at)
                return 1
            var gb is TensorF32
            if tensor_f32_init(&gb, 2, (*b).data.d0, (*b).data.d1, 1) != 0 then
                tensor_f32_free(&at)
                return 1
            if tensor_f32_matmul(&gb, &at, &(*t).grad) != 0 then
                tensor_f32_free(&gb)
                tensor_f32_free(&at)
                return 1
            if tensor_f32_add_inplace(&(*b).grad, &gb) != 0 then
                tensor_f32_free(&gb)
                tensor_f32_free(&at)
                return 1
            tensor_f32_free(&gb)
            tensor_f32_free(&at)

        if (*a).requires_grad != 0 then
            if tensor_backward_visit(a) != 0 then
                return 1
        if (*b).requires_grad != 0 then
            if tensor_backward_visit(b) != 0 then
                return 1
        return 0

    if (*n).op == ML_NODE_PERMUTE3 then
        var a is mut ref Tensor = (*n).a
        if (*a).requires_grad == 0 then
            return 0
        if tensor_alloc_grad(a) != 0 then
            return 1

        var ax0 is usize = (*n).ax0
        var ax1 is usize = (*n).ax1
        var ax2 is usize = (*n).ax2

        # inverse permutation
        var inv0 is usize = 0
        var inv1 is usize = 0
        var inv2 is usize = 0
        if ax0 == 0 then
            inv0 = 0
        else if ax1 == 0 then
            inv0 = 1
        else
            inv0 = 2
        if ax0 == 1 then
            inv1 = 0
        else if ax1 == 1 then
            inv1 = 1
        else
            inv1 = 2
        if ax0 == 2 then
            inv2 = 0
        else if ax1 == 2 then
            inv2 = 1
        else
            inv2 = 2

        var tmp is TensorF32
        if tensor_f32_init(&tmp, 3, (*a).data.d0, (*a).data.d1, (*a).data.d2) != 0 then
            return 1
        if tensor_f32_permute_3(&tmp, &(*t).grad, inv0, inv1, inv2) != 0 then
            tensor_f32_free(&tmp)
            return 1
        if tensor_f32_add_inplace(&(*a).grad, &tmp) != 0 then
            tensor_f32_free(&tmp)
            return 1
        tensor_f32_free(&tmp)
        return tensor_backward_visit(a)

    return 1


def tensor_backward(t is mut ref Tensor) returns i32
    # Only scalar outputs are supported in v0 (use `tensor_sum` first).
    if tensor_f32_numel(&(*t).data) != 1 then
        return 1
    if (*t).requires_grad == 0 then
        return 0
    if tensor_alloc_grad(t) != 0 then
        return 1
    tensor_f32_fill(&(*t).grad, 1.0)
    return tensor_backward_visit(t)
