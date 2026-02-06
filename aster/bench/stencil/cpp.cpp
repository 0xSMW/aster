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
    const size_t W = 512;
    const size_t H = 512;
    const int REPS = 3;
    const size_t SCALE = 20;
    const size_t total_reps = static_cast<size_t>(REPS) * bench_iters() * SCALE;
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

    for (size_t r = 0; r < total_reps; ++r) {
        for (size_t i = 1; i + 1 < H; ++i) {
            for (size_t j = 1; j + 1 < W; ++j) {
                size_t idx = i * W + j;
                double center = in[idx] * w0;
                double sum = in[idx - W] + in[idx + W] + in[idx - 1] + in[idx + 1];
                out[idx] = center + sum * w1;
            }
        }
        // Match vDSP_f3x3D semantics: border elements are set to zero each step.
        for (size_t j = 0; j < W; ++j) {
            out[j] = 0.0;
            out[(H - 1) * W + j] = 0.0;
        }
        for (size_t i = 1; i + 1 < H; ++i) {
            out[i * W + 0] = 0.0;
            out[i * W + (W - 1)] = 0.0;
        }
        double* tmp = in; in = out; out = tmp;
    }

    std::printf("%f\n", in[0]);
    std::free(in);
    std::free(out);
    return 0;
}
