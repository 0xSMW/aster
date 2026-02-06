const N: usize = 1_000_000;
const LCG_A: u64 = 6364136223846793005;
const LCG_C: u64 = 1;

fn count_matches(buf: &[u8]) -> u64 {
    let mut count: u64 = 0;
    let len = buf.len();
    let mut i: usize = 0;
    while i < len {
        if buf[i] == b'a' {
            let mut j = i + 1;
            while j < len && buf[j] == b'b' {
                j += 1;
            }
            if j < len && buf[j] == b'c' {
                count += 1;
            }
        }
        i += 1;
    }
    count
}

fn main() {
    let mut buf = vec![0u8; N];
    let iters: usize = std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1);

    let mut total: u64 = 0;
    for _ in 0..iters {
        let mut seed: u64 = 1;
        for i in 0..N {
            seed = seed.wrapping_mul(LCG_A).wrapping_add(LCG_C);
            let r = ((seed >> 32) & 3) as u8;
            let ch = match r {
                0 => b'a',
                1 => b'b',
                2 => b'c',
                _ => b'x',
            };
            buf[i] = ch;
        }
        total = total.wrapping_add(count_matches(&buf));
    }
    println!("{}", total);
}
