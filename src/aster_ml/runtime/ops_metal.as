# aster_ml.runtime.ops_metal (v0)
#
# Metal runtime hooks. These functions are implemented in
# `asm/compiler/ml_metal_rt.m` and auto-linked when this module is imported.

use core.libc

# Buffer allocation/free (shared storage so CPU can read/write `data`).
extern def aster_metal_buf_alloc(nbytes is usize, out_base is mut ref MutString, out_data is mut ref MutString) returns i32
extern def aster_metal_buf_free(base is MutString) returns ()

def metal_buf_alloc(nbytes is usize, out_base is mut ref MutString, out_data is mut ref MutString) returns i32
    return aster_metal_buf_alloc(nbytes, out_base, out_data)

def metal_buf_free(base is MutString) returns ()
    aster_metal_buf_free(base)
    return


# Kernels (v0 subset)
extern def aster_metal_add_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, b_base is MutString, b_off is usize, n is usize) returns i32
extern def aster_metal_mul_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, b_base is MutString, b_off is usize, n is usize) returns i32
extern def aster_metal_relu_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, n is usize) returns i32
extern def aster_metal_matmul_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, b_base is MutString, b_off is usize, m is usize, k is usize, n is usize) returns i32

def metal_add_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, b_base is MutString, b_off is usize, n is usize) returns i32
    return aster_metal_add_f32(out_base, out_off, a_base, a_off, b_base, b_off, n)

def metal_mul_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, b_base is MutString, b_off is usize, n is usize) returns i32
    return aster_metal_mul_f32(out_base, out_off, a_base, a_off, b_base, b_off, n)

def metal_relu_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, n is usize) returns i32
    return aster_metal_relu_f32(out_base, out_off, a_base, a_off, n)

def metal_matmul_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, b_base is MutString, b_off is usize, m is usize, k is usize, n is usize) returns i32
    # out: (m,n), a: (m,k), b: (k,n) in row-major contiguous float32.
    return aster_metal_matmul_f32(out_base, out_off, a_base, a_off, b_base, b_off, m, k, n)
