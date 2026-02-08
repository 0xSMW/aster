# aster_ml.buffer (v0)

use core.libc
use aster_ml.dtype
use aster_ml.device
use aster_ml.runtime.ops_metal

struct Buffer
    # `base` is the allocation handle for ownership tracking.
    # - CPU: base == (malloc pointer)
    # - METAL: base == (opaque MTLBuffer* handle)
    var base is MutString
    # `data` is the CPU-accessible pointer for the buffer start + byte_off.
    # - CPU: base + byte_off
    # - METAL: [MTLBuffer contents] + byte_off (shared storage)
    var data is MutString
    var bytes is usize
    var dtype is i32
    var device is i32
    var byte_off is usize

def buffer_init(b is mut ref Buffer, nbytes is usize, dtype is i32, device is i32) returns i32
    (*b).base = null
    (*b).data = null
    (*b).bytes = nbytes
    (*b).dtype = dtype
    (*b).device = device
    (*b).byte_off = 0

    if device == DEV_METAL then
        return metal_buf_alloc(nbytes, &(*b).base, &(*b).data)

    (*b).data = malloc(nbytes)
    if (*b).data is null then
        return 1
    (*b).base = (*b).data
    return 0


def buffer_free(b is mut ref Buffer) returns ()
    if (*b).base is not null then
        if (*b).device == DEV_METAL then
            # Views are non-owning: byte_off != 0.
            if (*b).byte_off == 0 then
                metal_buf_free((*b).base)
        else
            if (*b).byte_off == 0 then
                free((*b).base)
    (*b).base = null
    (*b).data = null
    (*b).bytes = 0
    (*b).dtype = DT_INVALID
    (*b).device = DEV_CPU
    (*b).byte_off = 0
    return


def buffer_view(out is mut ref Buffer, base is mut ref Buffer, byte_off is usize, nbytes is usize) returns i32
    if byte_off + nbytes > (*base).bytes then
        return 1
    (*out).base = (*base).base
    (*out).data = (*base).data + byte_off
    (*out).bytes = nbytes
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    (*out).byte_off = (*base).byte_off + byte_off
    return 0


def buffer_copy(dst is mut ref Buffer, src is mut ref Buffer) returns i32
    if (*dst).bytes != (*src).bytes then
        return 1
    memcpy((*dst).data, (*src).data, (*dst).bytes)
    return 0


def buffer_ptr_f32(b is mut ref Buffer) returns slice of f32
    return (*b).data


def buffer_ptr_f64(b is mut ref Buffer) returns slice of f64
    return (*b).data


def buffer_offset_bytes(b is mut ref Buffer) returns usize
    return (*b).byte_off
