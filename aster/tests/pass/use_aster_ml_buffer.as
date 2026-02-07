# Expected: compile+run OK (buffer views + copy)

use aster_ml.buffer
use aster_ml.dtype
use aster_ml.device
use core.io

def main() returns i32
    var b is Buffer
    if buffer_init(&b, 16, DT_F32, DEV_CPU) != 0 then
        return 1

    var p is slice of f32 = buffer_ptr_f32(&b)
    p[0] = 1.0
    p[1] = 2.0
    p[2] = 3.0
    p[3] = 4.0

    var v is Buffer
    if buffer_view(&v, &b, 4, 12) != 0 then
        buffer_free(&b)
        return 1
    var vp is slice of f32 = buffer_ptr_f32(&v)
    if vp[0] < 1.99 or vp[0] > 2.01 then
        return 1
    if vp[1] < 2.99 or vp[1] > 3.01 then
        return 1
    if vp[2] < 3.99 or vp[2] > 4.01 then
        return 1

    var c is Buffer
    if buffer_init(&c, 12, DT_F32, DEV_CPU) != 0 then
        buffer_free(&v)
        buffer_free(&b)
        return 1
    if buffer_copy(&c, &v) != 0 then
        buffer_free(&c)
        buffer_free(&v)
        buffer_free(&b)
        return 1
    var cp is slice of f32 = buffer_ptr_f32(&c)
    if cp[0] < 1.99 or cp[0] > 2.01 then
        return 1
    if cp[1] < 2.99 or cp[1] > 3.01 then
        return 1
    if cp[2] < 3.99 or cp[2] > 4.01 then
        return 1

    buffer_free(&c)
    buffer_free(&v)
    buffer_free(&b)
    println("ok")
    return 0
