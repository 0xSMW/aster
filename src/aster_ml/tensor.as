# aster_ml.tensor (v1)
#
# Tensor descriptor + movement/shape semantics (tinygrad-inspired, minimal).
#
# Design notes:
# - Tensors are pure descriptors: (Buffer + byte offset + dtype/device + shape/strides).
# - Views are representable without copying by adjusting `byte_off` and `strides`.
# - This file intentionally avoids autograd/eager graphs; later phases can layer an
#   IR scheduler on top of this descriptor.

use core.libc
use aster_ml.buffer
use aster_ml.dtype
use aster_ml.device
use aster_ml.runtime.ops_metal


struct Tensor
    var buf is Buffer
    var byte_off is usize      # additional byte offset from `buf.data` to logical (0,...,0)
    var dtype is i32
    var device is i32
    var ndim is usize
    var shape is MutString     # `slice of usize` (len=ndim) or null if ndim==0
    var strides is MutString   # `slice of isize` (len=ndim, in elements) or null if ndim==0
    var owns is i32            # owns `buf` (0 for views / from_blob wrappers)


def ptr_add_bytes(p is MutString, off is isize) returns MutString
    if off >= 0 then
        var u is usize = off
        return p + u
    var u2 is usize = 0 - off
    return p - u2


def tensor_meta_alloc(t is mut ref Tensor, ndim is usize) returns i32
    (*t).ndim = ndim
    (*t).shape = null
    (*t).strides = null
    if ndim == 0 then
        return 0
    var sh is MutString = malloc(ndim * 8)
    if sh is null then
        return 1
    var st is MutString = malloc(ndim * 8)
    if st is null then
        free(sh)
        return 1
    (*t).shape = sh
    (*t).strides = st
    return 0


def tensor_meta_free(t is mut ref Tensor) returns ()
    if (*t).shape is not null then
        free((*t).shape)
    if (*t).strides is not null then
        free((*t).strides)
    (*t).shape = null
    (*t).strides = null
    (*t).ndim = 0
    return


def tensor_reset(t is mut ref Tensor) returns ()
    (*t).byte_off = 0
    (*t).dtype = DT_INVALID
    (*t).device = DEV_CPU
    (*t).ndim = 0
    (*t).shape = null
    (*t).strides = null
    (*t).owns = 0
    # Leave buffer in a safe null state.
    (*t).buf.base = null
    (*t).buf.data = null
    (*t).buf.bytes = 0
    (*t).buf.dtype = DT_INVALID
    (*t).buf.device = DEV_CPU
    (*t).buf.byte_off = 0
    return


def tensor_free(t is mut ref Tensor) returns ()
    tensor_meta_free(t)
    if (*t).owns != 0 then
        buffer_free(&(*t).buf)
    (*t).owns = 0
    (*t).byte_off = 0
    (*t).dtype = DT_INVALID
    (*t).device = DEV_CPU
    return


def tensor_itemsize(t is mut ref Tensor) returns usize
    return dtype_itemsize((*t).dtype)


def tensor_numel(t is mut ref Tensor) returns usize
    if (*t).ndim == 0 then
        return 1
    var sh is slice of usize = (*t).shape
    var n is usize = 1
    var i is usize = 0
    while i < (*t).ndim do
        n = n * sh[i]
        i = i + 1
    return n


def tensor_copy_meta(out is mut ref Tensor, base is mut ref Tensor) returns i32
    if tensor_meta_alloc(out, (*base).ndim) != 0 then
        return 1
    if (*base).ndim == 0 then
        return 0
    var osh is slice of usize = (*out).shape
    var ost is slice of isize = (*out).strides
    var bsh is slice of usize = (*base).shape
    var bst is slice of isize = (*base).strides
    var i is usize = 0
    while i < (*base).ndim do
        osh[i] = bsh[i]
        ost[i] = bst[i]
        i = i + 1
    return 0


def tensor_calc_contiguous_strides(ndim is usize, shape is slice of usize, out_strides is slice of isize) returns ()
    if ndim == 0 then
        return
    var stride is isize = 1
    var i is usize = ndim
    while i > 0 do
        i = i - 1
        out_strides[i] = stride
        var d is isize = shape[i]
        stride = stride * d
    return


def tensor_is_contiguous(t is mut ref Tensor) returns i32
    if (*t).ndim == 0 then
        return 1
    var sh is slice of usize = (*t).shape
    var st is slice of isize = (*t).strides
    var expect is isize = 1
    var i is usize = (*t).ndim
    while i > 0 do
        i = i - 1
        if sh[i] == 1 then
            continue
        if st[i] != expect then
            return 0
        var d is isize = sh[i]
        expect = expect * d
    return 1


def tensor_data_ptr(t is mut ref Tensor) returns MutString
    # Returns the pointer to logical element 0 (may be non-contiguous beyond that).
    if (*t).buf.data is null then
        return null
    return (*t).buf.data + (*t).byte_off


def tensor_elem_ptr(t is mut ref Tensor, idx is slice of usize) returns MutString
    var base is MutString = tensor_data_ptr(t)
    if base is null then
        return null
    if (*t).ndim == 0 then
        return base
    var st is slice of isize = (*t).strides
    var item is isize = tensor_itemsize(t)
    var off_elems is isize = 0
    var i is usize = 0
    while i < (*t).ndim do
        var ii is isize = idx[i]
        off_elems = off_elems + ii * st[i]
        i = i + 1
    var off_bytes is isize = off_elems * item
    return ptr_add_bytes(base, off_bytes)


