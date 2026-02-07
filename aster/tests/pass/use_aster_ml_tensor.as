# Expected: compile+run OK (imports aster_ml and runs a tiny tensor op)

use aster_ml.tensor
use core.io

def main() returns i32
    var a is TensorF32
    var b is TensorF32
    var c is TensorF32

    if tensor_f32_init(&a, 2, 2, 3, 1) != 0 then
        return 1
    if tensor_f32_init(&b, 2, 2, 3, 1) != 0 then
        tensor_f32_free(&a)
        return 1
    if tensor_f32_init(&c, 2, 2, 3, 1) != 0 then
        tensor_f32_free(&a)
        tensor_f32_free(&b)
        return 1

    tensor_f32_fill(&a, 1.0)
    tensor_f32_fill(&b, 2.0)
    if tensor_f32_add(&c, &a, &b) != 0 then
        tensor_f32_free(&a)
        tensor_f32_free(&b)
        tensor_f32_free(&c)
        return 1

    var s is f32 = 0.0
    tensor_f32_sum1(&s, &c)
    if s < 17.0 or s > 19.0 then
        tensor_f32_free(&a)
        tensor_f32_free(&b)
        tensor_f32_free(&c)
        return 1

    tensor_f32_free(&a)
    tensor_f32_free(&b)
    tensor_f32_free(&c)
    println("ok")
    return 0

