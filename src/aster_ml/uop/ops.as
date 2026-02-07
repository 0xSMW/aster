# aster_ml.uop.ops (v0)
#
# Minimal tinygrad-style UOp IR bring-up:
# - UOp nodes with structural hashes ("stable keys")
# - hash-consing / interning in an explicit context
# - tiny local simplifier (rewrite hook)
#
# This is intentionally small: it exists to unlock Phase 7 work without
# requiring global mutable state or advanced Aster language features.

use core.libc
use aster_ml.dtype

# ---- ops (subset) ----
const UOP_INVALID is i32 = 0
const UOP_CONST is i32 = 1
const UOP_ADD is i32 = 2
const UOP_MUL is i32 = 3
const UOP_RELU is i32 = 4

# ---- generic helpers ----

def hash_mix_u64(x is u64) returns u64
    # 64-bit finalizer (MurmurHash3 fmix64)
    var z is u64 = x
    z = z ^ (z >> 33)
    z = z * 0xff51afd7ed558ccd
    z = z ^ (z >> 33)
    z = z * 0xc4ceb9fe1a85ec53
    z = z ^ (z >> 33)
    # Reserve 0 as "empty" in hash tables.
    if z == 0 then
        return 1
    return z


def hash_combine(h is u64, x is u64) returns u64
    # Classic boost-ish combine, then mix.
    var z is u64 = h ^ (x + 0x9e3779b97f4a7c15 + (h << 6) + (h >> 2))
    return hash_mix_u64(z)


def uop_hash(op is i32, dtype is i32, nsrc is usize, src_keys is slice of u64, arg0 is u64, arg1 is u64) returns u64
    var h is u64 = 0x243f6a8885a308d3
    h = hash_combine(h, op)
    h = hash_combine(h, dtype)
    h = hash_combine(h, nsrc)
    h = hash_combine(h, arg0)
    h = hash_combine(h, arg1)
    var i is usize = 0
    while i < nsrc do
        h = hash_combine(h, src_keys[i])
        i = i + 1
    return h


struct VecPtr
    var data is MutString  # `slice of MutString`
    var len is usize
    var cap is usize


def vec_ptr_init(v is mut ref VecPtr) returns ()
    (*v).data = null
    (*v).len = 0
    (*v).cap = 0
    return


def vec_ptr_free(v is mut ref VecPtr) returns ()
    if (*v).data is not null then
        free((*v).data)
    (*v).data = null
    (*v).len = 0
    (*v).cap = 0
    return


def vec_ptr_reserve(v is mut ref VecPtr, want is usize) returns i32
    if want <= (*v).cap then
        return 0
    var new_cap is usize = (*v).cap
    if new_cap < 8 then
        new_cap = 8
    while new_cap < want do
        new_cap = new_cap * 2
    var new_data is MutString = malloc(new_cap * 8)
    if new_data is null then
        return 1
    if (*v).data is not null and (*v).len != 0 then
        memcpy(new_data, (*v).data, (*v).len * 8)
        free((*v).data)
    (*v).data = new_data
    (*v).cap = new_cap
    return 0


def vec_ptr_push(v is mut ref VecPtr, p is MutString) returns i32
    if vec_ptr_reserve(v, (*v).len + 1) != 0 then
        return 1
    var xs is slice of MutString = (*v).data
    xs[(*v).len] = p
    (*v).len = (*v).len + 1
    return 0


struct UOp
    var op is i32
    var dtype is i32
    var nsrc is usize
    var src is MutString  # `slice of MutString` (UOp*)
    var arg0 is u64
    var arg1 is u64
    var key is u64


struct UOpCtx
    # Intern table: (keyhash -> UOp*)
    var tab_keys is MutString  # `slice of u64`
    var tab_vals is MutString  # `slice of MutString` (UOp*)
    var tab_cap is usize
    var tab_len is usize
    # Ownership tracking for freeing.
    var nodes is VecPtr


def uop_ctx_init(ctx is mut ref UOpCtx) returns i32
    (*ctx).tab_cap = 1024
    (*ctx).tab_len = 0
    (*ctx).tab_keys = calloc((*ctx).tab_cap, 8)
    if (*ctx).tab_keys is null then
        return 1
    (*ctx).tab_vals = calloc((*ctx).tab_cap, 8)
    if (*ctx).tab_vals is null then
        free((*ctx).tab_keys)
        (*ctx).tab_keys = null
        return 1
    vec_ptr_init(&(*ctx).nodes)
    return 0


