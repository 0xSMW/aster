#include <cstdint>
#include <cstdio>
#include <cstdlib>

static constexpr size_t N = 1000000;
static constexpr uint64_t LCG_A = 6364136223846793005ull;
static constexpr uint64_t LCG_C = 1ull;

static uint64_t count_matches(const char* buf, size_t len) {
    uint64_t count = 0;
    for (size_t i = 0; i < len; i++) {
        if (buf[i] == 'a') {
            size_t j = i + 1;
            while (j < len && buf[j] == 'b') {
                j++;
            }
            if (j < len && buf[j] == 'c') {
                count++;
            }
        }
    }
    return count;
}

int main() {
    char* buf = (char*)std::malloc(N);
    if (!buf) return 1;
    uint64_t seed = 1;
    for (size_t i = 0; i < N; i++) {
        seed = seed * LCG_A + LCG_C;
        uint8_t r = static_cast<uint8_t>(seed & 3);
        char ch = 'x';
        if (r == 0) ch = 'a';
        else if (r == 1) ch = 'b';
        else if (r == 2) ch = 'c';
        buf[i] = ch;
    }
    uint64_t matches = count_matches(buf, N);
    std::printf("%llu\n", static_cast<unsigned long long>(matches));
    std::free(buf);
    return 0;
}
