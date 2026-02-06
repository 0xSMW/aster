const N: usize = 200000;
const CAP: usize = 1048576;
const LCG_A: u64 = 6364136223846793005;
const LCG_C: u64 = 1;
const LOOKUP_SCALE: usize = 25;

#[inline]
fn hash_u64(key: u64) -> usize {
    let mut x = key;
    x ^= x >> 33;
    x = x.wrapping_mul(0xff51afd7ed558ccd);
    x ^= x >> 33;
    (x as usize) & (CAP - 1)
}

fn map_put(keys: &mut [u64], vals: &mut [u64], key: u64, val: u64) {
    let mut idx = hash_u64(key);
    loop {
        let cur = keys[idx];
        if cur == 0 || cur == key {
            keys[idx] = key;
            vals[idx] = val;
            return;
        }
        idx = (idx + 1) & (CAP - 1);
    }
}

fn map_get(keys: &[u64], vals: &[u64], key: u64) -> u64 {
    let mut idx = hash_u64(key);
    loop {
        let cur = keys[idx];
        if cur == 0 {
            return 0;
        }
        if cur == key {
            return vals[idx];
        }
        idx = (idx + 1) & (CAP - 1);
    }
}

fn main() {
    let mut keys = vec![0u64; CAP];
    let mut vals = vec![0u64; CAP];

    let mut seed: u64 = 1;
    for i in 0..N {
        seed = seed.wrapping_mul(LCG_A).wrapping_add(LCG_C);
        let key = seed | 1;
        map_put(&mut keys, &mut vals, key, i as u64);
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
            total = total.wrapping_add(map_get(&keys, &vals, key));
        }
    }

    println!("{}", total);
}
