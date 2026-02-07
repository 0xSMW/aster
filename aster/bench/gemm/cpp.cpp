#include <cstdio>
#include <cstdlib>

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

#if defined(__APPLE__)
extern "C" void cblas_dgemm(int Order, int TransA, int TransB, int M, int N, int K, double alpha, const double* A,
                           int lda, const double* B, int ldb, double beta, double* C, int ldc);
static constexpr int CBLAS_ROW_MAJOR = 101;
static constexpr int CBLAS_NO_TRANS = 111;
#endif

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
#if defined(__APPLE__)
        // Match the Aster baseline: use optimized BLAS (Accelerate) for GEMM.
        cblas_dgemm(CBLAS_ROW_MAJOR, CBLAS_NO_TRANS, CBLAS_NO_TRANS, (int)N, (int)N, (int)N, 1.0, a, (int)N, b,
                   (int)N, 0.0, c, (int)N);
#else
        // Portable fallback: blocked GEMM (still faster than naive ijk).
        for (size_t i = 0; i < total; ++i) c[i] = 0.0;
        constexpr size_t BS = 32;
        for (size_t i0 = 0; i0 < N; i0 += BS) {
            for (size_t k0 = 0; k0 < N; k0 += BS) {
                for (size_t j0 = 0; j0 < N; j0 += BS) {
                    const size_t imax = (i0 + BS < N) ? (i0 + BS) : N;
                    const size_t kmax = (k0 + BS < N) ? (k0 + BS) : N;
                    const size_t jmax = (j0 + BS < N) ? (j0 + BS) : N;
                    for (size_t i = i0; i < imax; ++i) {
                        double* c_row = c + i * N;
                        const double* a_row = a + i * N;
                        for (size_t k = k0; k < kmax; ++k) {
                            const double a_val = a_row[k];
                            const double* b_row = b + k * N;
                            for (size_t j = j0; j < jmax; ++j) {
                                c_row[j] += a_val * b_row[j];
                            }
                        }
                    }
                }
            }
        }
#endif
    }

    std::printf("%f\n", c[0]);
    std::free(a);
    std::free(b);
    std::free(c);
    return 0;
}
