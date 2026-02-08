# Expected: compile+run OK (Metal buffer + kernels)

use aster_ml.buffer
use aster_ml.device
use aster_ml.dtype
use aster_ml.runtime.ops_metal
use core.io

def main() returns i32
    var a is Buffer
    var b is Buffer
    var out is Buffer

    if buffer_init(&a, 16, DT_F32, DEV_METAL) != 0 then
        return 1
    if buffer_init(&b, 16, DT_F32, DEV_METAL) != 0 then
        buffer_free(&a)
        return 1
    if buffer_init(&out, 16, DT_F32, DEV_METAL) != 0 then
        buffer_free(&b)
        buffer_free(&a)
        return 1

    var ap is slice of f32 = buffer_ptr_f32(&a)
    var bp is slice of f32 = buffer_ptr_f32(&b)
    ap[0] = 1.0
    ap[1] = 2.0
    ap[2] = 3.0
    ap[3] = 4.0
    bp[0] = 10.0
    bp[1] = 20.0
    bp[2] = 30.0
    bp[3] = 40.0

    if metal_add_f32(out.base, buffer_offset_bytes(&out), a.base, buffer_offset_bytes(&a), b.base, buffer_offset_bytes(&b), 4) != 0 then
        buffer_free(&out)
        buffer_free(&b)
        buffer_free(&a)
        return 1

    var op is slice of f32 = buffer_ptr_f32(&out)
    if op[0] < 10.99 or op[0] > 11.01 then
        return 1
    if op[1] < 21.99 or op[1] > 22.01 then
        return 1
    if op[2] < 32.99 or op[2] > 33.01 then
        return 1
    if op[3] < 43.99 or op[3] > 44.01 then
        return 1

    buffer_free(&out)
    buffer_free(&b)
    buffer_free(&a)

    # Smoke-test repeated alloc/free (should not crash).
    var i is usize = 0
    while i < 256 do
        var t is Buffer
        if buffer_init(&t, 64, DT_F32, DEV_METAL) != 0 then
            return 1
        buffer_free(&t)
        i = i + 1
    println("ok")
    return 0
