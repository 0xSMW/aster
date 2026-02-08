# Expected: compile+run OK (safetensors roundtrip, float32 CPU)

use aster_ml.nn.state
use core.io

def main() returns i32
    var sd is StateDict
    if state_dict_init(&sd) != 0 then
        return 1

    # Tensor a: 2x3 with values 1..6
    var a is TensorF32
    if tensor_f32_init(&a, 2, 2, 3, 1) != 0 then
        state_dict_free(&sd)
        return 1
    var ap is slice of f32 = a.data
    var i is usize = 0
    while i < 6 do
        ap[i] = 1.0 + i
        i = i + 1

    # Tensor b: 1D(4) with values 0.5, 1.5, 2.5, 3.5
    var b is TensorF32
    if tensor_f32_init(&b, 1, 4, 1, 1) != 0 then
        tensor_f32_free(&a)
        state_dict_free(&sd)
        return 1
    var bp is slice of f32 = b.data
    bp[0] = 0.5
    bp[1] = 1.5
    bp[2] = 2.5
    bp[3] = 3.5

    if state_dict_put_copy(&sd, "a", &a) != 0 then
        tensor_f32_free(&a)
        tensor_f32_free(&b)
        state_dict_free(&sd)
        return 1
    if state_dict_put_copy(&sd, "b", &b) != 0 then
        tensor_f32_free(&a)
        tensor_f32_free(&b)
        state_dict_free(&sd)
        return 1

    tensor_f32_free(&a)
    tensor_f32_free(&b)

    # Roundtrip through safetensors.
    var path is String = "/tmp/aster_state_roundtrip.safetensors"
    if safetensors_save_f32(path, &sd) != 0 then
        state_dict_free(&sd)
        return 1
    state_dict_free(&sd)

    var sd2 is StateDict
    if state_dict_init(&sd2) != 0 then
        return 1
    if safetensors_load_f32(path, &sd2) != 0 then
        state_dict_free(&sd2)
        return 1
    if state_dict_len(&sd2) != 2 then
        state_dict_free(&sd2)
        return 1

    var ta is MutString = state_dict_get(&sd2, "a")
    var tb is MutString = state_dict_get(&sd2, "b")
    if ta is null or tb is null then
        state_dict_free(&sd2)
        return 1

    var a2 is mut ref TensorF32 = ta
    if (*a2).ndim != 2 or (*a2).d0 != 2 or (*a2).d1 != 3 then
        state_dict_free(&sd2)
        return 1
    var ap2 is slice of f32 = (*a2).data
    var j is usize = 0
    while j < 6 do
        if ap2[j] != 1.0 + j then
            state_dict_free(&sd2)
            return 1
        j = j + 1

    var b2 is mut ref TensorF32 = tb
    if (*b2).ndim != 1 or (*b2).d0 != 4 then
        state_dict_free(&sd2)
        return 1
    var bp2 is slice of f32 = (*b2).data
    if bp2[0] != 0.5 or bp2[1] != 1.5 or bp2[2] != 2.5 or bp2[3] != 3.5 then
        state_dict_free(&sd2)
        return 1

    state_dict_free(&sd2)
    println("ok")
    return 0
