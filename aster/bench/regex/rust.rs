const N: usize = 1_000_000;
const LCG_A: u64 = 6364136223846793005;
const LCG_C: u64 = 1;
const LUT_PACK: u32 = 0x7863_6261; // bytes: 'a','b','c','x' (little-endian)

fn main() {
    let iters: usize = std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1);

    let mut total: u64 = 0;
    for _ in 0..iters {
        let mut seed: u64 = 1;
        let mut matches: u64 = 0;
        let mut state: u8 = 0; // 0 = seek 'a'; 1 = after 'a' (consume b* then expect 'c' for a match).
        for _ in 0..N {
            seed = seed.wrapping_mul(LCG_A).wrapping_add(LCG_C);
            let r = ((seed >> 32) & 3) as u32;
            let ch = ((LUT_PACK >> (r << 3)) & 255) as u8;
            if state == 0 {
                if ch == b'a' {
                    state = 1;
                }
            } else if ch == b'c' {
                matches = matches.wrapping_add(1);
                state = 0;
            } else if ch == b'x' {
                state = 0;
            }
        }
        total = total.wrapping_add(matches);
    }
    println!("{}", total);
}
