#include <cstdint>
#include <cstdio>

static constexpr size_t N = 200000;
static constexpr size_t CAP = 1048576;
static constexpr uint64_t LCG_A = 6364136223846793005ull;
static constexpr uint64_t LCG_C = 1ull;

static inline size_t hash_u64(uint64_t key) {
    uint64_t x = key;
    x ^= x >> 33;
    x *= 0xff51afd7ed558ccdULL;
    x ^= x >> 33;
    return static_cast<size_t>(x) & (CAP - 1);
}

static void map_put(uint64_t* keys, uint64_t* vals, uint64_t key, uint64_t val) {
    size_t idx = hash_u64(key);
    for (;;) {
        uint64_t cur = keys[idx];
        if (cur == 0 || cur == key) {
            keys[idx] = key;
            vals[idx] = val;
            return;
        }
        idx = (idx + 1) & (CAP - 1);
    }
}

static uint64_t map_get(uint64_t* keys, uint64_t* vals, uint64_t key) {
    size_t idx = hash_u64(key);
    for (;;) {
        uint64_t cur = keys[idx];
        if (cur == 0) return 0;
        if (cur == key) return vals[idx];
        idx = (idx + 1) & (CAP - 1);
    }
}

int main() {
    auto* keys = new uint64_t[CAP]();
    auto* vals = new uint64_t[CAP]();

    uint64_t seed = 1;
    for (size_t i = 0; i < N; i++) {
        seed = seed * LCG_A + LCG_C;
        uint64_t key = seed | 1;
        map_put(keys, vals, key, i);
    }

    uint64_t total = 0;
    seed = 1;
    for (size_t i = 0; i < N; i++) {
        seed = seed * LCG_A + LCG_C;
        uint64_t key = seed | 1;
        total += map_get(keys, vals, key);
    }

    std::printf("%llu\n", static_cast<unsigned long long>(total));
    delete[] keys;
    delete[] vals;
    return 0;
}
