#include <cstdint>
#include <cstdio>
#include <cstring>

static constexpr size_t REPS = 20000;
static const char* JSON_TEXT = "{\"id\":123,\"name\":\"alpha\",\"val\":456,\"flag\":true}";

static uint64_t parse_one(const char* s, size_t len) {
    uint64_t sum = 0;
    size_t i = 0;
    while (i < len) {
        unsigned char c = static_cast<unsigned char>(s[i]);
        if (c == '"') {
            i++;
            while (i < len) {
                unsigned char d = static_cast<unsigned char>(s[i]);
                if (d == '"') break;
                sum += 1;
                i++;
            }
        } else if (c >= '0' && c <= '9') {
            uint64_t num = 0;
            while (i < len) {
                unsigned char d = static_cast<unsigned char>(s[i]);
                if (d < '0' || d > '9') break;
                num = num * 10 + (d - '0');
                i++;
            }
            sum += num;
            continue;
        }
        i++;
    }
    return sum;
}

int main() {
    size_t len = std::strlen(JSON_TEXT);
    uint64_t total = 0;
    for (size_t r = 0; r < REPS; r++) {
        total += parse_one(JSON_TEXT, len);
    }
    std::printf("%llu\n", static_cast<unsigned long long>(total));
    return 0;
}