def tensor_get_f32(t is mut ref Tensor, idx is slice of usize, out is mut ref f32) returns i32
    if (*t).dtype != DT_F32 then
        return 1
    if (*t).buf.data is null then
        return 1
    var p is MutString = tensor_elem_ptr(t, idx)
    if p is null then
        return 1
    var fp is slice of f32 = p
    *out = fp[0]
    return 0


def tensor_set_f32(t is mut ref Tensor, idx is slice of usize, v is f32) returns i32
    if (*t).dtype != DT_F32 then
        return 1
    if (*t).buf.data is null then
        return 1
    var p is MutString = tensor_elem_ptr(t, idx)
    if p is null then
        return 1
    var fp is slice of f32 = p
    fp[0] = v
    return 0


def tensor_item_f32(t is mut ref Tensor, out is mut ref f32) returns i32
    if (*t).dtype != DT_F32 then
        return 1
    if tensor_numel(t) != 1 then
        return 1
    var p is MutString = tensor_data_ptr(t)
    if p is null then
        return 1
    var fp is slice of f32 = p
    *out = fp[0]
    return 0


def tensor_fill_f32(t is mut ref Tensor, v is f32) returns i32
    if (*t).dtype != DT_F32 then
        return 1
    if (*t).buf.data is null then
        return 1
    if tensor_is_contiguous(t) == 0 then
        return 1
    var n is usize = tensor_numel(t)
    var p is slice of f32 = tensor_data_ptr(t)
    var i is usize = 0
    while i < n do
        p[i] = v
        i = i + 1
    return 0


def tensor_init_contiguous(out is mut ref Tensor, dtype is i32, device is i32, ndim is usize, dims is slice of usize) returns i32
    tensor_reset(out)
    (*out).dtype = dtype
    (*out).device = device
    (*out).byte_off = 0
    (*out).owns = 1
    if tensor_meta_alloc(out, ndim) != 0 then
        tensor_reset(out)
        return 1
    if ndim != 0 then
        var sh is slice of usize = (*out).shape
        var i is usize = 0
        while i < ndim do
            sh[i] = dims[i]
            i = i + 1
        var st is slice of isize = (*out).strides
        tensor_calc_contiguous_strides(ndim, sh, st)
    var nbytes is usize = tensor_numel(out) * dtype_itemsize(dtype)
    if buffer_init(&(*out).buf, nbytes, dtype, device) != 0 then
        tensor_free(out)
        tensor_reset(out)
        return 1
    return 0


def tensor_from_scalar_f32(out is mut ref Tensor, v is f32) returns i32
    tensor_reset(out)
    (*out).dtype = DT_F32
    (*out).device = DEV_CPU
    (*out).byte_off = 0
    (*out).owns = 1
    if tensor_meta_alloc(out, 0) != 0 then
        tensor_reset(out)
        return 1
    if buffer_init(&(*out).buf, 4, DT_F32, DEV_CPU) != 0 then
        tensor_free(out)
        tensor_reset(out)
        return 1
    var p is slice of f32 = (*out).buf.data
    p[0] = v
    return 0


def tensor_from_list_f32_1d(out is mut ref Tensor, xs is slice of f32, n is usize) returns i32
    var dims is slice of usize = malloc(1 * 8)
    if dims is null then
        return 1
    dims[0] = n
    if tensor_init_contiguous(out, DT_F32, DEV_CPU, 1, dims) != 0 then
        free(dims)
        return 1
    free(dims)
    var dst is slice of f32 = tensor_data_ptr(out)
    memcpy(dst, xs, n * 4)
    return 0


def tensor_from_list_f32(out is mut ref Tensor, xs is slice of f32, n is usize, ndim is usize, dims is slice of usize) returns i32
    # Create a contiguous tensor from a flat list, interpreted with `dims`.
    if ndim == 0 then
        if n != 1 then
            return 1
        return tensor_from_scalar_f32(out, xs[0])
    var want is usize = 1
    var i is usize = 0
    while i < ndim do
        want = want * dims[i]
        i = i + 1
    if want != n then
        return 1
    if tensor_init_contiguous(out, DT_F32, DEV_CPU, ndim, dims) != 0 then
        return 1
    var dst is slice of f32 = tensor_data_ptr(out)
    memcpy(dst, xs, n * 4)
    return 0


def tensor_from_blob_f32(out is mut ref Tensor, blob is MutString, nbytes is usize) returns i32
    # Wrap an existing memory region as a 1D f32 tensor (non-owning).
    if blob is null then
        return 1
    var rem is usize = nbytes - ((nbytes / 4) * 4)
    if rem != 0 then
        return 1
    tensor_reset(out)
    (*out).dtype = DT_F32
    (*out).device = DEV_CPU
    (*out).byte_off = 0
    (*out).owns = 0

    if tensor_meta_alloc(out, 1) != 0 then
        tensor_reset(out)
        return 1
    var sh is slice of usize = (*out).shape
    sh[0] = nbytes / 4
    var st is slice of isize = (*out).strides
    st[0] = 1

    # Buffer is a borrowed handle here: never free `blob`.
    (*out).buf.base = null
    (*out).buf.data = blob
    (*out).buf.bytes = nbytes
    (*out).buf.dtype = DT_F32
    (*out).buf.device = DEV_CPU
    (*out).buf.byte_off = 0
    return 0


