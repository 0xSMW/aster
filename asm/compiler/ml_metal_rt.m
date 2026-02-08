// Aster ML Metal runtime helpers (v0).
//
// This file is compiled into tools/build/out/ml_metal_rt.o and is meant to be
// linked into produced Aster binaries when `src/aster_ml/runtime/ops_metal.as`
// is imported (auto-link in asterc unit flags).
//
// Policy note: This is a runtime helper, not a compiler shim. Kernels are
// compiled by Metal at runtime.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreFoundation/CoreFoundation.h>

#include <pthread.h>
#include <stdint.h>
#include <string.h>

typedef struct {
  id<MTLDevice> dev;
  id<MTLCommandQueue> q;
  id<MTLLibrary> lib;
  id<MTLComputePipelineState> add_f32;
  id<MTLComputePipelineState> mul_f32;
  id<MTLComputePipelineState> relu_f32;
  id<MTLComputePipelineState> matmul_f32;
  int inited_devq;
} AsterMetalCtx;

static AsterMetalCtx g_ctx = {0};
static pthread_mutex_t g_metal_lock = PTHREAD_MUTEX_INITIALIZER;

static const char* kSrc =
    "#include <metal_stdlib>\n"
    "using namespace metal;\n"
    "\n"
    "kernel void add_f32(device const float* a [[buffer(0)]],\n"
    "                    device const float* b [[buffer(1)]],\n"
    "                    device float* out [[buffer(2)]],\n"
    "                    uint gid [[thread_position_in_grid]]) {\n"
    "  out[gid] = a[gid] + b[gid];\n"
    "}\n"
    "\n"
    "kernel void mul_f32(device const float* a [[buffer(0)]],\n"
    "                    device const float* b [[buffer(1)]],\n"
    "                    device float* out [[buffer(2)]],\n"
    "                    uint gid [[thread_position_in_grid]]) {\n"
    "  out[gid] = a[gid] * b[gid];\n"
    "}\n"
    "\n"
    "kernel void relu_f32(device const float* a [[buffer(0)]],\n"
    "                     device float* out [[buffer(1)]],\n"
    "                     uint gid [[thread_position_in_grid]]) {\n"
    "  float x = a[gid];\n"
    "  out[gid] = (x < 0.0f) ? 0.0f : x;\n"
    "}\n";

// Append additional kernels at build-time to keep a single MTLLibrary.
static const char* kSrcMatmul =
    "\n"
    "kernel void matmul_f32(device const float* a [[buffer(0)]],\n"
    "                       device const float* b [[buffer(1)]],\n"
    "                       device float* out [[buffer(2)]],\n"
    "                       constant uint& M [[buffer(3)]],\n"
    "                       constant uint& K [[buffer(4)]],\n"
    "                       constant uint& N [[buffer(5)]],\n"
    "                       uint gid [[thread_position_in_grid]]) {\n"
    "  if (N == 0) return;\n"
    "  uint row = gid / N;\n"
    "  uint col = gid - (row * N);\n"
    "  if (row >= M || col >= N) return;\n"
    "  float acc = 0.0f;\n"
    "  for (uint p = 0; p < K; p++) {\n"
    "    acc += a[row * K + p] * b[p * N + col];\n"
    "  }\n"
    "  out[row * N + col] = acc;\n"
    "}\n";

static int aster_metal_init_devq_locked(void) {
  if (g_ctx.inited_devq) return 0;
  @autoreleasepool {
    g_ctx.dev = MTLCreateSystemDefaultDevice();
    if (!g_ctx.dev) return 1;
    g_ctx.q = [g_ctx.dev newCommandQueue];
    if (!g_ctx.q) return 1;
    g_ctx.inited_devq = 1;
    return 0;
  }
}

static int aster_metal_init_devq(void) {
  pthread_mutex_lock(&g_metal_lock);
  int rc = aster_metal_init_devq_locked();
  pthread_mutex_unlock(&g_metal_lock);
  return rc;
}

static int aster_metal_ensure_library_locked(void) {
  if (g_ctx.lib) return 0;
  if (aster_metal_init_devq_locked() != 0) return 1;
  @autoreleasepool {
    NSError* err = nil;
    // Single compiled library cached for the process lifetime.
    NSString* src = [NSString stringWithFormat:@"%s%s", kSrc, kSrcMatmul];
    g_ctx.lib = [g_ctx.dev newLibraryWithSource:src options:nil error:&err];
    return g_ctx.lib ? 0 : 1;
  }
}

