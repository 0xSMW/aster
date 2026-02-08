#[cfg(target_os = "macos")]
#[link(name = "Accelerate", kind = "framework")]
extern "C" {
    fn cblas_dgemm(
        order: i32,
        transa: i32,
        transb: i32,
        m: i32,
        n: i32,
        k: i32,
        alpha: f64,
        a: *const f64,
        lda: i32,
        b: *const f64,
        ldb: i32,
        beta: f64,
        c: *mut f64,
        ldc: i32,
    );
}

const CBLAS_ROW_MAJOR: i32 = 101;
const CBLAS_NO_TRANS: i32 = 111;

fn main() {
    let n: usize = 128;
    let reps: usize = 2;
    let iters: usize = std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1);
    let total_reps = reps * iters;
    let total = n * n;
    let a = vec![1.0_f64; total];
    let b = vec![2.0_f64; total];
    let mut c = vec![0.0_f64; total];

    for _ in 0..total_reps {
        #[cfg(target_os = "macos")]
        unsafe {
            // Match the Aster baseline: use optimized BLAS (Accelerate) for GEMM.
            cblas_dgemm(
                CBLAS_ROW_MAJOR,
                CBLAS_NO_TRANS,
                CBLAS_NO_TRANS,
                n as i32,
                n as i32,
                n as i32,
                1.0,
                a.as_ptr(),
                n as i32,
                b.as_ptr(),
                n as i32,
                0.0,
                c.as_mut_ptr(),
                n as i32,
            );
        }

        #[cfg(not(target_os = "macos"))]
        {
            // Portable fallback: blocked GEMM (still faster than naive ijk).
            for x in c.iter_mut() {
                *x = 0.0;
            }
            const BS: usize = 32;
            let mut i0 = 0;
            while i0 < n {
                let imax = (i0 + BS).min(n);
                let mut k0 = 0;
                while k0 < n {
                    let kmax = (k0 + BS).min(n);
                    let mut j0 = 0;
                    while j0 < n {
                        let jmax = (j0 + BS).min(n);
                        for i in i0..imax {
                            let c_row = i * n;
                            let a_row = i * n;
                            for k in k0..kmax {
                                let a_val = a[a_row + k];
                                let b_row = k * n;
                                for j in j0..jmax {
                                    c[c_row + j] += a_val * b[b_row + j];
                                }
                            }
                        }
                        j0 += BS;
                    }
                    k0 += BS;
                }
                i0 += BS;
            }
        }
    }

    println!("{}", c[0]);
}