def tensor_from_owned_blob_f32(out is mut ref Tensor, blob is MutString, nbytes is usize) returns i32
    # Wrap an existing malloc'd memory region as a 1D f32 tensor (owning).
    # The tensor will `free(blob)` when `tensor_free` is called.
    if blob is null then
        return 1
    var rem is usize = nbytes - ((nbytes / 4) * 4)
    if rem != 0 then
        return 1
    if nbytes == 0 then
        return 1

    tensor_reset(out)
    (*out).dtype = DT_F32
    (*out).device = DEV_CPU
    (*out).byte_off = 0
    (*out).owns = 1

    if tensor_meta_alloc(out, 1) != 0 then
        tensor_reset(out)
        return 1
    var sh is slice of usize = (*out).shape
    sh[0] = nbytes / 4
    var st is slice of isize = (*out).strides
    st[0] = 1

    (*out).buf.base = blob
    (*out).buf.data = blob
    (*out).buf.bytes = nbytes
    (*out).buf.dtype = DT_F32
    (*out).buf.device = DEV_CPU
    (*out).buf.byte_off = 0
    return 0


def tensor_reshape(out is mut ref Tensor, base is mut ref Tensor, ndim is usize, dims is slice of usize) returns i32
    if tensor_is_contiguous(base) == 0 then
        return 1
    var want is usize = 1
    var i is usize = 0
    while i < ndim do
        want = want * dims[i]
        i = i + 1
    if want != tensor_numel(base) then
        return 1

    tensor_reset(out)
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    (*out).owns = 0
    (*out).buf = (*base).buf
    (*out).byte_off = (*base).byte_off
    if tensor_meta_alloc(out, ndim) != 0 then
        tensor_reset(out)
        return 1
    if ndim != 0 then
        var sh is slice of usize = (*out).shape
        var j is usize = 0
        while j < ndim do
            sh[j] = dims[j]
            j = j + 1
        var st is slice of isize = (*out).strides
        tensor_calc_contiguous_strides(ndim, sh, st)
    return 0


def tensor_permute(out is mut ref Tensor, base is mut ref Tensor, perm is slice of usize) returns i32
    var n is usize = (*base).ndim
    # validate permutation (O(n^2), small n)
    var i is usize = 0
    while i < n do
        if perm[i] >= n then
            return 1
        var j is usize = i + 1
        while j < n do
            if perm[i] == perm[j] then
                return 1
            j = j + 1
        i = i + 1

    tensor_reset(out)
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    (*out).owns = 0
    (*out).buf = (*base).buf
    (*out).byte_off = (*base).byte_off
    if tensor_meta_alloc(out, n) != 0 then
        tensor_reset(out)
        return 1
    if n == 0 then
        return 0
    var bsh is slice of usize = (*base).shape
    var bst is slice of isize = (*base).strides
    var osh is slice of usize = (*out).shape
    var ost is slice of isize = (*out).strides
    var k is usize = 0
    while k < n do
        var ax is usize = perm[k]
        osh[k] = bsh[ax]
        ost[k] = bst[ax]
        k = k + 1
    return 0


def tensor_expand(out is mut ref Tensor, base is mut ref Tensor, ndim is usize, dims is slice of usize) returns i32
    # Broadcast/expand semantics: align from the right; size-1 dims can expand with stride 0.
    if ndim < (*base).ndim then
        return 1

    tensor_reset(out)
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    (*out).owns = 0
    (*out).buf = (*base).buf
    (*out).byte_off = (*base).byte_off
    if tensor_meta_alloc(out, ndim) != 0 then
        tensor_reset(out)
        return 1

    var osh is slice of usize = (*out).shape
    var ost is slice of isize = (*out).strides
    var bsh is slice of usize = (*base).shape
    var bst is slice of isize = (*base).strides

    var i is usize = 0
    while i < ndim do
        osh[i] = dims[i]
        ost[i] = 0
        i = i + 1

    var oi is usize = 0
    while oi < ndim do
        var out_ax is usize = (ndim - 1) - oi
        var out_dim is usize = osh[out_ax]

        var has_in is i32 = 1
        var in_ax is usize = 0
        if oi >= (*base).ndim then
            has_in = 0
        else
            in_ax = ((*base).ndim - 1) - oi

        if has_in == 0 then
            # implicit leading-1 dim: broadcasted
            ost[out_ax] = 0
        else
            var in_dim is usize = bsh[in_ax]
            var in_stride is isize = bst[in_ax]
            if in_dim == out_dim then
                ost[out_ax] = in_stride
            else if in_dim == 1 then
                ost[out_ax] = 0
            else
                tensor_meta_free(out)
                tensor_reset(out)
                return 1
        oi = oi + 1
    return 0


