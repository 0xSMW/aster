#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cstdlib>

static constexpr size_t REPS = 20000;
static const char* JSON_TEXT = "{\"id\":123,\"name\":\"alpha\",\"val\":456,\"flag\":true}";

static size_t bench_iters() {
    const char* s = std::getenv("BENCH_ITERS");
    if (!s || !*s) return 1;
    long v = std::strtol(s, nullptr, 10);
    if (v <= 0) return 1;
    return static_cast<size_t>(v);
}

static uint64_t parse_one(const char* s, size_t len) {
    uint64_t sum = 0;
    const unsigned char* p = (const unsigned char*)s;
    const unsigned char* end = p + len;
    while (p < end) {
        // Fast skip: if the next 8 bytes contain no quote or digit, skip them.
        if (p + 8 <= end) {
            const unsigned char c0 = p[0];
            const unsigned char c1 = p[1];
            const unsigned char c2 = p[2];
            const unsigned char c3 = p[3];
            const unsigned char c4 = p[4];
            const unsigned char c5 = p[5];
            const unsigned char c6 = p[6];
            const unsigned char c7 = p[7];
            bool hit = false;
            if (c0 == '"' || (c0 >= '0' && c0 <= '9')) hit = true;
            else if (c1 == '"' || (c1 >= '0' && c1 <= '9')) hit = true;
            else if (c2 == '"' || (c2 >= '0' && c2 <= '9')) hit = true;
            else if (c3 == '"' || (c3 >= '0' && c3 <= '9')) hit = true;
            else if (c4 == '"' || (c4 >= '0' && c4 <= '9')) hit = true;
            else if (c5 == '"' || (c5 >= '0' && c5 <= '9')) hit = true;
            else if (c6 == '"' || (c6 >= '0' && c6 <= '9')) hit = true;
            else if (c7 == '"' || (c7 >= '0' && c7 <= '9')) hit = true;
            if (!hit) {
                p += 8;
                continue;
            }
        }

        const unsigned char c = p[0];
        if (c == '"') {
            p++;
            while (p < end) {
                const unsigned char d = p[0];
                if (d == '"') break;
                sum += 1;
                p++;
            }
        } else if (c >= '0' && c <= '9') {
            uint64_t num = 0;
            while (p + 4 <= end) {
                const unsigned char d0 = p[0];
                const unsigned char d1 = p[1];
                const unsigned char d2 = p[2];
                const unsigned char d3 = p[3];
                if (d0 < '0' || d0 > '9' || d1 < '0' || d1 > '9' || d2 < '0' || d2 > '9' || d3 < '0' ||
                    d3 > '9') {
                    break;
                }
                num = (num * 10000) + (uint64_t)(d0 - '0') * 1000 + (uint64_t)(d1 - '0') * 100 +
                      (uint64_t)(d2 - '0') * 10 + (uint64_t)(d3 - '0');
                p += 4;
            }
            while (p < end) {
                const unsigned char d = p[0];
                if (d < '0' || d > '9') break;
                num = num * 10 + (uint64_t)(d - '0');
                p++;
            }
            sum += num;
            continue;
        }
        p++;
    }
    return sum;
}

int main() {
    size_t len = std::strlen(JSON_TEXT);
    uint64_t total = 0;
    const size_t total_reps = REPS * bench_iters();
    for (size_t r = 0; r < total_reps; r++) {
        total += parse_one(JSON_TEXT, len);
    }
    std::printf("%llu\n", static_cast<unsigned long long>(total));
    return 0;
}
