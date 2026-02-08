# aster_ml.device (v0)

use core.libc

const DEV_CPU is i32 = 0
const DEV_METAL is i32 = 1
const DEV_INVALID is i32 = 2

def device_default() returns i32
    var s is String = getenv("ASTER_ML_DEVICE")
    return device_parse_or_default(s)


def device_is_valid(dev is i32) returns i32
    return (dev == DEV_CPU or dev == DEV_METAL)


def device_name(dev is i32) returns String
    if dev == DEV_CPU then
        return "cpu"
    if dev == DEV_METAL then
        return "metal"
    return "invalid"


def device_parse(s is String) returns i32
    if s is null then
        return DEV_INVALID
    # accept "cpu" or "metal" (case-sensitive for now)
    if s[0] == 99 and s[1] == 112 and s[2] == 117 and s[3] == 0 then
        return DEV_CPU
    if s[0] == 109 and s[1] == 101 and s[2] == 116 and s[3] == 97 and s[4] == 108 and s[5] == 0 then
        return DEV_METAL
    return DEV_INVALID


def device_parse_or_default(s is String) returns i32
    var d is i32 = device_parse(s)
    if d == DEV_INVALID then
        return DEV_CPU
    return d