def tensor_slice(out is mut ref Tensor, base is mut ref Tensor, axis is usize, start is usize, end is usize) returns i32
    # Narrow slice: [start, end) along `axis`.
    if axis >= (*base).ndim then
        return 1
    if start > end then
        return 1
    var bsh is slice of usize = (*base).shape
    if end > bsh[axis] then
        return 1

    tensor_reset(out)
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    (*out).owns = 0
    (*out).buf = (*base).buf
    (*out).byte_off = (*base).byte_off
    if tensor_copy_meta(out, base) != 0 then
        tensor_reset(out)
        return 1

    var osh is slice of usize = (*out).shape
    osh[axis] = end - start

    var bst is slice of isize = (*base).strides
    var item is isize = tensor_itemsize(base)
    var delta_elems is isize = bst[axis] * (start)
    var delta_bytes is isize = delta_elems * item
    var boff is isize = (*base).byte_off
    var new_off is isize = boff + delta_bytes
    if new_off < 0 then
        tensor_free(out)
        tensor_reset(out)
        return 1
    (*out).byte_off = new_off
    return 0


def tensor_index(out is mut ref Tensor, base is mut ref Tensor, axis is usize, index is usize) returns i32
    # Select a single index along `axis` and drop that dimension.
    if axis >= (*base).ndim then
        return 1
    var bsh is slice of usize = (*base).shape
    if index >= bsh[axis] then
        return 1

    tensor_reset(out)
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    (*out).owns = 0
    (*out).buf = (*base).buf
    (*out).byte_off = (*base).byte_off

    var out_ndim is usize = 0
    if (*base).ndim > 0 then
        out_ndim = (*base).ndim - 1
    if tensor_meta_alloc(out, out_ndim) != 0 then
        tensor_reset(out)
        return 1

    if out_ndim != 0 then
        var osh is slice of usize = (*out).shape
        var ost is slice of isize = (*out).strides
        var bst is slice of isize = (*base).strides
        var i is usize = 0
        var j is usize = 0
        while i < (*base).ndim do
            if i != axis then
                osh[j] = bsh[i]
                ost[j] = bst[i]
                j = j + 1
            i = i + 1

    var bst2 is slice of isize = (*base).strides
    var item is isize = tensor_itemsize(base)
    var delta_elems is isize = bst2[axis] * (index)
    var delta_bytes is isize = delta_elems * item
    var boff is isize = (*base).byte_off
    var new_off is isize = boff + delta_bytes
    if new_off < 0 then
        tensor_free(out)
        tensor_reset(out)
        return 1
    (*out).byte_off = new_off
    return 0


def tensor_shrink(out is mut ref Tensor, base is mut ref Tensor, starts is slice of usize, ends is slice of usize) returns i32
    # Multi-axis slice: for each axis i, take [starts[i], ends[i]).
    var n is usize = (*base).ndim
    tensor_reset(out)
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    (*out).owns = 0
    (*out).buf = (*base).buf
    (*out).byte_off = (*base).byte_off
    if tensor_copy_meta(out, base) != 0 then
        tensor_reset(out)
        return 1
    if n == 0 then
        return 0

    var bsh is slice of usize = (*base).shape
    var bst is slice of isize = (*base).strides
    var osh is slice of usize = (*out).shape
    var item is isize = tensor_itemsize(base)
    var off is isize = (*base).byte_off

    var i is usize = 0
    while i < n do
        var s is usize = starts[i]
        var e is usize = ends[i]
        if s > e then
            tensor_free(out)
            tensor_reset(out)
            return 1
        if e > bsh[i] then
            tensor_free(out)
            tensor_reset(out)
            return 1
        osh[i] = e - s
        var delta_elems is isize = bst[i] * (s)
        off = off + delta_elems * item
        i = i + 1
    if off < 0 then
        tensor_free(out)
        tensor_reset(out)
        return 1
    (*out).byte_off = off
    return 0


def tensor_flip(out is mut ref Tensor, base is mut ref Tensor, axis is usize) returns i32
    if axis >= (*base).ndim then
        return 1
    tensor_reset(out)
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    (*out).owns = 0
    (*out).buf = (*base).buf
    (*out).byte_off = (*base).byte_off
    if tensor_copy_meta(out, base) != 0 then
        tensor_reset(out)
        return 1
    if (*base).ndim == 0 then
        return 0

    var sh is slice of usize = (*base).shape
    var bst is slice of isize = (*base).strides
    var ost is slice of isize = (*out).strides
    var item is isize = tensor_itemsize(base)

    var delta_elems is isize = (sh[axis] - 1) * bst[axis]
    var delta_bytes is isize = delta_elems * item
    var off is isize = (*base).byte_off + delta_bytes
    if off < 0 then
        tensor_free(out)
        tensor_reset(out)
        return 1
    (*out).byte_off = off
    ost[axis] = 0 - bst[axis]
    return 0


def tensor_tolist_f32(out_ptr is mut ref MutString, out_len is mut ref usize, t is mut ref Tensor) returns i32
    if (*t).dtype != DT_F32 then
        return 1
    var n is usize = tensor_numel(t)
    var p is MutString = malloc(n * 4)
    if p is null then
        return 1
    var out is slice of f32 = p

    if tensor_is_contiguous(t) != 0 then
        memcpy(out, tensor_data_ptr(t), n * 4)
        *out_ptr = p
        *out_len = n
        return 0

    if (*t).ndim == 0 then
        var v is f32 = 0.0
        if tensor_item_f32(t, &v) != 0 then
            free(p)
            return 1
        out[0] = v
        *out_ptr = p
        *out_len = 1
        return 0

    var idx is slice of usize = malloc((*t).ndim * 8)
    if idx is null then
        free(p)
        return 1
    var sh is slice of usize = (*t).shape
    var i is usize = 0
    while i < (*t).ndim do
        idx[i] = 0
        i = i + 1

    var k is usize = 0
    while k < n do
        var v is f32 = 0.0
        if tensor_get_f32(t, idx, &v) != 0 then
            free(idx)
            free(p)
            return 1
        out[k] = v

        # odometer increment
        var d is usize = (*t).ndim
        while d > 0 do
            d = d - 1
            idx[d] = idx[d] + 1
            if idx[d] < sh[d] then
                break
            idx[d] = 0
        k = k + 1

    free(idx)
    *out_ptr = p
    *out_len = n
    return 0


