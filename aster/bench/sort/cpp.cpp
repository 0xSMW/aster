#include <array>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

static constexpr size_t N = 200000;
static constexpr uint64_t LCG_A = 6364136223846793005ull;
static constexpr uint64_t LCG_C = 1ull;
static constexpr uint64_t RADIX_BITS = 11;
static constexpr size_t RADIX = 2048;
static constexpr uint64_t RADIX_MASK = 2047;
static constexpr size_t PASSES = 6;

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

static inline void radix_sort_ws(uint64_t* a, size_t n, uint64_t* tmp, uint32_t* counts) {
    if (n < 2) return;

    uint64_t* src = a;
    uint64_t* dst = tmp;
    uint64_t shift = 0;
    for (size_t pass = 0; pass < PASSES; pass++) {
        std::memset(counts, 0, RADIX * sizeof(uint32_t));

        for (size_t i = 0; i < n; i++) {
            uint64_t key = src[i];
            size_t idx = (size_t)((key >> shift) & RADIX_MASK);
            counts[idx] += 1;
        }

        uint32_t sum = 0;
        for (size_t i = 0; i < RADIX; i++) {
            sum += counts[i];
            counts[i] = sum;
        }

        for (size_t i = n; i > 0; i--) {
            uint64_t key = src[i - 1];
            size_t idx = (size_t)((key >> shift) & RADIX_MASK);
            uint32_t pos = --counts[idx];
            dst[pos] = key;
        }

        uint64_t* swap = src;
        src = dst;
        dst = swap;
        shift += RADIX_BITS;
    }

    // With an even number of passes, src == a. Keep a fallback for safety.
    if (src != a) {
        for (size_t i = 0; i < n; i++) {
            a[i] = src[i];
        }
    }
}

int main() {
    std::vector<uint64_t> data(N);
    std::vector<uint64_t> tmp(N);
    std::array<uint32_t, RADIX> counts{};

    const size_t iters = bench_iters();
    uint64_t total = 0;

    for (size_t it = 0; it < iters; it++) {
        uint64_t seed = 1;
        for (size_t i = 0; i < N; i++) {
            seed = seed * LCG_A + LCG_C;
            data[i] = seed;
        }
        radix_sort_ws(data.data(), N, tmp.data(), counts.data());
        total += data[0];
    }

    std::printf("%llu\n", static_cast<unsigned long long>(total));
    return 0;
}
