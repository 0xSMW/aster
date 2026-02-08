#include <cstdint>
#include <cstdio>
#include <cstdlib>

static constexpr size_t N = 1000000;
static constexpr uint64_t LCG_A = 6364136223846793005ull;
static constexpr uint64_t LCG_C = 1ull;
static constexpr uint64_t LUT_PACK = 0x78636261ull;  // bytes: 'a','b','c','x' (little-endian)

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

int main() {
    const size_t iters = bench_iters();
    uint64_t total = 0;
    for (size_t it = 0; it < iters; it++) {
        uint64_t seed = 1;
        uint64_t matches = 0;
        int state = 0;  // 0 = seek 'a'; 1 = after 'a' (consume b* then expect 'c' for a match).
        for (size_t i = 0; i < N; i++) {
            seed = seed * LCG_A + LCG_C;
            uint64_t r = (seed >> 32) & 3ull;
            uint8_t ch = (uint8_t)((LUT_PACK >> (r << 3)) & 255ull);
            if (state == 0) {
                if (ch == (uint8_t)'a') state = 1;
            } else {
                if (ch == (uint8_t)'c') {
                    matches++;
                    state = 0;
                } else if (ch == (uint8_t)'x') {
                    state = 0;
                }
            }
        }
        total += matches;
    }
    std::printf("%llu\n", static_cast<unsigned long long>(total));
    return 0;
}