def uop_ctx_free(ctx is mut ref UOpCtx) returns ()
    # Free all nodes (and their src arrays).
    var xs is slice of MutString = (*ctx).nodes.data
    var i is usize = 0
    while i < (*ctx).nodes.len do
        var p is MutString = xs[i]
        if p is not null then
            var u is mut ref UOp = p
            if (*u).src is not null then
                free((*u).src)
            free(p)
        i = i + 1
    vec_ptr_free(&(*ctx).nodes)

    if (*ctx).tab_keys is not null then
        free((*ctx).tab_keys)
    if (*ctx).tab_vals is not null then
        free((*ctx).tab_vals)
    (*ctx).tab_keys = null
    (*ctx).tab_vals = null
    (*ctx).tab_cap = 0
    (*ctx).tab_len = 0
    return


def uop_tab_grow(ctx is mut ref UOpCtx) returns i32
    var old_cap is usize = (*ctx).tab_cap
    var new_cap is usize = old_cap * 2
    var new_keys is MutString = calloc(new_cap, 8)
    if new_keys is null then
        return 1
    var new_vals is MutString = calloc(new_cap, 8)
    if new_vals is null then
        free(new_keys)
        return 1

    var oldk is slice of u64 = (*ctx).tab_keys
    var oldv is slice of MutString = (*ctx).tab_vals
    var nk is slice of u64 = new_keys
    var nv is slice of MutString = new_vals

    var i is usize = 0
    while i < old_cap do
        var k is u64 = oldk[i]
        if k != 0 then
            var idx is usize = k
            idx = idx & (new_cap - 1)
            while nk[idx] != 0 do
                idx = (idx + 1) & (new_cap - 1)
            nk[idx] = k
            nv[idx] = oldv[i]
        i = i + 1

    free((*ctx).tab_keys)
    free((*ctx).tab_vals)
    (*ctx).tab_keys = new_keys
    (*ctx).tab_vals = new_vals
    (*ctx).tab_cap = new_cap
    return 0


def uop_eq(u is mut ref UOp, op is i32, dtype is i32, nsrc is usize, src is slice of MutString, arg0 is u64, arg1 is u64) returns i32
    if (*u).op != op then
        return 0
    if (*u).dtype != dtype then
        return 0
    if (*u).nsrc != nsrc then
        return 0
    if (*u).arg0 != arg0 or (*u).arg1 != arg1 then
        return 0
    if nsrc == 0 then
        return 1
    var usrc is slice of MutString = (*u).src
    var i is usize = 0
    while i < nsrc do
        if usrc[i] != src[i] then
            return 0
        i = i + 1
    return 1


def uop_intern(ctx is mut ref UOpCtx, op is i32, dtype is i32, nsrc is usize, src is slice of MutString, arg0 is u64, arg1 is u64) returns MutString
    # Compute structural hash from children keys (stable keys).
    var tmp_keys is slice of u64 = null
    if nsrc != 0 then
        tmp_keys = malloc(nsrc * 8)
        if tmp_keys is null then
            return null
        var i is usize = 0
        while i < nsrc do
            var su is mut ref UOp = src[i]
            tmp_keys[i] = (*su).key
            i = i + 1
    var key is u64 = uop_hash(op, dtype, nsrc, tmp_keys, arg0, arg1)
    if tmp_keys is not null then
        free(tmp_keys)

    # Grow table if load factor > 0.7.
    if ((*ctx).tab_len * 10) >= ((*ctx).tab_cap * 7) then
        if uop_tab_grow(ctx) != 0 then
            return null

    var keys is slice of u64 = (*ctx).tab_keys
    var vals is slice of MutString = (*ctx).tab_vals
    var cap is usize = (*ctx).tab_cap

    var idx is usize = key
    idx = idx & (cap - 1)
    while keys[idx] != 0 do
        if keys[idx] == key then
            var p is MutString = vals[idx]
            if p is not null then
                var u is mut ref UOp = p
                if uop_eq(u, op, dtype, nsrc, src, arg0, arg1) != 0 then
                    return p
        idx = (idx + 1) & (cap - 1)

    # Allocate node.
    var up is MutString = malloc(56)  # sizeof(UOp) on 64-bit (aligned)
    if up is null then
        return null
    var u is mut ref UOp = up
    (*u).op = op
    (*u).dtype = dtype
    (*u).nsrc = nsrc
    (*u).arg0 = arg0
    (*u).arg1 = arg1
    (*u).key = key
    (*u).src = null
    if nsrc != 0 then
        var sp is MutString = malloc(nsrc * 8)
        if sp is null then
            free(up)
            return null
        memcpy(sp, src, nsrc * 8)
        (*u).src = sp

    if vec_ptr_push(&(*ctx).nodes, up) != 0 then
        if (*u).src is not null then
            free((*u).src)
        free(up)
        return null

    keys[idx] = key
    vals[idx] = up
    (*ctx).tab_len = (*ctx).tab_len + 1
    return up


