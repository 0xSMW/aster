fn main() {
    let w: usize = 512;
    let h: usize = 512;
    let reps: usize = 3;
    let total = w * h;
    let mut input = vec![1.0_f64; total];
    let mut output = vec![0.0_f64; total];

    let w0 = 0.5_f64;
    let w1 = 0.125_f64;

    for _ in 0..reps {
        for i in 1..(h - 1) {
            for j in 1..(w - 1) {
                let idx = i * w + j;
                let center = input[idx] * w0;
                let sum = input[idx - w] + input[idx + w] + input[idx - 1] + input[idx + 1];
                output[idx] = center + sum * w1;
            }
        }
        std::mem::swap(&mut input, &mut output);
    }

    println!("{}", input[0]);
}