def tensor_sum_all_f32(out is mut ref Tensor, t is mut ref Tensor) returns i32
    if (*t).dtype != DT_F32 then
        return 1
    if tensor_from_scalar_f32(out, 0.0) != 0 then
        return 1
    var acc is f32 = 0.0
    var n is usize = tensor_numel(t)

    if tensor_is_contiguous(t) != 0 then
        var p is slice of f32 = tensor_data_ptr(t)
        var i is usize = 0
        while i < n do
            acc = acc + p[i]
            i = i + 1
    else if (*t).ndim == 0 then
        if tensor_item_f32(t, &acc) != 0 then
            tensor_free(out)
            return 1
    else
        var idx is slice of usize = malloc((*t).ndim * 8)
        if idx is null then
            tensor_free(out)
            return 1
        var sh is slice of usize = (*t).shape
        var j is usize = 0
        while j < (*t).ndim do
            idx[j] = 0
            j = j + 1
        var k is usize = 0
        while k < n do
            var v is f32 = 0.0
            if tensor_get_f32(t, idx, &v) != 0 then
                free(idx)
                tensor_free(out)
                return 1
            acc = acc + v
            var d is usize = (*t).ndim
            while d > 0 do
                d = d - 1
                idx[d] = idx[d] + 1
                if idx[d] < sh[d] then
                    break
                idx[d] = 0
            k = k + 1
        free(idx)

    var op is slice of f32 = tensor_data_ptr(out)
    op[0] = acc
    return 0


def tensor_sum_axis_f32(out is mut ref Tensor, t is mut ref Tensor, axis is usize, keepdim is i32) returns i32
    if (*t).dtype != DT_F32 then
        return 1
    if axis >= (*t).ndim then
        return 1

    var tnd is usize = (*t).ndim
    var tsh is slice of usize = (*t).shape

    var out_nd is usize = 0
    if keepdim != 0 then
        out_nd = tnd
    else
        out_nd = tnd - 1

    var dims is slice of usize = null
    if out_nd != 0 then
        dims = malloc(out_nd * 8)
        if dims is null then
            return 1
        var i is usize = 0
        var j is usize = 0
        while i < tnd do
            if keepdim != 0 then
                if i == axis then
                    dims[i] = 1
                else
                    dims[i] = tsh[i]
                i = i + 1
            else
                if i != axis then
                    dims[j] = tsh[i]
                    j = j + 1
                i = i + 1
    if tensor_init_contiguous(out, DT_F32, (*t).device, out_nd, dims) != 0 then
        if dims is not null then
            free(dims)
        return 1
    if dims is not null then
        free(dims)

    if tensor_fill_f32(out, 0.0) != 0 then
        tensor_free(out)
        return 1

    var n is usize = tensor_numel(t)
    if n == 0 then
        return 0

    if (*t).ndim == 0 then
        # scalar reduced over axis is invalid (axis>=ndim handled above)
        return 1

    var idx is slice of usize = malloc(tnd * 8)
    if idx is null then
        tensor_free(out)
        return 1
    var i0 is usize = 0
    while i0 < tnd do
        idx[i0] = 0
        i0 = i0 + 1

    var out_idx is slice of usize = null
    if out_nd != 0 then
        out_idx = malloc(out_nd * 8)
        if out_idx is null then
            free(idx)
            tensor_free(out)
            return 1

    var k is usize = 0
    while k < n do
        var v is f32 = 0.0
        if tensor_get_f32(t, idx, &v) != 0 then
            if out_idx is not null then
                free(out_idx)
            free(idx)
            tensor_free(out)
            return 1

        if keepdim != 0 then
            var oi is usize = 0
            while oi < out_nd do
                if oi == axis then
                    out_idx[oi] = 0
                else
                    out_idx[oi] = idx[oi]
                oi = oi + 1
        else
            var ti is usize = 0
            var oj is usize = 0
            while ti < tnd do
                if ti != axis then
                    out_idx[oj] = idx[ti]
                    oj = oj + 1
                ti = ti + 1

        var p is MutString = tensor_elem_ptr(out, out_idx)
        var fp is slice of f32 = p
        fp[0] = fp[0] + v

        # increment input idx
        var d is usize = tnd
        while d > 0 do
            d = d - 1
            idx[d] = idx[d] + 1
            if idx[d] < tsh[d] then
                break
            idx[d] = 0
        k = k + 1

    if out_idx is not null then
        free(out_idx)
    free(idx)
    return 0


