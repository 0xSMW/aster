# aster_ml.uop.upat (v0)
#
# Minimal pattern matching used by the UOp rewrite engine.
#
# This is a tiny subset of tinygrad's UPat/PatternMatcher: enough to match
# small algebraic identities deterministically and to bind variables.

use core.libc
use aster_ml.uop.ops

const UPAT_ANY_OP is i32 = 0

struct UPat
    var op is i32            # 0 => any op
    var bind is i32          # -1 => no binding, otherwise bind slot id
    var nsrc is usize
    var src is MutString     # `slice of MutString` (UPat*)
    var has_arg0 is i32
    var arg0 is u64
    var has_arg1 is i32
    var arg1 is u64


struct Bindings
    var vars is MutString  # `slice of MutString` (UOp*)
    var n is usize


def bindings_init(b is mut ref Bindings, n is usize) returns i32
    (*b).n = n
    (*b).vars = calloc(n, 8)
    if (*b).vars is null then
        (*b).n = 0
        return 1
    return 0


def bindings_free(b is mut ref Bindings) returns ()
    if (*b).vars is not null then
        free((*b).vars)
    (*b).vars = null
    (*b).n = 0
    return


def bindings_clear(b is mut ref Bindings) returns ()
    if (*b).vars is null then
        return
    var xs is slice of MutString = (*b).vars
    var i is usize = 0
    while i < (*b).n do
        xs[i] = null
        i = i + 1
    return


def upat_init(out is mut ref UPat, op is i32, bind is i32) returns ()
    (*out).op = op
    (*out).bind = bind
    (*out).nsrc = 0
    (*out).src = null
    (*out).has_arg0 = 0
    (*out).arg0 = 0
    (*out).has_arg1 = 0
    (*out).arg1 = 0
    return


def upat_set_src(out is mut ref UPat, nsrc is usize, src is slice of MutString) returns i32
    (*out).nsrc = nsrc
    (*out).src = null
    if nsrc == 0 then
        return 0
    var p is MutString = malloc(nsrc * 8)
    if p is null then
        return 1
    memcpy(p, src, nsrc * 8)
    (*out).src = p
    return 0


def upat_free(p is mut ref UPat) returns ()
    if (*p).src is not null then
        free((*p).src)
    (*p).src = null
    (*p).nsrc = 0
    return


def upat_match(pat is mut ref UPat, node is MutString, b is mut ref Bindings) returns i32
    if node is null then
        return 0
    var u is mut ref UOp = node

    if (*pat).op != UPAT_ANY_OP and (*pat).op != (*u).op then
        return 0
    if (*pat).has_arg0 != 0 and (*pat).arg0 != (*u).arg0 then
        return 0
    if (*pat).has_arg1 != 0 and (*pat).arg1 != (*u).arg1 then
        return 0

    if (*pat).bind >= 0 then
        if (*pat).bind >= (*b).n then
            return 0
        var xs is slice of MutString = (*b).vars
        var cur is MutString = xs[(*pat).bind]
        if cur is null then
            xs[(*pat).bind] = node
        else
            if cur != node then
                return 0

    if (*pat).nsrc != (*u).nsrc then
        return 0
    if (*pat).nsrc == 0 then
        return 1

    var ps is slice of MutString = (*pat).src
    var us is slice of MutString = (*u).src
    var i is usize = 0
    while i < (*pat).nsrc do
        var cp is mut ref UPat = ps[i]
        if upat_match(cp, us[i], b) == 0 then
            return 0
        i = i + 1
    return 1
