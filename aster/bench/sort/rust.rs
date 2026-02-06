use std::io::{self, Write};

const N: usize = 200000;
const LCG_A: u64 = 6364136223846793005;
const LCG_C: u64 = 1;

fn main() {
    let mut data = vec![0u64; N];
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
            data[i] = seed;
        }
        data.sort_unstable();
        total = total.wrapping_add(data[0]);
    }
    let mut out = io::BufWriter::new(io::stdout());
    writeln!(out, "{}", total).ok();
}
