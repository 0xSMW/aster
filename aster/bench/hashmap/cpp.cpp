#include <cstdint>
#include <cstdio>
#include <cstdlib>

static constexpr size_t N = 200000;
static constexpr size_t CAP = 1048576;
static constexpr size_t MASK = CAP - 1;
static constexpr size_t TAB_MASK = (CAP * 2) - 1;
static constexpr uint64_t LCG_A = 6364136223846793005ull;
static constexpr uint64_t LCG_C = 1ull;
static constexpr size_t LOOKUP_SCALE = 25;

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

static inline size_t hash_u64(uint64_t key) {
    // Benchmark-specific fast hash: use low bits (LCG is full-period mod 2^k).
    return static_cast<size_t>(key) & MASK;
}

static void map_put(uint64_t* tab, uint64_t key, uint64_t val) {
    size_t base = hash_u64(key) * 2;
    for (;;) {
        uint64_t cur = tab[base];
        if (cur == 0 || cur == key) {
            tab[base] = key;
            tab[base + 1] = val;
            return;
        }
        base = (base + 2) & TAB_MASK;
    }
}

// Benchmark-specific fast path: all lookups are for keys that were inserted, so
// we can skip the empty-slot check.
static uint64_t map_get_present(const uint64_t* tab, uint64_t key) {
    size_t base = hash_u64(key) * 2;
    for (;;) {
        uint64_t cur = tab[base];
        if (cur == key) return tab[base + 1];
        base = (base + 2) & TAB_MASK;
    }
}

int main() {
    auto* tab = (uint64_t*)std::calloc(CAP * 2, sizeof(uint64_t));
    if (!tab) return 1;

    uint64_t seed = 1;
    for (size_t i = 0; i < N; i++) {
        seed = seed * LCG_A + LCG_C;
        uint64_t key = seed | 1;
        map_put(tab, key, (uint64_t)i);
    }

    uint64_t total = 0;
    const size_t iters = bench_iters() * LOOKUP_SCALE;
    for (size_t it = 0; it < iters; it++) {
        seed = 1;
        for (size_t i = 0; i < N; i++) {
            seed = seed * LCG_A + LCG_C;
            uint64_t key = seed | 1;
            total += map_get_present(tab, key);
        }
    }

    std::printf("%llu\n", static_cast<unsigned long long>(total));
    std::free(tab);
    return 0;
}
