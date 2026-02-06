fn main() {
    let n: usize = 128;
    let reps: usize = 2;
    let total = n * n;
    let a = vec![1.0_f64; total];
    let b = vec![2.0_f64; total];
    let mut c = vec![0.0_f64; total];

    for _ in 0..reps {
        for i in 0..total {
            c[i] = 0.0;
        }
        for i in 0..n {
            let c_row = i * n;
            let a_row = i * n;
            for k in 0..n {
                let a_val = a[a_row + k];
                let b_row = k * n;
                for j in 0..n {
                    c[c_row + j] += a_val * b[b_row + j];
                }
            }
        }
    }

    println!("{}", c[0]);
}
