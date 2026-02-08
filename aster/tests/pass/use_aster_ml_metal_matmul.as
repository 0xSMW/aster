# Expected: compile+run OK (Metal matmul_f32)

use aster_ml.buffer
use aster_ml.device
use aster_ml.dtype
use aster_ml.runtime.ops_metal
use core.io

def main() returns i32
    # A: (m,k), B: (k,n), C: (m,n)
    var m is usize = 2
    var k is usize = 3
    var n is usize = 2

    var a is Buffer
    var b is Buffer
    var out is Buffer

    if buffer_init(&a, m * k * 4, DT_F32, DEV_METAL) != 0 then
        return 1
    if buffer_init(&b, k * n * 4, DT_F32, DEV_METAL) != 0 then
        buffer_free(&a)
        return 1
    if buffer_init(&out, m * n * 4, DT_F32, DEV_METAL) != 0 then
        buffer_free(&b)
        buffer_free(&a)
        return 1

    var ap is slice of f32 = buffer_ptr_f32(&a)
    var bp is slice of f32 = buffer_ptr_f32(&b)
    ap[0] = 1.0
    ap[1] = 2.0
    ap[2] = 3.0
    ap[3] = 4.0
    ap[4] = 5.0
    ap[5] = 6.0
    bp[0] = 7.0
    bp[1] = 8.0
    bp[2] = 9.0
    bp[3] = 10.0
    bp[4] = 11.0
    bp[5] = 12.0

    if metal_matmul_f32(out.base, buffer_offset_bytes(&out), a.base, buffer_offset_bytes(&a), b.base, buffer_offset_bytes(&b), m, k, n) != 0 then
        buffer_free(&out)
        buffer_free(&b)
        buffer_free(&a)
        return 1

    # Expected:
    # [58, 64]
    # [139, 154]
    var op is slice of f32 = buffer_ptr_f32(&out)
    if op[0] < 57.99 or op[0] > 58.01 then
        return 1
    if op[1] < 63.99 or op[1] > 64.01 then
        return 1
    if op[2] < 138.99 or op[2] > 139.01 then
        return 1
    if op[3] < 153.99 or op[3] > 154.01 then
        return 1

    buffer_free(&out)
    buffer_free(&b)
    buffer_free(&a)
    println("ok")
    return 0

