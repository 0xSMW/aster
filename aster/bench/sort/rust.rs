use std::io::{self, Write};

const N: usize = 200000;
const LCG_A: u64 = 6364136223846793005;
const LCG_C: u64 = 1;

fn main() {
    let mut data = vec![0u64; N];
    let mut seed: u64 = 1;
    for i in 0..N {
        seed = seed.wrapping_mul(LCG_A).wrapping_add(LCG_C);
        data[i] = seed;
    }
    data.sort_unstable();
    let mut out = io::BufWriter::new(io::stdout());
    writeln!(out, "{}", data[0]).ok();
}
