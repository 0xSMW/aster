# Aster JSON parse benchmark (Aster0 subset)

const REPS is usize = 20000
const JSON_TEXT is String = "{\"id\":123,\"name\":\"alpha\",\"val\":456,\"flag\":true}"

extern def strlen(s is String) returns usize
extern def printf(fmt is String, a is u64) returns i32

# parse a single JSON object string and accumulate digits/strings

def parse_one(s is String, len is usize) returns u64
    var p is String = s
    var end is String = s + len
    var sum is u64 = 0
    while p < end do
        if (p + 8) <= end then
            var c0 is u8 = p[0]
            var c1 is u8 = p[1]
            var c2 is u8 = p[2]
            var c3 is u8 = p[3]
            var c4 is u8 = p[4]
            var c5 is u8 = p[5]
            var c6 is u8 = p[6]
            var c7 is u8 = p[7]
            var hit is i32 = 0
            if c0 == 34 or (c0 >= 48 and c0 <= 57) then
                hit = 1
            else if c1 == 34 or (c1 >= 48 and c1 <= 57) then
                hit = 1
            else if c2 == 34 or (c2 >= 48 and c2 <= 57) then
                hit = 1
            else if c3 == 34 or (c3 >= 48 and c3 <= 57) then
                hit = 1
            else if c4 == 34 or (c4 >= 48 and c4 <= 57) then
                hit = 1
            else if c5 == 34 or (c5 >= 48 and c5 <= 57) then
                hit = 1
            else if c6 == 34 or (c6 >= 48 and c6 <= 57) then
                hit = 1
            else if c7 == 34 or (c7 >= 48 and c7 <= 57) then
                hit = 1
            if hit == 0 then
                p = p + 8
                continue
        var c is u8 = p[0]
        if c == 34 then
            p = p + 1
            while p < end do
                var d is u8 = p[0]
                if d == 34 then
                    break
                sum = sum + 1
                p = p + 1
        else if c >= 48 and c <= 57 then
            var num is u64 = 0
            while (p + 4) <= end do
                var d0 is u8 = p[0]
                var d1 is u8 = p[1]
                var d2 is u8 = p[2]
                var d3 is u8 = p[3]
                if d0 < 48 or d0 > 57 or d1 < 48 or d1 > 57 or d2 < 48 or d2 > 57 or d3 < 48 or d3 > 57 then
                    break
                num = num * 10000 + (d0 - 48) * 1000 + (d1 - 48) * 100 + (d2 - 48) * 10 + (d3 - 48)
                p = p + 4
            while p < end do
                var d2 is u8 = p[0]
                if d2 < 48 or d2 > 57 then
                    break
                num = num * 10 + (d2 - 48)
                p = p + 1
            sum = sum + num
            continue
        p = p + 1
    return sum

# entry

def main() returns i32
    var len is usize = strlen(JSON_TEXT)
    var rep is usize = 0
    var total is u64 = 0
    while rep < REPS do
        total = total + parse_one(JSON_TEXT, len)
        rep = rep + 1
    printf("%llu\n", total)
    return 0