static int aster_metal_ensure_library(void) {
  pthread_mutex_lock(&g_metal_lock);
  int rc = aster_metal_ensure_library_locked();
  pthread_mutex_unlock(&g_metal_lock);
  return rc;
}

static int aster_metal_ensure_pso_locked(id<MTLComputePipelineState>* out, const char* name_cstr) {
  if (!out) return 1;
  if (*out) return 0;
  if (aster_metal_ensure_library_locked() != 0) return 1;
  @autoreleasepool {
    NSError* err = nil;
    NSString* name = [NSString stringWithUTF8String:name_cstr];
    if (!name) return 1;
    id<MTLFunction> f = [g_ctx.lib newFunctionWithName:name];
    if (!f) return 1;
    id<MTLComputePipelineState> pso = [g_ctx.dev newComputePipelineStateWithFunction:f error:&err];
#if !__has_feature(objc_arc)
    [f release];
#endif
    if (!pso) return 1;
    *out = pso;
    return 0;
  }
}

static int aster_metal_ensure_pso(id<MTLComputePipelineState>* out, const char* name_cstr) {
  pthread_mutex_lock(&g_metal_lock);
  int rc = aster_metal_ensure_pso_locked(out, name_cstr);
  pthread_mutex_unlock(&g_metal_lock);
  return rc;
}

static int dispatch_1d(id<MTLComputePipelineState> pso, id<MTLBuffer> b0, NSUInteger o0, id<MTLBuffer> b1, NSUInteger o1,
                       id<MTLBuffer> b2, NSUInteger o2, uint64_t n, int nargs) {
  if (n == 0) return 0;
  @autoreleasepool {
    id<MTLCommandBuffer> cb = [g_ctx.q commandBuffer];
    if (!cb) return 1;
    id<MTLComputeCommandEncoder> enc = [cb computeCommandEncoder];
    if (!enc) return 1;
    [enc setComputePipelineState:pso];
    if (nargs >= 1) [enc setBuffer:b0 offset:o0 atIndex:0];
    if (nargs >= 2) [enc setBuffer:b1 offset:o1 atIndex:1];
    if (nargs >= 3) [enc setBuffer:b2 offset:o2 atIndex:2];

    MTLSize grid = MTLSizeMake((NSUInteger)n, 1, 1);
    NSUInteger tg = pso.maxTotalThreadsPerThreadgroup;
    if (tg == 0) tg = 1;
    if (tg > (NSUInteger)n) tg = (NSUInteger)n;
    MTLSize th = MTLSizeMake(tg, 1, 1);
    [enc dispatchThreads:grid threadsPerThreadgroup:th];
    [enc endEncoding];
    [cb commit];
    [cb waitUntilCompleted];
    return 0;
  }
}

static int dispatch_matmul_f32(id<MTLComputePipelineState> pso, id<MTLBuffer> out_b, NSUInteger out_o, id<MTLBuffer> a_b, NSUInteger a_o,
                               id<MTLBuffer> b_b, NSUInteger b_o, uint32_t m, uint32_t k, uint32_t n) {
  uint64_t total = (uint64_t)m * (uint64_t)n;
  if (total == 0) return 0;
  if (total > (uint64_t)UINTPTR_MAX) return 1;
  @autoreleasepool {
    id<MTLCommandBuffer> cb = [g_ctx.q commandBuffer];
    if (!cb) return 1;
    id<MTLComputeCommandEncoder> enc = [cb computeCommandEncoder];
    if (!enc) return 1;
    [enc setComputePipelineState:pso];
    [enc setBuffer:a_b offset:a_o atIndex:0];
    [enc setBuffer:b_b offset:b_o atIndex:1];
    [enc setBuffer:out_b offset:out_o atIndex:2];
    [enc setBytes:&m length:sizeof(m) atIndex:3];
    [enc setBytes:&k length:sizeof(k) atIndex:4];
    [enc setBytes:&n length:sizeof(n) atIndex:5];

    MTLSize grid = MTLSizeMake((NSUInteger)total, 1, 1);
    NSUInteger tg = pso.maxTotalThreadsPerThreadgroup;
    if (tg == 0) tg = 1;
    if (tg > (NSUInteger)total) tg = (NSUInteger)total;
    MTLSize th = MTLSizeMake(tg, 1, 1);
    [enc dispatchThreads:grid threadsPerThreadgroup:th];
    [enc endEncoding];
    [cb commit];
    [cb waitUntilCompleted];
    return 0;
  }
}

