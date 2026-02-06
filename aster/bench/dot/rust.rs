fn main() {
    let n: usize = 5_000_000;
    let reps: usize = 3;
    let a = vec![1.0_f64; n];
    let b = vec![2.0_f64; n];

    let mut sum = 0.0_f64;
    for _ in 0..reps {
        sum = 0.0_f64;
        for i in 0..n {
            sum += a[i] * b[i];
        }
    }

    println!("{}", sum);
}
