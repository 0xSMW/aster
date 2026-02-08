# Expected: compile+run OK (UPat matching + bindings)

use aster_ml.uop.ops
use aster_ml.uop.upat
use core.libc
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

    # node: add(o, z)
    var add is MutString = uop_add(&ctx, o, z)
    if add is null then
        uop_ctx_free(&ctx)
        return 1

    # pattern: ADD(x, CONST(0.0))
    var px is UPat
    upat_init(&px, UPAT_ANY_OP, 0)

    var pz is UPat
    upat_init(&pz, UOP_CONST, -1)
    pz.has_arg0 = 1
    pz.arg0 = 0

    var padd is UPat
    upat_init(&padd, UOP_ADD, -1)
    var src is slice of MutString = malloc(2 * 8)
    if src is null then
        uop_ctx_free(&ctx)
        return 1
    src[0] = &px
    src[1] = &pz
    if upat_set_src(&padd, 2, src) != 0 then
        free(src)
        uop_ctx_free(&ctx)
        return 1
    free(src)

    var b is Bindings
    if bindings_init(&b, 1) != 0 then
        upat_free(&padd)
        uop_ctx_free(&ctx)
        return 1
    bindings_clear(&b)

    if upat_match(&padd, add, &b) == 0 then
        bindings_free(&b)
        upat_free(&padd)
        uop_ctx_free(&ctx)
        return 1

    var xs is slice of MutString = b.vars
    if xs[0] != o then
        bindings_free(&b)
        upat_free(&padd)
        uop_ctx_free(&ctx)
        return 1

    bindings_free(&b)
    upat_free(&padd)
    uop_ctx_free(&ctx)
    println("ok")
    return 0
