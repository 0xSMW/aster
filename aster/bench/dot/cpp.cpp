#include <cstdio>
#include <cstdlib>

int main() {
    const size_t N = 5000000;
    const int REPS = 3;
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
    for (int r = 0; r < REPS; ++r) {
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
