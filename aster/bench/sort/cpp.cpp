#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <vector>

static constexpr size_t N = 200000;
static constexpr uint64_t LCG_A = 6364136223846793005ull;
static constexpr uint64_t LCG_C = 1ull;

int main() {
    std::vector<uint64_t> data;
    data.resize(N);
    uint64_t seed = 1;
    for (size_t i = 0; i < N; i++) {
        seed = seed * LCG_A + LCG_C;
        data[i] = seed;
    }

    std::sort(data.begin(), data.end());
    std::printf("%llu\n", static_cast<unsigned long long>(data[0]));
    return 0;
}
