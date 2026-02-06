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
    const size_t N = 128;
    const int REPS = 2;
    const size_t total_reps = static_cast<size_t>(REPS) * bench_iters();
    const size_t total = N * N;
    double* a = static_cast<double*>(std::malloc(total * sizeof(double)));
    double* b = static_cast<double*>(std::malloc(total * sizeof(double)));
    double* c = static_cast<double*>(std::malloc(total * sizeof(double)));
    if (!a || !b || !c) return 1;

    for (size_t i = 0; i < total; ++i) {
        a[i] = 1.0;
        b[i] = 2.0;
        c[i] = 0.0;
    }

    for (size_t r = 0; r < total_reps; ++r) {
        for (size_t i = 0; i < total; ++i) c[i] = 0.0;
        for (size_t i = 0; i < N; ++i) {
            double* c_row = c + i * N;
            double* a_row = a + i * N;
            for (size_t k = 0; k < N; ++k) {
                double a_val = a_row[k];
                double* b_row = b + k * N;
                for (size_t j = 0; j < N; ++j) {
                    c_row[j] += a_val * b_row[j];
                }
            }
        }
    }

    std::printf("%f\n", c[0]);
    std::free(a);
    std::free(b);
    std::free(c);
    return 0;
}
