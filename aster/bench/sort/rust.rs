use std::io::{self, Write};

const N: usize = 200000;
const LCG_A: u64 = 6364136223846793005;
const LCG_C: u64 = 1;
const RADIX_BITS: u32 = 11;
const RADIX: usize = 2048;
const RADIX_MASK: u64 = 2047;
const PASSES: usize = 6;

#[inline(always)]
fn radix_sort_ws(a: &mut [u64], tmp: &mut [u64], counts: &mut [u32; RADIX]) {
    let n = a.len();
    if n < 2 {
        return;
    }

    // Track which buffer holds the live data to avoid borrowing `a` again while
    // it is already mutably borrowed through `src`/`dst`.
    let mut src_is_a = true;
    let mut src: &mut [u64] = a;
    let mut dst: &mut [u64] = tmp;
    let mut shift: u32 = 0;

    for _pass in 0..PASSES {
        counts.fill(0);

        for &key in src.iter() {
            let idx = ((key >> shift) & RADIX_MASK) as usize;
            // Hot path: avoid bounds checks in the count array.
            unsafe {
                let p = counts.get_unchecked_mut(idx);
                *p = p.wrapping_add(1);
            }
        }

        let mut sum: u32 = 0;
        for c in counts.iter_mut() {
            sum = sum.wrapping_add(*c);
            *c = sum;
        }

        // Backward scatter for stability.
        for i in (0..n).rev() {
            let key = unsafe { *src.get_unchecked(i) };
            let idx = ((key >> shift) & RADIX_MASK) as usize;
            unsafe {
                let c = counts.get_unchecked_mut(idx);
                *c = c.wrapping_sub(1);
                *dst.get_unchecked_mut(*c as usize) = key;
            }
        }

        std::mem::swap(&mut src, &mut dst);
        src_is_a = !src_is_a;
        shift += RADIX_BITS;
    }

    // After an odd number of passes, the sorted data lives in `tmp` (src) and
    // `dst` points back at `a`.
    if !src_is_a {
        dst.copy_from_slice(src);
    }
}

fn main() {
    let mut data = vec![0u64; N];
    let mut tmp = vec![0u64; N];
    let mut counts = [0u32; RADIX];
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
        radix_sort_ws(&mut data, &mut tmp, &mut counts);
        total = total.wrapping_add(data[0]);
    }
    let mut out = io::BufWriter::new(io::stdout());
    writeln!(out, "{}", total).ok();
}