def tensor_sum_axes_f32(out is mut ref Tensor, t is mut ref Tensor, axes is slice of usize, naxes is usize, keepdim is i32) returns i32
    # Reduce multiple axes by repeated single-axis reduction.
    if naxes == 0 then
        # no-op: view/copy meta only
        tensor_reset(out)
        (*out).dtype = (*t).dtype
        (*out).device = (*t).device
        (*out).owns = 0
        (*out).buf = (*t).buf
        (*out).byte_off = (*t).byte_off
        if tensor_copy_meta(out, t) != 0 then
            tensor_reset(out)
            return 1
        return 0

    # Copy axes into a temp array we can sort (small n).
    var ax is slice of usize = malloc(naxes * 8)
    if ax is null then
        return 1
    var i is usize = 0
    while i < naxes do
        ax[i] = axes[i]
        i = i + 1

    # If keepdim==0, reduce in descending axis order to keep axis indices stable.
    var swapped is i32 = 1
    while swapped != 0 do
        swapped = 0
        var j is usize = 0
        while (j + 1) < naxes do
            var a0 is usize = ax[j]
            var a1 is usize = ax[j + 1]
            var want_swap is i32 = 0
            if keepdim == 0 then
                if a0 < a1 then
                    want_swap = 1
            else
                if a0 > a1 then
                    want_swap = 1
            if want_swap != 0 then
                ax[j] = a1
                ax[j + 1] = a0
                swapped = 1
            j = j + 1

    var cur is Tensor
    tensor_reset(&cur)
    # Start with a view to the input.
    cur.dtype = (*t).dtype
    cur.device = (*t).device
    cur.owns = 0
    cur.buf = (*t).buf
    cur.byte_off = (*t).byte_off
    if tensor_copy_meta(&cur, t) != 0 then
        free(ax)
        return 1

    var tmp is Tensor
    tensor_reset(&tmp)
    var k is usize = 0
    while k < naxes do
        var axis is usize = ax[k]
        if tensor_sum_axis_f32(&tmp, &cur, axis, keepdim) != 0 then
            tensor_free(&tmp)
            tensor_free(&cur)
            free(ax)
            return 1
        tensor_free(&cur)
        cur = tmp
        tensor_reset(&tmp)
        k = k + 1

    free(ax)
    *out = cur
    return 0


def tensor_pad_f32(out is mut ref Tensor, t is mut ref Tensor, pads is slice of usize) returns i32
    # pads is len=2*ndim: [before0, after0, before1, after1, ...]
    if (*t).dtype != DT_F32 then
        return 1
    var n is usize = (*t).ndim
    if n == 0 then
        # scalar pad is undefined in this minimal impl
        return 1

    var tsh is slice of usize = (*t).shape
    var dims is slice of usize = malloc(n * 8)
    if dims is null then
        return 1
    var i is usize = 0
    while i < n do
        dims[i] = tsh[i] + pads[2 * i] + pads[2 * i + 1]
        i = i + 1
    if tensor_init_contiguous(out, DT_F32, (*t).device, n, dims) != 0 then
        free(dims)
        return 1
    free(dims)

    if tensor_fill_f32(out, 0.0) != 0 then
        tensor_free(out)
        return 1

    var n_in is usize = tensor_numel(t)
    var idx is slice of usize = malloc(n * 8)
    if idx is null then
        tensor_free(out)
        return 1
    var oidx is slice of usize = malloc(n * 8)
    if oidx is null then
        free(idx)
        tensor_free(out)
        return 1
    var j is usize = 0
    while j < n do
        idx[j] = 0
        oidx[j] = 0
        j = j + 1

    var k is usize = 0
    while k < n_in do
        # map idx -> oidx with pad offset
        var d is usize = 0
        while d < n do
            oidx[d] = idx[d] + pads[2 * d]
            d = d + 1
        var v is f32 = 0.0
        if tensor_get_f32(t, idx, &v) != 0 then
            free(oidx)
            free(idx)
            tensor_free(out)
            return 1
        if tensor_set_f32(out, oidx, v) != 0 then
            free(oidx)
            free(idx)
            tensor_free(out)
            return 1

        # increment idx
        var dd is usize = n
        while dd > 0 do
            dd = dd - 1
            idx[dd] = idx[dd] + 1
            if idx[dd] < tsh[dd] then
                break
            idx[dd] = 0
        k = k + 1

    free(oidx)
    free(idx)
    return 0


# -----------------------------
# Math ops (v1 subset; float32 only)
# -----------------------------

def tensor_total_byte_off(t is mut ref Tensor) returns usize
    # Total byte offset from the underlying allocation base.
    return buffer_offset_bytes(&(*t).buf) + (*t).byte_off


