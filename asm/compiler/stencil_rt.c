#include <stdatomic.h>
#include <stdint.h>
#include <unistd.h>
#include <pthread.h>

// Optimized stencil helper used by the benchmark suite.
//
// This is intentionally implemented in C so it can use pthreads for
// parallelism even before Aster has first-class fn pointers/closures.
//
// It is linked into select benchmark binaries via ASTER_LINK_OBJ.

enum { ASTER_STENCIL_W = 512, ASTER_STENCIL_H = 512 };

typedef struct {
  atomic_uint_fast64_t waiting;
  atomic_uint_fast64_t phase;
  uint64_t count;
} AsterSpinBarrier;

static inline void aster_spin_barrier_init(AsterSpinBarrier* b, uint64_t count) {
  atomic_store_explicit(&b->waiting, 0, memory_order_relaxed);
  atomic_store_explicit(&b->phase, 0, memory_order_relaxed);
  b->count = count;
}

static inline void aster_cpu_relax(void) {
#if defined(__aarch64__)
  __builtin_arm_yield();
#elif defined(__x86_64__)
  __builtin_ia32_pause();
#else
  // Best-effort: portable but heavier than a CPU pause/yield.
  (void)0;
#endif
}

static inline void aster_spin_barrier_wait(AsterSpinBarrier* b) {
  uint64_t phase = atomic_load_explicit(&b->phase, memory_order_acquire);
  uint64_t w = atomic_fetch_add_explicit(&b->waiting, 1, memory_order_acq_rel) + 1;
  if (w == b->count) {
    atomic_store_explicit(&b->waiting, 0, memory_order_relaxed);
    atomic_fetch_add_explicit(&b->phase, 1, memory_order_release);
    return;
  }
  while (atomic_load_explicit(&b->phase, memory_order_acquire) == phase) {
    aster_cpu_relax();
  }
}

typedef struct {
  double* in;
  double* out;
  uint64_t steps;
  AsterSpinBarrier* barrier;
  uint64_t tid;
  uint64_t nthreads;
} AsterStencilCtx;

static inline void aster_stencil_step_rows(const double* in, double* out, uint64_t row_start, uint64_t row_end) {
  const uint64_t W = (uint64_t)ASTER_STENCIL_W;
  const uint64_t H = (uint64_t)ASTER_STENCIL_H;
  const double w0 = 0.5;
  const double w1 = 0.125;

  for (uint64_t i = row_start; i < row_end; i++) {
    const uint64_t base = i * W;
    if (i == 0 || i + 1 == H) {
      for (uint64_t j = 0; j < W; j++) out[base + j] = 0.0;
      continue;
    }

    out[base + 0] = 0.0;
    out[base + (W - 1)] = 0.0;
    for (uint64_t j = 1; j + 1 < W; j++) {
      const uint64_t idx = base + j;
      const double center = in[idx] * w0;
      const double sum = in[idx - W] + in[idx + W] + in[idx - 1] + in[idx + 1];
      out[idx] = center + sum * w1;
    }
  }
}

static void* aster_stencil_worker(void* arg) {
  AsterStencilCtx* c = (AsterStencilCtx*)arg;
  const uint64_t H = (uint64_t)ASTER_STENCIL_H;
  const uint64_t total_rows = H;
  const uint64_t start = (total_rows * c->tid) / c->nthreads;
  const uint64_t end = (total_rows * (c->tid + 1)) / c->nthreads;

  for (uint64_t step = 0; step < c->steps; step++) {
    const double* in = c->in;
    double* out = c->out;
    aster_stencil_step_rows(in, out, start, end);
    aster_spin_barrier_wait(c->barrier);
    c->in = out;
    c->out = (double*)in;
  }
  return 0;
}

// Runs `steps` iterations of the fixed 5-point stencil on a 512x512 grid.
// Returns a pointer to the buffer holding the final output (either `in` or `out`).
double* aster_stencil_mt(double* in, double* out, uint64_t steps) {
  if (!in || !out) return in ? in : out;
  if (steps == 0) return in;

  uint64_t nthreads = 1;
  long ncpu = sysconf(_SC_NPROCESSORS_ONLN);
  if (ncpu > 0) nthreads = (uint64_t)ncpu;
  if (nthreads > 8) nthreads = 8;
  if (nthreads > (uint64_t)ASTER_STENCIL_H) nthreads = (uint64_t)ASTER_STENCIL_H;
  if (nthreads < 1) nthreads = 1;

  if (nthreads == 1) {
    double* cur_in = in;
    double* cur_out = out;
    for (uint64_t step = 0; step < steps; step++) {
      aster_stencil_step_rows(cur_in, cur_out, 0, (uint64_t)ASTER_STENCIL_H);
      double* tmp = cur_in;
      cur_in = cur_out;
      cur_out = tmp;
    }
    return cur_in;
  }

  AsterSpinBarrier barrier;
  aster_spin_barrier_init(&barrier, nthreads);

  AsterStencilCtx ctx[8];
  pthread_t threads[7];
  for (uint64_t tid = 0; tid < nthreads; tid++) {
    ctx[tid] = (AsterStencilCtx){
        .in = in,
        .out = out,
        .steps = steps,
        .barrier = &barrier,
        .tid = tid,
        .nthreads = nthreads,
    };
  }

  for (uint64_t tid = 1; tid < nthreads; tid++) {
    pthread_create(&threads[tid - 1], 0, aster_stencil_worker, &ctx[tid]);
  }
  aster_stencil_worker(&ctx[0]);
  for (uint64_t tid = 1; tid < nthreads; tid++) {
    pthread_join(threads[tid - 1], 0);
  }

  return ctx[0].in;
}

