# aster_ml.device (v0)

use core.libc

const DEV_CPU is i32 = 0
const DEV_METAL is i32 = 1

def device_default() returns i32
    var s is String = getenv("ASTER_ML_DEVICE")
    if s is null then
        return DEV_CPU
    # accept "cpu" or "metal" (case-sensitive for now)
    if s[0] == 99 and s[1] == 112 and s[2] == 117 and s[3] == 0 then
        return DEV_CPU
    if s[0] == 109 and s[1] == 101 and s[2] == 116 and s[3] == 97 and s[4] == 108 and s[5] == 0 then
        return DEV_METAL
    return DEV_CPU