def tensor_add_f32(out is mut ref Tensor, a is mut ref Tensor, b is mut ref Tensor) returns i32
    if (*a).dtype != DT_F32 or (*b).dtype != DT_F32 then
        return 1
    if (*a).device != (*b).device then
        return 1

    var out_ndim is usize = (*a).ndim
    if (*b).ndim > out_ndim then
        out_ndim = (*b).ndim

    # compute broadcasted output shape
    var out_dims is slice of usize = null
    if out_ndim != 0 then
        out_dims = malloc(out_ndim * 8)
        if out_dims is null then
            return 1
    var i is usize = 0
    while i < out_ndim do
        var oi is usize = (out_ndim - 1) - i
        var ad is usize = 1
        var bd is usize = 1
        if i < (*a).ndim then
            var ai is usize = ((*a).ndim - 1) - i
            var ash is slice of usize = (*a).shape
            ad = ash[ai]
        if i < (*b).ndim then
            var bi is usize = ((*b).ndim - 1) - i
            var bsh is slice of usize = (*b).shape
            bd = bsh[bi]
        var od is usize = 0
        if ad == bd then
            od = ad
        else if ad == 1 then
            od = bd
        else if bd == 1 then
            od = ad
        else
            if out_dims is not null then
                free(out_dims)
            return 1
        if out_dims is not null then
            out_dims[oi] = od
        i = i + 1

    # broadcast views
    var av is Tensor
    var bv is Tensor
    if tensor_expand(&av, a, out_ndim, out_dims) != 0 then
        if out_dims is not null then
            free(out_dims)
        return 1
    if tensor_expand(&bv, b, out_ndim, out_dims) != 0 then
        tensor_free(&av)
        if out_dims is not null then
            free(out_dims)
        return 1

    # allocate out
    if tensor_init_contiguous(out, DT_F32, (*a).device, out_ndim, out_dims) != 0 then
        tensor_free(&bv)
        tensor_free(&av)
        if out_dims is not null then
            free(out_dims)
        return 1
    if out_dims is not null then
        free(out_dims)

    var n is usize = tensor_numel(out)
    if n == 0 then
        tensor_free(&bv)
        tensor_free(&av)
        return 0

    # fast path: all contiguous
    if tensor_is_contiguous(&av) != 0 and tensor_is_contiguous(&bv) != 0 then
        var op is slice of f32 = tensor_data_ptr(out)
        var ap is slice of f32 = tensor_data_ptr(&av)
        var bp is slice of f32 = tensor_data_ptr(&bv)
        var j is usize = 0
        while j < n do
            op[j] = ap[j] + bp[j]
            j = j + 1
        tensor_free(&bv)
        tensor_free(&av)
        return 0

    # generic indexed path
    var idx is slice of usize = null
    if out_ndim != 0 then
        idx = malloc(out_ndim * 8)
        if idx is null then
            tensor_free(out)
            tensor_free(&bv)
            tensor_free(&av)
            return 1
        var z is usize = 0
        while z < out_ndim do
            idx[z] = 0
            z = z + 1

    var osh is slice of usize = (*out).shape
    var k is usize = 0
    while k < n do
        var optr is MutString = tensor_elem_ptr(out, idx)
        var aptr is MutString = tensor_elem_ptr(&av, idx)
        var bptr is MutString = tensor_elem_ptr(&bv, idx)
        var outp is slice of f32 = optr
        var af is slice of f32 = aptr
        var bf is slice of f32 = bptr
        outp[0] = af[0] + bf[0]

        # increment idx
        var d is usize = out_ndim
        while d > 0 do
            d = d - 1
            idx[d] = idx[d] + 1
            if idx[d] < osh[d] then
                break
            idx[d] = 0
        k = k + 1

    if idx is not null then
        free(idx)
    tensor_free(&bv)
    tensor_free(&av)
    return 0


def tensor_mul_f32(out is mut ref Tensor, a is mut ref Tensor, b is mut ref Tensor) returns i32
    if (*a).dtype != DT_F32 or (*b).dtype != DT_F32 then
        return 1
    if (*a).device != (*b).device then
        return 1

    var out_ndim is usize = (*a).ndim
    if (*b).ndim > out_ndim then
        out_ndim = (*b).ndim

    var out_dims is slice of usize = null
    if out_ndim != 0 then
        out_dims = malloc(out_ndim * 8)
        if out_dims is null then
            return 1
    var i is usize = 0
    while i < out_ndim do
        var oi is usize = (out_ndim - 1) - i
        var ad is usize = 1
        var bd is usize = 1
        if i < (*a).ndim then
            var ai is usize = ((*a).ndim - 1) - i
            var ash is slice of usize = (*a).shape
            ad = ash[ai]
        if i < (*b).ndim then
            var bi is usize = ((*b).ndim - 1) - i
            var bsh is slice of usize = (*b).shape
            bd = bsh[bi]
        var od is usize = 0
        if ad == bd then
            od = ad
        else if ad == 1 then
            od = bd
        else if bd == 1 then
            od = ad
        else
            if out_dims is not null then
                free(out_dims)
            return 1
        if out_dims is not null then
            out_dims[oi] = od
        i = i + 1

    var av is Tensor
    var bv is Tensor
    if tensor_expand(&av, a, out_ndim, out_dims) != 0 then
        if out_dims is not null then
            free(out_dims)
        return 1
    if tensor_expand(&bv, b, out_ndim, out_dims) != 0 then
        tensor_free(&av)
        if out_dims is not null then
            free(out_dims)
        return 1

    if tensor_init_contiguous(out, DT_F32, (*a).device, out_ndim, out_dims) != 0 then
        tensor_free(&bv)
        tensor_free(&av)
        if out_dims is not null then
            free(out_dims)
        return 1
    if out_dims is not null then
        free(out_dims)

    var n is usize = tensor_numel(out)
    if n == 0 then
        tensor_free(&bv)
        tensor_free(&av)
        return 0

    if tensor_is_contiguous(&av) != 0 and tensor_is_contiguous(&bv) != 0 then
        var op is slice of f32 = tensor_data_ptr(out)
        var ap is slice of f32 = tensor_data_ptr(&av)
        var bp is slice of f32 = tensor_data_ptr(&bv)
        var j is usize = 0
        while j < n do
            op[j] = ap[j] * bp[j]
            j = j + 1
        tensor_free(&bv)
        tensor_free(&av)
        return 0

    var idx is slice of usize = null
    if out_ndim != 0 then
        idx = malloc(out_ndim * 8)
        if idx is null then
            tensor_free(out)
            tensor_free(&bv)
            tensor_free(&av)
            return 1
        var z is usize = 0
        while z < out_ndim do
            idx[z] = 0
            z = z + 1

    var osh is slice of usize = (*out).shape
    var k is usize = 0
    while k < n do
        var optr is MutString = tensor_elem_ptr(out, idx)
        var aptr is MutString = tensor_elem_ptr(&av, idx)
        var bptr is MutString = tensor_elem_ptr(&bv, idx)
        var outp is slice of f32 = optr
        var af is slice of f32 = aptr
        var bf is slice of f32 = bptr
        outp[0] = af[0] * bf[0]

        var d is usize = out_ndim
        while d > 0 do
            d = d - 1
            idx[d] = idx[d] + 1
            if idx[d] < osh[d] then
                break
            idx[d] = 0
        k = k + 1

    if idx is not null then
        free(idx)
    tensor_free(&bv)
    tensor_free(&av)
    return 0


