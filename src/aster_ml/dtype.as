# aster_ml.dtype (v1, partial tinygrad parity)
#
# This file provides a tinygrad-inspired scalar dtype system:
# - scalar dtype codes
# - itemsize/name queries
# - least-upper-dtype promotion (JAX-style lattice; subset)
#
# Note: ML kernels are currently float32-first; f16/bf16 are represented as
# codes for promotion/serialization but not yet supported as first-class scalar
# types in Aster codegen.

const DT_INVALID is i32 = 0

const DT_BOOL is i32 = 1
const DT_I8 is i32 = 2
const DT_U8 is i32 = 3
const DT_I16 is i32 = 4
const DT_U16 is i32 = 5
const DT_I32 is i32 = 6
const DT_U32 is i32 = 7
const DT_I64 is i32 = 8
const DT_U64 is i32 = 9

const DT_F16 is i32 = 10
const DT_BF16 is i32 = 11
const DT_F32 is i32 = 12
const DT_F64 is i32 = 13

# tinygrad has an `index` dtype; we model it as a scalar code for now.
const DT_INDEX is i32 = 14


def dtype_itemsize(dt is i32) returns usize
    if dt == DT_BOOL then
        return 1
    if dt == DT_I8 or dt == DT_U8 then
        return 1
    if dt == DT_I16 or dt == DT_U16 then
        return 2
    if dt == DT_I32 or dt == DT_U32 then
        return 4
    if dt == DT_I64 or dt == DT_U64 or dt == DT_INDEX then
        return 8
    if dt == DT_F16 or dt == DT_BF16 then
        return 2
    if dt == DT_F32 then
        return 4
    if dt == DT_F64 then
        return 8
    return 0


def dtype_is_float(dt is i32) returns i32
    return (dt == DT_F16 or dt == DT_BF16 or dt == DT_F32 or dt == DT_F64)


def dtype_is_int(dt is i32) returns i32
    return (dt == DT_I8 or dt == DT_U8 or dt == DT_I16 or dt == DT_U16 or dt == DT_I32 or dt == DT_U32 or dt == DT_I64 or dt == DT_U64 or dt == DT_INDEX)


def dtype_is_unsigned(dt is i32) returns i32
    return (dt == DT_U8 or dt == DT_U16 or dt == DT_U32 or dt == DT_U64)


def dtype_name(dt is i32) returns String
    if dt == DT_BOOL then
        return "bool"
    if dt == DT_I8 then
        return "i8"
    if dt == DT_U8 then
        return "u8"
    if dt == DT_I16 then
        return "i16"
    if dt == DT_U16 then
        return "u16"
    if dt == DT_I32 then
        return "i32"
    if dt == DT_U32 then
        return "u32"
    if dt == DT_I64 then
        return "i64"
    if dt == DT_U64 then
        return "u64"
    if dt == DT_F16 then
        return "f16"
    if dt == DT_BF16 then
        return "bf16"
    if dt == DT_F32 then
        return "f32"
    if dt == DT_F64 then
        return "f64"
    if dt == DT_INDEX then
        return "index"
    return "invalid"


def dtype_priority(dt is i32) returns i32
    # Mirrors tinygrad's scalar priorities for the common subset.
    if dt == DT_BOOL then
        return 0
    if dt == DT_I8 then
        return 1
    if dt == DT_U8 then
        return 2
    if dt == DT_I16 then
        return 3
    if dt == DT_U16 then
        return 4
    if dt == DT_I32 then
        return 5
    if dt == DT_U32 then
        return 6
    if dt == DT_I64 then
        return 7
    if dt == DT_U64 then
        return 8
    if dt == DT_F16 then
        return 11
    if dt == DT_BF16 then
        return 12
    if dt == DT_F32 then
        return 13
    if dt == DT_F64 then
        return 14
    if dt == DT_INDEX then
        return -1
    return -999


def dtype_order_next(dt is i32) returns i32
    # Total order used for `dtype_least_upper` scanning.
    if dt == DT_BOOL then
        return DT_I8
    if dt == DT_I8 then
        return DT_U8
    if dt == DT_U8 then
        return DT_I16
    if dt == DT_I16 then
        return DT_U16
    if dt == DT_U16 then
        return DT_I32
    if dt == DT_I32 then
        return DT_U32
    if dt == DT_U32 then
        return DT_I64
    if dt == DT_I64 then
        return DT_U64
    if dt == DT_U64 then
        return DT_F16
    if dt == DT_F16 then
        return DT_BF16
    if dt == DT_BF16 then
        return DT_F32
    if dt == DT_F32 then
        return DT_F64
    return DT_INVALID


def dtype_parents(dt is i32, p0 is mut ref i32, p1 is mut ref i32, pn is mut ref i32) returns ()
    # Promotion lattice (subset of tinygrad's `promo_lattice`).
    *pn = 0
    *p0 = DT_INVALID
    *p1 = DT_INVALID

    if dt == DT_BOOL then
        *pn = 2
        *p0 = DT_I8
        *p1 = DT_U8
        return
    if dt == DT_I8 then
        *pn = 1
        *p0 = DT_I16
        return
    if dt == DT_I16 then
        *pn = 1
        *p0 = DT_I32
        return
    if dt == DT_I32 then
        *pn = 1
        *p0 = DT_I64
        return
    if dt == DT_I64 then
        *pn = 1
        *p0 = DT_U64
        return

    if dt == DT_U8 then
        *pn = 2
        *p0 = DT_I16
        *p1 = DT_U16
        return
    if dt == DT_U16 then
        *pn = 2
        *p0 = DT_I32
        *p1 = DT_U32
        return
    if dt == DT_U32 then
        *pn = 2
        *p0 = DT_I64
        *p1 = DT_U64
        return
    if dt == DT_U64 then
        *pn = 2
        *p0 = DT_F16
        *p1 = DT_BF16
        return

    if dt == DT_F16 then
        *pn = 1
        *p0 = DT_F32
        return
    if dt == DT_BF16 then
        *pn = 1
        *p0 = DT_F32
        return
    if dt == DT_F32 then
        *pn = 1
        *p0 = DT_F64
        return

    # DT_F64 is the top.
    return


def dtype_is_ancestor(cand is i32, dt is i32) returns i32
    # True if `cand` is in the recursive-parent set of `dt` (including self).
    if cand == dt then
        return 1
    if dt == DT_INVALID then
        return 0
    var p0 is i32 = DT_INVALID
    var p1 is i32 = DT_INVALID
    var pn is i32 = 0
    dtype_parents(dt, &p0, &p1, &pn)
    if pn == 0 then
        return 0
    if pn >= 1 then
        if dtype_is_ancestor(cand, p0) != 0 then
            return 1
    if pn >= 2 then
        if dtype_is_ancestor(cand, p1) != 0 then
            return 1
    return 0


def dtype_least_upper(a is i32, b is i32) returns i32
    if a == DT_INVALID or b == DT_INVALID then
        return DT_INVALID
    if a == b then
        return a
    # `index` is special in tinygrad; for now treat it as "int-like" and keep it.
    if a == DT_INDEX then
        return DT_INDEX
    if b == DT_INDEX then
        return DT_INDEX

    var cand is i32 = DT_BOOL
    while cand != DT_INVALID do
        if dtype_is_ancestor(cand, a) != 0 and dtype_is_ancestor(cand, b) != 0 then
            return cand
        cand = dtype_order_next(cand)
    return DT_INVALID


def dtype_promote(a is i32, b is i32) returns i32
    return dtype_least_upper(a, b)

