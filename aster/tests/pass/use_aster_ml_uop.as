# Expected: compile+run OK (UOp IR hash-consing + tiny rewrites)

use aster_ml.uop.ops
use core.io

def main() returns i32
    var ctx is UOpCtx
    if uop_ctx_init(&ctx) != 0 then
        return 1

    var z is MutString = uop_const_f32(&ctx, 0.0)
    var o is MutString = uop_const_f32(&ctx, 1.0)
    var m1 is MutString = uop_const_f32(&ctx, 0.0 - 1.0)
    if z is null or o is null or m1 is null then
        uop_ctx_free(&ctx)
        return 1

    # interning: identical consts are the same node
    var z2 is MutString = uop_const_f32(&ctx, 0.0)
    if z2 != z then
        uop_ctx_free(&ctx)
        return 1

    # interning: identical add is the same node
    var a1 is MutString = uop_add(&ctx, z, o)
    var a2 is MutString = uop_add(&ctx, z, o)
    if a1 is null or a2 is null then
        uop_ctx_free(&ctx)
        return 1
    if a1 != a2 then
        uop_ctx_free(&ctx)
        return 1

    # simplify: x+0 -> x
    var s1 is MutString = uop_simplify(&ctx, a1)
    if s1 != o then
        uop_ctx_free(&ctx)
        return 1

    # simplify: relu(const(-1)) -> const(0)
    var r is MutString = uop_relu(&ctx, m1)
    if r is null then
        uop_ctx_free(&ctx)
        return 1
    var sr is MutString = uop_simplify(&ctx, r)
    var ur is mut ref UOp = sr
    if (*ur).op != UOP_CONST then
        uop_ctx_free(&ctx)
        return 1
    if (*ur).arg0 != 0 then
        uop_ctx_free(&ctx)
        return 1

    uop_ctx_free(&ctx)
    println("ok")
    return 0
