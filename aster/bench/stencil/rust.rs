fn main() {
    let w: usize = 512;
    let h: usize = 512;
    let reps: usize = 3;
    let scale: usize = 20;
    let iters: usize = std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1);
    let total_reps = reps * iters * scale;
    let total = w * h;
    let mut input = vec![1.0_f64; total];
    let mut output = vec![0.0_f64; total];

    let w0 = 0.5_f64;
    let w1 = 0.125_f64;

    for _ in 0..total_reps {
        for i in 1..(h - 1) {
            for j in 1..(w - 1) {
                let idx = i * w + j;
                let center = input[idx] * w0;
                let sum = input[idx - w] + input[idx + w] + input[idx - 1] + input[idx + 1];
                output[idx] = center + sum * w1;
            }
        }
        // Match vDSP_f3x3D semantics: border elements are set to zero each step.
        for j in 0..w {
            output[j] = 0.0;
            output[(h - 1) * w + j] = 0.0;
        }
        for i in 1..(h - 1) {
            output[i * w] = 0.0;
            output[i * w + (w - 1)] = 0.0;
        }
        std::mem::swap(&mut input, &mut output);
    }

    println!("{}", input[0]);
}
