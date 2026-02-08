# aster_ml.uop.symbolic (v0)
#
# Minimal symbolic integer system for shapes/indices:
# - const ints
# - named variables
# - add/mul expression nodes
#
# This is not a full tinygrad port yet; it's enough to represent and evaluate
# simple expressions deterministically in the Aster ML stack.

use core.libc

const SYM_CONST is i32 = 0
const SYM_VAR is i32 = 1
const SYM_ADD is i32 = 2
const SYM_MUL is i32 = 3

struct SymInt
    var kind is i32
    var val is i64
    var name is String        # for SYM_VAR
    var a is MutString        # SymInt*
    var b is MutString        # SymInt*


def sym_const(v is i64) returns MutString
    var p is MutString = malloc(40)
    if p is null then
        return null
    var s is mut ref SymInt = p
    (*s).kind = SYM_CONST
    (*s).val = v
    (*s).name = null
    (*s).a = null
    (*s).b = null
    return p


def sym_var(name is String) returns MutString
    var p is MutString = malloc(40)
    if p is null then
        return null
    var s is mut ref SymInt = p
    (*s).kind = SYM_VAR
    (*s).val = 0
    (*s).name = name
    (*s).a = null
    (*s).b = null
    return p


def sym_add(a is MutString, b is MutString) returns MutString
    var p is MutString = malloc(40)
    if p is null then
        return null
    var s is mut ref SymInt = p
    (*s).kind = SYM_ADD
    (*s).val = 0
    (*s).name = null
    (*s).a = a
    (*s).b = b
    return p


def sym_mul(a is MutString, b is MutString) returns MutString
    var p is MutString = malloc(40)
    if p is null then
        return null
    var s is mut ref SymInt = p
    (*s).kind = SYM_MUL
    (*s).val = 0
    (*s).name = null
    (*s).a = a
    (*s).b = b
    return p


def sym_free(p is MutString) returns ()
    if p is null then
        return
    var s is mut ref SymInt = p
    # v0: no owned strings; name pointers are borrowed.
    # Free children recursively.
    if (*s).a is not null then
        sym_free((*s).a)
    if (*s).b is not null then
        sym_free((*s).b)
    free(p)
    return


def sym_lookup(name is String, n is usize, names is slice of String, vals is slice of i64, found is mut ref i32) returns i64
    # linear search (small n)
    var i is usize = 0
    while i < n do
        var s is String = names[i]
        # strcmp without libc: compare bytes until NUL or mismatch.
        var a is String = name
        var b is String = s
        var ok is i32 = 1
        while a[0] != 0 or b[0] != 0 do
            if a[0] != b[0] then
                ok = 0
                break
            a = a + 1
            b = b + 1
        if ok != 0 then
            *found = 1
            return vals[i]
        i = i + 1
    *found = 0
    return 0


def sym_eval(p is MutString, n is usize, names is slice of String, vals is slice of i64, ok is mut ref i32) returns i64
    if p is null then
        *ok = 0
        return 0
    var s is mut ref SymInt = p
    if (*s).kind == SYM_CONST then
        *ok = 1
        return (*s).val
    if (*s).kind == SYM_VAR then
        return sym_lookup((*s).name, n, names, vals, ok)
    if (*s).kind == SYM_ADD then
        var ok0 is i32 = 0
        var ok1 is i32 = 0
        var x is i64 = sym_eval((*s).a, n, names, vals, &ok0)
        var y is i64 = sym_eval((*s).b, n, names, vals, &ok1)
        if ok0 == 0 or ok1 == 0 then
            *ok = 0
            return 0
        *ok = 1
        return x + y
    if (*s).kind == SYM_MUL then
        var ok0 is i32 = 0
        var ok1 is i32 = 0
        var x is i64 = sym_eval((*s).a, n, names, vals, &ok0)
        var y is i64 = sym_eval((*s).b, n, names, vals, &ok1)
        if ok0 == 0 or ok1 == 0 then
            *ok = 0
            return 0
        *ok = 1
        return x * y
    *ok = 0
    return 0
