# Expected: compile+run OK (GGUF minimal subset loader: Q8_0 -> f32)

use aster_ml.nn.state
use core.io

def try_load(path is String, out is mut ref StateDict) returns i32
    # Caller must provide an initialized StateDict.
    if gguf_load_f32(path, out) == 0 then
        return 0
    return 1


def main() returns i32
    var sd is StateDict
    if state_dict_init(&sd) != 0 then
        return 1

    # Try a few relative paths so this test is resilient to the runner's cwd.
    var ok is i32 = 0
    if try_load("aster/tests/fixtures/minimal_q8_0.gguf", &sd) == 0 then
        ok = 1
    if ok == 0 then
        state_dict_free(&sd)
        if state_dict_init(&sd) != 0 then
            return 1
        if try_load("tests/fixtures/minimal_q8_0.gguf", &sd) == 0 then
            ok = 1
    if ok == 0 then
        state_dict_free(&sd)
        if state_dict_init(&sd) != 0 then
            return 1
        if try_load("../aster/tests/fixtures/minimal_q8_0.gguf", &sd) == 0 then
            ok = 1
    if ok == 0 then
        state_dict_free(&sd)
        if state_dict_init(&sd) != 0 then
            return 1
        if try_load("./fixtures/minimal_q8_0.gguf", &sd) == 0 then
            ok = 1
    if ok == 0 then
        state_dict_free(&sd)
        return 1

    var tp is MutString = state_dict_get(&sd, "w")
    if tp is null then
        state_dict_free(&sd)
        return 1
    var t is mut ref TensorF32 = tp
    if (*t).ndim != 1 or (*t).d0 != 32 then
        state_dict_free(&sd)
        return 1

    var p is slice of f32 = (*t).data
    # Fixture encodes q = [-16..15] with scale 1.0, so output is exactly [-16..15].
    var i is i32 = 0
    while i < 32 do
        var want is f32 = (0.0 + i) - 16.0
        if p[i] != want then
            state_dict_free(&sd)
            return 1
        i = i + 1

    state_dict_free(&sd)
    println("ok")
    return 0
