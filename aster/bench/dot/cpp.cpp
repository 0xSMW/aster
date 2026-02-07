#include <cstdio>
#include <cstdlib>

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

static inline double dot_u8(const double* __restrict a, const double* __restrict b, size_t n) {
    double sum0 = 0.0;
    double sum1 = 0.0;
    double sum2 = 0.0;
    double sum3 = 0.0;
    double sum4 = 0.0;
    double sum5 = 0.0;
    double sum6 = 0.0;
    double sum7 = 0.0;

    size_t i = 0;
    const size_t n8 = n & ~static_cast<size_t>(7);
    for (; i < n8; i += 8) {
        sum0 += a[i + 0] * b[i + 0];
        sum1 += a[i + 1] * b[i + 1];
        sum2 += a[i + 2] * b[i + 2];
        sum3 += a[i + 3] * b[i + 3];
        sum4 += a[i + 4] * b[i + 4];
        sum5 += a[i + 5] * b[i + 5];
        sum6 += a[i + 6] * b[i + 6];
        sum7 += a[i + 7] * b[i + 7];
    }

    double sum = (((sum0 + sum1) + (sum2 + sum3)) + ((sum4 + sum5) + (sum6 + sum7)));
    for (; i < n; ++i) {
        sum += a[i] * b[i];
    }
    return sum;
}

int main() {
    const size_t N = 5000000;
    const int REPS = 3;
    const size_t iters = bench_iters();
    const size_t total_reps = static_cast<size_t>(REPS) * iters;

    double* a = nullptr;
    double* b = nullptr;
    if (posix_memalign((void**)&a, 64, N * sizeof(double)) != 0) return 1;
    if (posix_memalign((void**)&b, 64, N * sizeof(double)) != 0) {
        std::free(a);
        return 1;
    }
    if (!a || !b) {
        return 1;
    }

    for (size_t i = 0; i < N; ++i) {
        a[i] = 1.0;
        b[i] = 2.0;
    }

    const double* aa = (const double*)__builtin_assume_aligned(a, 64);
    const double* bb = (const double*)__builtin_assume_aligned(b, 64);

    double sum = 0.0;
    for (size_t r = 0; r < total_reps; ++r) {
        sum = dot_u8(aa, bb, N);
    }

    std::printf("%f\n", sum);
    std::free(a);
    std::free(b);
    return 0;
}
