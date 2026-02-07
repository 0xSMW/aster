use std::io::Write;

const ITERS: usize = 2000;
const CHUNK: usize = 4096;

extern "C" {
    fn pipe(fds: *mut i32) -> i32;
    fn read(fd: i32, buf: *mut u8, count: usize) -> isize;
    fn write(fd: i32, buf: *const u8, count: usize) -> isize;
    fn close(fd: i32) -> i32;
}

fn main() {
    let iters: usize = std::env::var("BENCH_ITERS")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&v| v > 0)
        .unwrap_or(1);
    let total_iters = ITERS * iters;

    let mut fds = [0i32; 2];
    unsafe {
        if pipe(fds.as_mut_ptr()) != 0 {
            return;
        }
    }
    let rfd = fds[0];
    let wfd = fds[1];

    let mut buf = vec![b'a'; CHUNK];
    let mut total: u64 = 0;

    for _ in 0..total_iters {
        unsafe {
            let _ = write(wfd, buf.as_ptr(), CHUNK);
            let n = read(rfd, buf.as_mut_ptr(), CHUNK);
            if n > 0 {
                total += n as u64;
            }
        }
    }

    let mut out = std::io::BufWriter::new(std::io::stdout());
    writeln!(out, "{}", total).ok();

    unsafe {
        close(rfd);
        close(wfd);
    }
}
