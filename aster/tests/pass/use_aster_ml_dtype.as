# Expected: compile+run OK (dtype promotion lattice sanity)

use aster_ml.dtype
use core.io

def main() returns i32
    if dtype_promote(DT_U8, DT_U16) != DT_U16 then
        return 1
    if dtype_promote(DT_U8, DT_I8) != DT_I16 then
        return 1
    if dtype_promote(DT_I32, DT_U32) != DT_I64 then
        return 1
    if dtype_promote(DT_I64, DT_U64) != DT_U64 then
        return 1
    if dtype_promote(DT_F16, DT_I32) != DT_F16 then
        return 1
    if dtype_promote(DT_F32, DT_I16) != DT_F32 then
        return 1

    var s is String = dtype_safetensors_name(DT_F32)
    if s[0] != 70 or s[1] != 51 or s[2] != 50 or s[3] != 0 then # "F32"
        return 1
    if dtype_from_safetensors_name("F32") != DT_F32 then
        return 1
    if dtype_can_cast_lossless(DT_F32, DT_F64) == 0 then
        return 1
    if dtype_can_cast_lossless(DT_F64, DT_F32) != 0 then
        return 1
    println("ok")
    return 0
