fn bench_iters() -> usize {
    std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1)
}

#[inline(always)]
fn dot_u8(a: &[f64], b: &[f64]) -> f64 {
    let n = a.len();
    debug_assert_eq!(n, b.len());

    let pa = a.as_ptr();
    let pb = b.as_ptr();

    let mut sum0 = 0.0_f64;
    let mut sum1 = 0.0_f64;
    let mut sum2 = 0.0_f64;
    let mut sum3 = 0.0_f64;
    let mut sum4 = 0.0_f64;
    let mut sum5 = 0.0_f64;
    let mut sum6 = 0.0_f64;
    let mut sum7 = 0.0_f64;

    let mut i: usize = 0;
    let n8 = n & !7usize;
    unsafe {
        while i < n8 {
            sum0 += *pa.add(i + 0) * *pb.add(i + 0);
            sum1 += *pa.add(i + 1) * *pb.add(i + 1);
            sum2 += *pa.add(i + 2) * *pb.add(i + 2);
            sum3 += *pa.add(i + 3) * *pb.add(i + 3);
            sum4 += *pa.add(i + 4) * *pb.add(i + 4);
            sum5 += *pa.add(i + 5) * *pb.add(i + 5);
            sum6 += *pa.add(i + 6) * *pb.add(i + 6);
            sum7 += *pa.add(i + 7) * *pb.add(i + 7);
            i += 8;
        }

        let mut sum = ((sum0 + sum1) + (sum2 + sum3)) + ((sum4 + sum5) + (sum6 + sum7));
        while i < n {
            sum += *pa.add(i) * *pb.add(i);
            i += 1;
        }
        sum
    }
}

fn main() {
    let n: usize = 5_000_000;
    let reps: usize = 3;
    let total_reps = reps * bench_iters();
    let a = vec![1.0_f64; n];
    let b = vec![2.0_f64; n];

    let mut sum = 0.0_f64;
    for _ in 0..total_reps {
        sum = dot_u8(&a, &b);
    }

    println!("{}", sum);
}
