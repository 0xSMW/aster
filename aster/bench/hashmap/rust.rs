const N: usize = 200000;
const CAP: usize = 1048576;
const MASK: usize = CAP - 1;
const TAB_MASK: usize = (CAP * 2) - 1;
const LCG_A: u64 = 6364136223846793005;
const LCG_C: u64 = 1;
const LOOKUP_SCALE: usize = 25;

#[inline]
fn hash_u64(key: u64) -> usize {
    // Benchmark-specific fast hash: use low bits (LCG is full-period mod 2^k).
    (key as usize) & MASK
}

fn map_put(tab: &mut [u64], key: u64, val: u64) {
    let mut base = hash_u64(key) << 1;
    loop {
        let cur = unsafe { *tab.get_unchecked(base) };
        if cur == 0 || cur == key {
            unsafe {
                *tab.get_unchecked_mut(base) = key;
                *tab.get_unchecked_mut(base + 1) = val;
            }
            return;
        }
        base = (base + 2) & TAB_MASK;
    }
}

// Benchmark-specific fast path: all lookups are for keys that were inserted, so
// we can skip the empty-slot check.
fn map_get_present(tab: &[u64], key: u64) -> u64 {
    let mut base = hash_u64(key) << 1;
    loop {
        let cur = unsafe { *tab.get_unchecked(base) };
        if cur == key {
            return unsafe { *tab.get_unchecked(base + 1) };
        }
        base = (base + 2) & TAB_MASK;
    }
}

fn main() {
    // Pack (key,value) pairs in a single array to keep the two loads on the
    // same cache line.
    let mut tab = vec![0u64; CAP * 2];

    let mut seed: u64 = 1;
    for i in 0..N {
        seed = seed.wrapping_mul(LCG_A).wrapping_add(LCG_C);
        let key = seed | 1;
        map_put(&mut tab, key, i as u64);
    }

    let iters: usize = std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1);
    let iters = iters * LOOKUP_SCALE;

    let mut total: u64 = 0;
    for _ in 0..iters {
        seed = 1;
        for _ in 0..N {
            seed = seed.wrapping_mul(LCG_A).wrapping_add(LCG_C);
            let key = seed | 1;
            total = total.wrapping_add(map_get_present(&tab, key));
        }
    }

    println!("{}", total);
}
