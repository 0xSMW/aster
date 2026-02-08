# Expected: compile+run OK (schedule topo order)

use aster_ml.uop.ops
use aster_ml.engine.schedule
use core.io

def main() returns i32
    var ctx is UOpCtx
    if uop_ctx_init(&ctx) != 0 then
        return 1

    var z is MutString = uop_const_f32(&ctx, 0.0)
    var o is MutString = uop_const_f32(&ctx, 1.0)
    if z is null or o is null then
        uop_ctx_free(&ctx)
        return 1

    var m is MutString = uop_mul(&ctx, o, o)
    if m is null then
        uop_ctx_free(&ctx)
        return 1
    var add is MutString = uop_add(&ctx, m, z)
    if add is null then
        uop_ctx_free(&ctx)
        return 1

    var s is Schedule
    if schedule_build(&s, add) != 0 then
        uop_ctx_free(&ctx)
        return 1

    if s.order.len != 4 then
        schedule_free(&s)
        uop_ctx_free(&ctx)
        return 1
    var xs is slice of MutString = s.order.data
    if xs[3] != add then
        schedule_free(&s)
        uop_ctx_free(&ctx)
        return 1

    schedule_free(&s)
    uop_ctx_free(&ctx)
    println("ok")
    return 0