int aster_metal_buf_alloc(uint64_t nbytes, void** out_base, void** out_data) {
  if (!out_base || !out_data) return 1;
  *out_base = NULL;
  *out_data = NULL;
  if (aster_metal_init_devq() != 0) return 1;
  @autoreleasepool {
    // Shared storage so Aster can read/write via `contents`.
    id<MTLBuffer> buf = [g_ctx.dev newBufferWithLength:(NSUInteger)nbytes options:MTLResourceStorageModeShared];
    if (!buf) return 1;
#if __has_feature(objc_arc)
    // Under ARC, transfer ownership of `buf` to the opaque handle so it
    // doesn't get released when `buf` goes out of scope.
    *out_base = (void*)CFBridgingRetain(buf);
#else
    // MRC: `newBufferWithLength` returns retained (+1). Caller frees via
    // `aster_metal_buf_free`, which sends `release`.
    *out_base = (__bridge void*)buf;
#endif
    *out_data = [buf contents];
    return (*out_data != NULL) ? 0 : 1;
  }
}

void aster_metal_buf_free(void* base) {
  if (!base) return;
  @autoreleasepool {
#if __has_feature(objc_arc)
    CFRelease((CFTypeRef)base);
#else
    id obj = (__bridge id)base;
    [obj release];
#endif
  }
}

int aster_metal_add_f32(void* out_base, uint64_t out_off, void* a_base, uint64_t a_off, void* b_base, uint64_t b_off, uint64_t n) {
  if (aster_metal_init_devq() != 0) return 1;
  if (aster_metal_ensure_pso(&g_ctx.add_f32, "add_f32") != 0) return 1;
  return dispatch_1d(g_ctx.add_f32, (__bridge id<MTLBuffer>)a_base, (NSUInteger)a_off, (__bridge id<MTLBuffer>)b_base, (NSUInteger)b_off,
                     (__bridge id<MTLBuffer>)out_base, (NSUInteger)out_off, n, 3);
}

int aster_metal_mul_f32(void* out_base, uint64_t out_off, void* a_base, uint64_t a_off, void* b_base, uint64_t b_off, uint64_t n) {
  if (aster_metal_init_devq() != 0) return 1;
  if (aster_metal_ensure_pso(&g_ctx.mul_f32, "mul_f32") != 0) return 1;
  return dispatch_1d(g_ctx.mul_f32, (__bridge id<MTLBuffer>)a_base, (NSUInteger)a_off, (__bridge id<MTLBuffer>)b_base, (NSUInteger)b_off,
                     (__bridge id<MTLBuffer>)out_base, (NSUInteger)out_off, n, 3);
}

int aster_metal_relu_f32(void* out_base, uint64_t out_off, void* a_base, uint64_t a_off, uint64_t n) {
  if (aster_metal_init_devq() != 0) return 1;
  if (aster_metal_ensure_pso(&g_ctx.relu_f32, "relu_f32") != 0) return 1;
  return dispatch_1d(g_ctx.relu_f32, (__bridge id<MTLBuffer>)a_base, (NSUInteger)a_off, (__bridge id<MTLBuffer>)out_base, (NSUInteger)out_off, NULL, 0, n, 2);
}

int aster_metal_matmul_f32(void* out_base, uint64_t out_off, void* a_base, uint64_t a_off, void* b_base, uint64_t b_off, uint64_t m,
                           uint64_t k, uint64_t n) {
  if (aster_metal_init_devq() != 0) return 1;
  if (aster_metal_ensure_pso(&g_ctx.matmul_f32, "matmul_f32") != 0) return 1;
  if (m > UINT32_MAX || n > UINT32_MAX || k > UINT32_MAX) return 1;
  if (m != 0 && n > (UINT32_MAX / m)) return 1;  // gid is `uint` (32-bit)
  return dispatch_matmul_f32(g_ctx.matmul_f32, (__bridge id<MTLBuffer>)out_base, (NSUInteger)out_off, (__bridge id<MTLBuffer>)a_base, (NSUInteger)a_off,
                             (__bridge id<MTLBuffer>)b_base, (NSUInteger)b_off, (uint32_t)m, (uint32_t)k, (uint32_t)n);
}