def tensor_relu_f32(out is mut ref Tensor, a is mut ref Tensor) returns i32
    if (*a).dtype != DT_F32 then
        return 1
    if tensor_init_contiguous(out, DT_F32, (*a).device, (*a).ndim, (*a).shape) != 0 then
        return 1
    var n is usize = tensor_numel(a)
    if n == 0 then
        return 0
    if tensor_is_contiguous(a) != 0 then
        var ap is slice of f32 = tensor_data_ptr(a)
        var op is slice of f32 = tensor_data_ptr(out)
        var i is usize = 0
        while i < n do
            var x is f32 = ap[i]
            if x < 0.0 then
                x = 0.0
            op[i] = x
            i = i + 1
        return 0

    # generic index path
    var idx is slice of usize = null
    if (*a).ndim != 0 then
        idx = malloc((*a).ndim * 8)
        if idx is null then
            tensor_free(out)
            return 1
        var z is usize = 0
        while z < (*a).ndim do
            idx[z] = 0
            z = z + 1

    var sh is slice of usize = (*a).shape
    var k is usize = 0
    while k < n do
        var aptr is MutString = tensor_elem_ptr(a, idx)
        var optr is MutString = tensor_elem_ptr(out, idx)
        var af is slice of f32 = aptr
        var outp is slice of f32 = optr
        var x is f32 = af[0]
        if x < 0.0 then
            x = 0.0
        outp[0] = x

        var d is usize = (*a).ndim
        while d > 0 do
            d = d - 1
            idx[d] = idx[d] + 1
            if idx[d] < sh[d] then
                break
            idx[d] = 0
        k = k + 1

    if idx is not null then
        free(idx)
    return 0


def tensor_matmul_f32(out is mut ref Tensor, a is mut ref Tensor, b is mut ref Tensor) returns i32
    # a: (m,k), b: (k,n), out: (m,n)
    if (*a).dtype != DT_F32 or (*b).dtype != DT_F32 then
        return 1
    if (*a).device != (*b).device then
        return 1
    if (*a).ndim != 2 or (*b).ndim != 2 then
        return 1
    var ash is slice of usize = (*a).shape
    var bsh is slice of usize = (*b).shape
    var m is usize = ash[0]
    var k is usize = ash[1]
    if bsh[0] != k then
        return 1
    var n is usize = bsh[1]

    var dims is slice of usize = malloc(2 * 8)
    if dims is null then
        return 1
    dims[0] = m
    dims[1] = n
    if tensor_init_contiguous(out, DT_F32, (*a).device, 2, dims) != 0 then
        free(dims)
        return 1
    free(dims)

    # Metal fast path (contiguous row-major only).
    if (*a).device == DEV_METAL then
        if tensor_is_contiguous(a) == 0 or tensor_is_contiguous(b) == 0 then
            tensor_free(out)
            return 1
        if tensor_is_contiguous(out) == 0 then
            tensor_free(out)
            return 1
        # Call metal kernel via buffer bases + byte offsets.
        if metal_matmul_f32((*out).buf.base, tensor_total_byte_off(out), (*a).buf.base, tensor_total_byte_off(a), (*b).buf.base, tensor_total_byte_off(b), m, k, n) != 0 then
            tensor_free(out)
            return 1
        return 0

    # CPU: require contiguous for now.
    if tensor_is_contiguous(a) == 0 or tensor_is_contiguous(b) == 0 then
        tensor_free(out)
        return 1
    var ap is slice of f32 = tensor_data_ptr(a)
    var bp is slice of f32 = tensor_data_ptr(b)
    var op is slice of f32 = tensor_data_ptr(out)
    var i is usize = 0
    while i < m do
        var j is usize = 0
        while j < n do
            var acc is f32 = 0.0
            var p is usize = 0
            while p < k do
                acc = acc + ap[i * k + p] * bp[p * n + j]
                p = p + 1
            op[i * n + j] = acc
            j = j + 1
        i = i + 1
    return 0
