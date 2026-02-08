# Conformance: module preprocessor (`use` preamble) + multiple modules.

use core.io
use core.time

def main() returns i32
    var t0 is u64 = now_ns()
    var t1 is u64 = now_ns()
    if t1 < t0 then
        return 1
    println("ok")
    return 0

