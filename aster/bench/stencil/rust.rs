use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;

const W: usize = 512;
const H: usize = 512;
const REPS: u64 = 3;
const SCALE: u64 = 20;

fn bench_iters() -> u64 {
    std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<u64>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1)
}

struct SpinBarrier {
    waiting: AtomicU64,
    phase: AtomicU64,
    count: u64,
}

impl SpinBarrier {
    fn new(count: u64) -> Self {
        Self {
            waiting: AtomicU64::new(0),
            phase: AtomicU64::new(0),
            count,
        }
    }

    #[inline(always)]
    fn wait(&self) {
        let phase = self.phase.load(Ordering::Acquire);
        let w = self.waiting.fetch_add(1, Ordering::AcqRel) + 1;
        if w == self.count {
            self.waiting.store(0, Ordering::Relaxed);
            self.phase.fetch_add(1, Ordering::Release);
            return;
        }
        while self.phase.load(Ordering::Acquire) == phase {
            std::hint::spin_loop();
        }
    }
}

#[inline(always)]
unsafe fn stencil_step_rows(in_ptr: *const f64, out_ptr: *mut f64, row_start: usize, row_end: usize) {
    let w0 = 0.5_f64;
    let w1 = 0.125_f64;

    for i in row_start..row_end {
        let base = i * W;
        if i == 0 || i + 1 == H {
            for j in 0..W {
                *out_ptr.add(base + j) = 0.0;
            }
            continue;
        }

        *out_ptr.add(base + 0) = 0.0;
        *out_ptr.add(base + (W - 1)) = 0.0;
        for j in 1..(W - 1) {
            let idx = base + j;
            let center = *in_ptr.add(idx) * w0;
            let sum = *in_ptr.add(idx - W)
                + *in_ptr.add(idx + W)
                + *in_ptr.add(idx - 1)
                + *in_ptr.add(idx + 1);
            *out_ptr.add(idx) = center + sum * w1;
        }
    }
}

fn stencil_mt(in_ptr: *mut f64, out_ptr: *mut f64, steps: u64) -> *mut f64 {
    if steps == 0 {
        return in_ptr;
    }

    let mut nthreads = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(1);
    if nthreads > 8 {
        nthreads = 8;
    }
    if nthreads > H {
        nthreads = H;
    }
    if nthreads < 1 {
        nthreads = 1;
    }

    if nthreads == 1 {
        let mut cur_in = in_ptr;
        let mut cur_out = out_ptr;
        for _ in 0..steps {
            unsafe { stencil_step_rows(cur_in, cur_out, 0, H) };
            std::mem::swap(&mut cur_in, &mut cur_out);
        }
        return cur_in;
    }

    let barrier = Arc::new(SpinBarrier::new(nthreads as u64));

    let mut handles = Vec::with_capacity(nthreads - 1);
    for tid in 1..nthreads {
        let barrier = barrier.clone();
        // `*mut T` is not `Send` on stable Rust; shuttle pointers as integers.
        let mut local_in = in_ptr as usize;
        let mut local_out = out_ptr as usize;
        handles.push(std::thread::spawn(move || {
            let start = (H * tid) / nthreads;
            let end = (H * (tid + 1)) / nthreads;
            for _ in 0..steps {
                let in_p = local_in as *const f64;
                let out_p = local_out as *mut f64;
                unsafe { stencil_step_rows(in_p, out_p, start, end) };
                barrier.wait();
                std::mem::swap(&mut local_in, &mut local_out);
            }
        }));
    }

    // Use the main thread as worker 0.
    let mut local_in = in_ptr;
    let mut local_out = out_ptr;
    let start = 0;
    let end = (H * 1) / nthreads;
    for _ in 0..steps {
        unsafe { stencil_step_rows(local_in, local_out, start, end) };
        barrier.wait();
        std::mem::swap(&mut local_in, &mut local_out);
    }

    for h in handles {
        let _ = h.join();
    }

    local_in
}

fn main() {
    let steps = REPS * bench_iters() * SCALE;
    let total = W * H;
    let mut input = vec![1.0_f64; total];
    let mut output = vec![0.0_f64; total];

    let result_ptr = stencil_mt(input.as_mut_ptr(), output.as_mut_ptr(), steps);
    let result0 = unsafe { *result_ptr };
    println!("{}", result0);
}
