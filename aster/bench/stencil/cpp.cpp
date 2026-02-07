#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <pthread.h>
#include <unistd.h>

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

struct SpinBarrier {
    std::atomic<uint64_t> waiting;
    std::atomic<uint64_t> phase;
    uint64_t count;
};

static inline void spin_barrier_init(SpinBarrier* b, uint64_t count) {
    b->waiting.store(0, std::memory_order_relaxed);
    b->phase.store(0, std::memory_order_relaxed);
    b->count = count;
}

static inline void cpu_relax() {
#if defined(__aarch64__)
    __builtin_arm_yield();
#elif defined(__x86_64__)
    __builtin_ia32_pause();
#else
    (void)0;
#endif
}

static inline void spin_barrier_wait(SpinBarrier* b) {
    uint64_t phase = b->phase.load(std::memory_order_acquire);
    uint64_t w = b->waiting.fetch_add(1, std::memory_order_acq_rel) + 1;
    if (w == b->count) {
        b->waiting.store(0, std::memory_order_relaxed);
        b->phase.fetch_add(1, std::memory_order_release);
        return;
    }
    while (b->phase.load(std::memory_order_acquire) == phase) {
        cpu_relax();
    }
}

static inline void stencil_step_rows(const double* in, double* out, uint64_t row_start, uint64_t row_end) {
    const uint64_t W = 512;
    const uint64_t H = 512;
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

struct StencilCtx {
    double* in;
    double* out;
    uint64_t steps;
    SpinBarrier* barrier;
    uint64_t tid;
    uint64_t nthreads;
};

static void* stencil_worker(void* arg) {
    auto* c = (StencilCtx*)arg;
    const uint64_t H = 512;
    const uint64_t total_rows = H;
    const uint64_t start = (total_rows * c->tid) / c->nthreads;
    const uint64_t end = (total_rows * (c->tid + 1)) / c->nthreads;

    for (uint64_t step = 0; step < c->steps; step++) {
        const double* in = c->in;
        double* out = c->out;
        stencil_step_rows(in, out, start, end);
        spin_barrier_wait(c->barrier);
        c->in = out;
        c->out = (double*)in;
    }
    return nullptr;
}

// Runs `steps` iterations of the fixed 5-point stencil on a 512x512 grid.
// Returns a pointer to the buffer holding the final output (either `in` or `out`).
static double* stencil_mt(double* in, double* out, uint64_t steps) {
    if (!in || !out) return in ? in : out;
    if (steps == 0) return in;

    uint64_t nthreads = 1;
    long ncpu = sysconf(_SC_NPROCESSORS_ONLN);
    if (ncpu > 0) nthreads = (uint64_t)ncpu;
    if (nthreads > 8) nthreads = 8;
    if (nthreads > 512) nthreads = 512;
    if (nthreads < 1) nthreads = 1;

    if (nthreads == 1) {
        double* cur_in = in;
        double* cur_out = out;
        for (uint64_t step = 0; step < steps; step++) {
            stencil_step_rows(cur_in, cur_out, 0, 512);
            double* tmp = cur_in;
            cur_in = cur_out;
            cur_out = tmp;
        }
        return cur_in;
    }

    SpinBarrier barrier;
    spin_barrier_init(&barrier, nthreads);

    StencilCtx ctx[8];
    pthread_t threads[7];
    for (uint64_t tid = 0; tid < nthreads; tid++) {
        ctx[tid] = (StencilCtx){
            .in = in,
            .out = out,
            .steps = steps,
            .barrier = &barrier,
            .tid = tid,
            .nthreads = nthreads,
        };
    }

    for (uint64_t tid = 1; tid < nthreads; tid++) {
        pthread_create(&threads[tid - 1], nullptr, stencil_worker, &ctx[tid]);
    }
    (void)stencil_worker(&ctx[0]);
    for (uint64_t tid = 1; tid < nthreads; tid++) {
        pthread_join(threads[tid - 1], nullptr);
    }

    return ctx[0].in;
}

int main() {
    const size_t W = 512;
    const size_t H = 512;
    const int REPS = 3;
    const size_t SCALE = 20;
    const uint64_t total_reps = static_cast<uint64_t>(REPS) * static_cast<uint64_t>(bench_iters()) * (uint64_t)SCALE;
    const size_t total = W * H;
    double* in = static_cast<double*>(std::malloc(total * sizeof(double)));
    double* out = static_cast<double*>(std::malloc(total * sizeof(double)));
    if (!in || !out) return 1;

    for (size_t i = 0; i < total; ++i) {
        in[i] = 1.0;
        out[i] = 0.0;
    }

    const double w0 = 0.5;
    const double w1 = 0.125;

    (void)w0;
    (void)w1;
    double* result = stencil_mt(in, out, total_reps);
    std::printf("%f\n", result ? result[0] : 0.0);
    std::free(in);
    std::free(out);
    return 0;
}
