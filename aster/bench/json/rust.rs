const REPS: usize = 20000;
const JSON_TEXT: &str = "{\"id\":123,\"name\":\"alpha\",\"val\":456,\"flag\":true}";

fn parse_one(bytes: &[u8]) -> u64 {
    let mut sum: u64 = 0;
    let mut i: usize = 0;
    while i < bytes.len() {
        let c = bytes[i];
        if c == b'"' {
            i += 1;
            while i < bytes.len() {
                let d = bytes[i];
                if d == b'"' {
                    break;
                }
                sum += 1;
                i += 1;
            }
        } else if c >= b'0' && c <= b'9' {
            let mut num: u64 = 0;
            while i < bytes.len() {
                let d = bytes[i];
                if d < b'0' || d > b'9' {
                    break;
                }
                num = num * 10 + (d - b'0') as u64;
                i += 1;
            }
            sum += num;
            continue;
        }
        i += 1;
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
