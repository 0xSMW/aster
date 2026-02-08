# aster_ml.codegen.c (v0)
#
# Minimal C renderer for CPU elementwise kernels.
#
# v0 scope:
# - float32 elementwise kernels: add/mul/relu
# - stable symbol ABI:
#   - `aster_ml_kernel(out, a, b, n)` (out-of-line loop)
#   - `aster_ml_kernel_entry(void* ctx)` (dispatch_sync_f-compatible trampoline)

const C_EWISE_ADD_F32 is i32 = 1
const C_EWISE_MUL_F32 is i32 = 2
const C_EWISE_RELU_F32 is i32 = 3

def c_render_ewise_f32(op is i32) returns String
    # All kernels share the same exported symbols so callers can dlsym a
    # stable name per-dylib.
    if op == C_EWISE_ADD_F32 then
        return "#include <stddef.h>\n\n__attribute__((visibility(\"default\")))\nvoid aster_ml_kernel(float* out, const float* a, const float* b, size_t n) {\n    for (size_t i = 0; i < n; i++) {\n        out[i] = a[i] + b[i];\n    }\n}\n\ntypedef struct {\n    float* out;\n    const float* a;\n    const float* b;\n    size_t n;\n} AsterMlKernelCtx;\n\n__attribute__((visibility(\"default\")))\nvoid aster_ml_kernel_entry(void* p) {\n    AsterMlKernelCtx* c = (AsterMlKernelCtx*)p;\n    aster_ml_kernel(c->out, c->a, c->b, c->n);\n}\n"
    if op == C_EWISE_MUL_F32 then
        return "#include <stddef.h>\n\n__attribute__((visibility(\"default\")))\nvoid aster_ml_kernel(float* out, const float* a, const float* b, size_t n) {\n    for (size_t i = 0; i < n; i++) {\n        out[i] = a[i] * b[i];\n    }\n}\n\ntypedef struct {\n    float* out;\n    const float* a;\n    const float* b;\n    size_t n;\n} AsterMlKernelCtx;\n\n__attribute__((visibility(\"default\")))\nvoid aster_ml_kernel_entry(void* p) {\n    AsterMlKernelCtx* c = (AsterMlKernelCtx*)p;\n    aster_ml_kernel(c->out, c->a, c->b, c->n);\n}\n"
    if op == C_EWISE_RELU_F32 then
        return "#include <stddef.h>\n\n__attribute__((visibility(\"default\")))\nvoid aster_ml_kernel(float* out, const float* a, const float* b, size_t n) {\n    (void)b;\n    for (size_t i = 0; i < n; i++) {\n        float x = a[i];\n        if (x < 0.0f) x = 0.0f;\n        out[i] = x;\n    }\n}\n\ntypedef struct {\n    float* out;\n    const float* a;\n    const float* b;\n    size_t n;\n} AsterMlKernelCtx;\n\n__attribute__((visibility(\"default\")))\nvoid aster_ml_kernel_entry(void* p) {\n    AsterMlKernelCtx* c = (AsterMlKernelCtx*)p;\n    aster_ml_kernel(c->out, c->a, c->b, c->n);\n}\n"
    return null
