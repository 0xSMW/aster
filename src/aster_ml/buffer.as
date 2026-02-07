# aster_ml.buffer (v0)

use core.libc
use aster_ml.dtype
use aster_ml.device

struct Buffer
    # `base` is the original allocation pointer for ownership tracking.
    # For views/sub-buffers, `base != data` and freeing the view is a no-op.
    var base is MutString
    var data is MutString
    var bytes is usize
    var dtype is i32
    var device is i32

def buffer_init(b is mut ref Buffer, nbytes is usize, dtype is i32, device is i32) returns i32
    (*b).data = malloc(nbytes)
    if (*b).data is null then
        return 1
    (*b).base = (*b).data
    (*b).bytes = nbytes
    (*b).dtype = dtype
    (*b).device = device
    return 0


def buffer_free(b is mut ref Buffer) returns ()
    if (*b).data is not null and (*b).base == (*b).data then
        free((*b).base)
    (*b).base = null
    (*b).data = null
    (*b).bytes = 0
    (*b).dtype = DT_INVALID
    (*b).device = DEV_CPU
    return


def buffer_view(out is mut ref Buffer, base is mut ref Buffer, byte_off is usize, nbytes is usize) returns i32
    if byte_off + nbytes > (*base).bytes then
        return 1
    (*out).base = (*base).base
    (*out).data = (*base).data + byte_off
    (*out).bytes = nbytes
    (*out).dtype = (*base).dtype
    (*out).device = (*base).device
    return 0


def buffer_copy(dst is mut ref Buffer, src is mut ref Buffer) returns i32
    if (*dst).bytes != (*src).bytes then
        return 1
    if (*dst).device != DEV_CPU or (*src).device != DEV_CPU then
        return 1
    memcpy((*dst).data, (*src).data, (*dst).bytes)
    return 0


def buffer_ptr_f32(b is mut ref Buffer) returns slice of f32
    return (*b).data


def buffer_ptr_f64(b is mut ref Buffer) returns slice of f64
    return (*b).data
