#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>

static constexpr size_t N = 200000;
static constexpr uint64_t LCG_A = 6364136223846793005ull;
static constexpr uint64_t LCG_C = 1ull;

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

int main() {
    std::vector<uint64_t> data(N);
    const size_t iters = bench_iters();
    uint64_t total = 0;

    for (size_t it = 0; it < iters; it++) {
        uint64_t seed = 1;
        for (size_t i = 0; i < N; i++) {
            seed = seed * LCG_A + LCG_C;
            data[i] = seed;
        }
        std::sort(data.begin(), data.end());
        total += data[0];
    }

    std::printf("%llu\n", static_cast<unsigned long long>(total));
    return 0;
}
