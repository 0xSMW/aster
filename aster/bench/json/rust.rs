const REPS: usize = 20000;
const JSON_TEXT: &str = "{\"id\":123,\"name\":\"alpha\",\"val\":456,\"flag\":true}";

#[inline(always)]
fn parse_one(bytes: &[u8]) -> u64 {
    let mut sum: u64 = 0;
    let mut p = bytes.as_ptr();
    let end = unsafe { p.add(bytes.len()) };

    unsafe {
        while p < end {
            // Fast skip: if the next 8 bytes contain no quote or digit, skip them.
            if p.add(8) <= end {
                let c0 = *p.add(0);
                let c1 = *p.add(1);
                let c2 = *p.add(2);
                let c3 = *p.add(3);
                let c4 = *p.add(4);
                let c5 = *p.add(5);
                let c6 = *p.add(6);
                let c7 = *p.add(7);
                let mut hit = false;
                if c0 == b'"' || (c0 >= b'0' && c0 <= b'9') {
                    hit = true;
                } else if c1 == b'"' || (c1 >= b'0' && c1 <= b'9') {
                    hit = true;
                } else if c2 == b'"' || (c2 >= b'0' && c2 <= b'9') {
                    hit = true;
                } else if c3 == b'"' || (c3 >= b'0' && c3 <= b'9') {
                    hit = true;
                } else if c4 == b'"' || (c4 >= b'0' && c4 <= b'9') {
                    hit = true;
                } else if c5 == b'"' || (c5 >= b'0' && c5 <= b'9') {
                    hit = true;
                } else if c6 == b'"' || (c6 >= b'0' && c6 <= b'9') {
                    hit = true;
                } else if c7 == b'"' || (c7 >= b'0' && c7 <= b'9') {
                    hit = true;
                }
                if !hit {
                    p = p.add(8);
                    continue;
                }
            }

            let c = *p;
            if c == b'"' {
                p = p.add(1);
                while p < end {
                    let d = *p;
                    if d == b'"' {
                        break;
                    }
                    sum = sum.wrapping_add(1);
                    p = p.add(1);
                }
            } else if c >= b'0' && c <= b'9' {
                let mut num: u64 = 0;
                while p.add(4) <= end {
                    let d0 = *p.add(0);
                    let d1 = *p.add(1);
                    let d2 = *p.add(2);
                    let d3 = *p.add(3);
                    if d0 < b'0'
                        || d0 > b'9'
                        || d1 < b'0'
                        || d1 > b'9'
                        || d2 < b'0'
                        || d2 > b'9'
                        || d3 < b'0'
                        || d3 > b'9'
                    {
                        break;
                    }
                    num = (num * 10000)
                        + (d0 - b'0') as u64 * 1000
                        + (d1 - b'0') as u64 * 100
                        + (d2 - b'0') as u64 * 10
                        + (d3 - b'0') as u64;
                    p = p.add(4);
                }
                while p < end {
                    let d = *p;
                    if d < b'0' || d > b'9' {
                        break;
                    }
                    num = num * 10 + (d - b'0') as u64;
                    p = p.add(1);
                }
                sum = sum.wrapping_add(num);
                continue;
            }
            p = p.add(1);
        }
    }

    sum
}

fn main() {
    let bytes = JSON_TEXT.as_bytes();
    let iters: usize = std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1);
    let total_reps = REPS * iters;
    let mut total: u64 = 0;
    for _ in 0..total_reps {
        total += parse_one(bytes);
    }
    println!("{}", total);
}
