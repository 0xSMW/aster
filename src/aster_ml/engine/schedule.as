# aster_ml.engine.schedule (v0)
#
# Deterministic schedule construction for a UOp sink.
#
# v0: a minimal topo-order schedule used to unblock the rest of the ML stack.

use aster_ml.uop.ops

struct Schedule
    var order is VecPtr   # list of UOp* in dependency order


def schedule_init(s is mut ref Schedule) returns ()
    vec_ptr_init(&(*s).order)
    return


def schedule_free(s is mut ref Schedule) returns ()
    vec_ptr_free(&(*s).order)
    return


def vec_ptr_contains(v is mut ref VecPtr, p is MutString) returns i32
    var xs is slice of MutString = (*v).data
    var i is usize = 0
    while i < (*v).len do
        if xs[i] == p then
            return 1
        i = i + 1
    return 0


def schedule_visit(order is mut ref VecPtr, seen is mut ref VecPtr, p is MutString) returns i32
    if p is null then
        return 1
    if vec_ptr_contains(seen, p) != 0 then
        return 0
    if vec_ptr_push(seen, p) != 0 then
        return 1

    var u is mut ref UOp = p
    var i is usize = 0
    var src is slice of MutString = (*u).src
    while i < (*u).nsrc do
        if schedule_visit(order, seen, src[i]) != 0 then
            return 1
        i = i + 1

    if vec_ptr_push(order, p) != 0 then
        return 1
    return 0


def schedule_build(out is mut ref Schedule, sink is MutString) returns i32
    schedule_init(out)
    var seen is VecPtr
    vec_ptr_init(&seen)

    var rc is i32 = schedule_visit(&(*out).order, &seen, sink)
    vec_ptr_free(&seen)
    if rc != 0 then
        schedule_free(out)
        return 1
    return 0
