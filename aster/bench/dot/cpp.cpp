#include <cstdio>
#include <cstdlib>

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

int main() {
    const size_t N = 5000000;
    const int REPS = 3;
    const size_t iters = bench_iters();
    const size_t total_reps = static_cast<size_t>(REPS) * iters;
    double* a = static_cast<double*>(std::malloc(N * sizeof(double)));
    double* b = static_cast<double*>(std::malloc(N * sizeof(double)));
    if (!a || !b) {
        return 1;
    }

    for (size_t i = 0; i < N; ++i) {
        a[i] = 1.0;
        b[i] = 2.0;
    }

    double sum = 0.0;
    for (size_t r = 0; r < total_reps; ++r) {
        sum = 0.0;
        for (size_t i = 0; i < N; ++i) {
            sum += a[i] * b[i];
        }
    }

    std::printf("%f\n", sum);
    std::free(a);
    std::free(b);
    return 0;
}
