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
    println("ok")
    return 0