# ---- constructors (subset) ----

def uop_const_f32(ctx is mut ref UOpCtx, v is f32) returns MutString
    # Store float bits in arg0 for stable hashing/identity.
    var tmp is f32 = v
    var pf is mut ref f32 = &tmp
    var pu is mut ref u32 = pf
    var bits is u32 = *pu
    return uop_intern(ctx, UOP_CONST, DT_F32, 0, null, bits, 0)


def uop_add(ctx is mut ref UOpCtx, a is MutString, b is MutString) returns MutString
    var src is slice of MutString = malloc(2 * 8)
    if src is null then
        return null
    src[0] = a
    src[1] = b
    var out is MutString = uop_intern(ctx, UOP_ADD, DT_F32, 2, src, 0, 0)
    free(src)
    return out


def uop_mul(ctx is mut ref UOpCtx, a is MutString, b is MutString) returns MutString
    var src is slice of MutString = malloc(2 * 8)
    if src is null then
        return null
    src[0] = a
    src[1] = b
    var out is MutString = uop_intern(ctx, UOP_MUL, DT_F32, 2, src, 0, 0)
    free(src)
    return out


def uop_relu(ctx is mut ref UOpCtx, a is MutString) returns MutString
    var src is slice of MutString = malloc(1 * 8)
    if src is null then
        return null
    src[0] = a
    var out is MutString = uop_intern(ctx, UOP_RELU, DT_F32, 1, src, 0, 0)
    free(src)
    return out


# ---- simplifier (local rewrite engine hook) ----

def uop_is_const_zero(u is mut ref UOp) returns i32
    if (*u).op != UOP_CONST then
        return 0
    # arg0 holds u32 bits of f32.
    return ((*u).arg0 == 0)


def uop_is_const_one(u is mut ref UOp) returns i32
    if (*u).op != UOP_CONST then
        return 0
    return ((*u).arg0 == 0x3f800000)  # 1.0f32


def uop_simplify(ctx is mut ref UOpCtx, p is MutString) returns MutString
    if p is null then
        return null
    var u is mut ref UOp = p

    if (*u).nsrc == 0 then
        return p

    # Simplify children first.
    var nsrc is usize = (*u).nsrc
    var changed is i32 = 0
    var src is slice of MutString = malloc(nsrc * 8)
    if src is null then
        return p
    var usrc is slice of MutString = (*u).src
    var i is usize = 0
    while i < nsrc do
        var sp is MutString = uop_simplify(ctx, usrc[i])
        src[i] = sp
        if sp != usrc[i] then
            changed = 1
        i = i + 1

    # Local rewrites.
    if (*u).op == UOP_ADD then
        var a is mut ref UOp = src[0]
        var b is mut ref UOp = src[1]
        if uop_is_const_zero(a) != 0 then
            var ret is MutString = src[1]
            free(src)
            return ret
        if uop_is_const_zero(b) != 0 then
            var ret2 is MutString = src[0]
            free(src)
            return ret2

    if (*u).op == UOP_MUL then
        var a is mut ref UOp = src[0]
        var b is mut ref UOp = src[1]
        if uop_is_const_one(a) != 0 then
            var ret3 is MutString = src[1]
            free(src)
            return ret3
        if uop_is_const_one(b) != 0 then
            var ret4 is MutString = src[0]
            free(src)
            return ret4
        if uop_is_const_zero(a) != 0 then
            var ret5 is MutString = src[0]
            free(src)
            return ret5
        if uop_is_const_zero(b) != 0 then
            var ret6 is MutString = src[1]
            free(src)
            return ret6

    if (*u).op == UOP_RELU then
        var a is mut ref UOp = src[0]
        if (*a).op == UOP_CONST then
            # const relu can fold.
            var bits is u32 = (*a).arg0
            var tmp is u32 = bits
            var pu is mut ref u32 = &tmp
            var pf is mut ref f32 = pu
            var fv is f32 = *pf
            if fv < 0.0 then
                fv = 0.0
            var out is MutString = uop_const_f32(ctx, fv)
            free(src)
            return out

    # Rebuild node if any child changed.
    if changed != 0 then
        var out is MutString = uop_intern(ctx, (*u).op, (*u).dtype, nsrc, src, (*u).arg0, (*u).arg1)
        free(src)
        return out

    free(src)
    return p
