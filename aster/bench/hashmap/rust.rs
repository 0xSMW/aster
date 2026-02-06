const N: usize = 200000;
const CAP: usize = 1048576;
const LCG_A: u64 = 6364136223846793005;
const LCG_C: u64 = 1;

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

    let mut total: u64 = 0;
    seed = 1;
    for _ in 0..N {
        seed = seed.wrapping_mul(LCG_A).wrapping_add(LCG_C);
        let key = seed | 1;
        total = total.wrapping_add(map_get(&keys, &vals, key));
    }

    println!("{}", total);
}
