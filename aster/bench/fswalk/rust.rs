use std::env;
use std::ffi::OsStr;
use std::fs;
use std::os::unix::ffi::OsStrExt;
use std::path::PathBuf;
use std::sync::Arc;

const HASH_OFFSET: u64 = 1469598103934665603;
const HASH_PRIME: u64 = 1099511628211;

fn hash_bytes(hash: &mut u64, bytes: &[u8]) -> usize {
    for &b in bytes {
        *hash ^= b as u64;
        *hash = hash.wrapping_mul(HASH_PRIME);
    }
    bytes.len()
}

fn read_env_int(name: &str, default: i32) -> i32 {
    match env::var(name) {
        Ok(val) => val.parse::<i32>().unwrap_or(default),
        Err(_) => default,
    }
}

fn read_env_bool(name: &str, default: bool) -> bool {
    match env::var(name) {
        Ok(val) => val.parse::<i32>().map(|v| v != 0).unwrap_or(default),
        Err(_) => default,
    }
}

fn read_env_str(name: &str) -> Option<String> {
    env::var(name).ok()
}

fn clamp_threads(mut n: usize) -> usize {
    if n < 1 {
        n = 1;
    }
    if n > 32 {
        n = 32;
    }
    n
}

fn default_threads() -> usize {
    let mut n = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(1);
    if n > 8 {
        n = 8;
    }
    n
}

fn read_lines_file(path: &str) -> Option<(Arc<Vec<u8>>, Arc<Vec<usize>>)> {
    let mut buf = fs::read(path).ok()?;
    let read = buf.len();
    buf.push(0);

    // Normalize newlines to '\0' separators.
    for b in &mut buf[..read] {
        if *b == b'\n' || *b == b'\r' {
            *b = 0;
        }
    }

    let mut starts: Vec<usize> = Vec::new();
    for i in 0..read {
        if buf[i] != 0 && (i == 0 || buf[i - 1] == 0) {
            starts.push(i);
        }
    }

    Some((Arc::new(buf), Arc::new(starts)))
}

fn fswalk_list(
    list_path: &str,
    follow: bool,
    count_only: bool,
    inventory: bool,
    links: &mut u64,
    name_bytes: &mut u64,
    name_hash: &mut u64,
) -> (u64, u64, u64) {
    let Some((buf, starts)) = read_lines_file(list_path) else {
        if inventory {
            *links = 0;
            *name_bytes = 0;
            *name_hash = HASH_OFFSET;
        }
        return (0, 0, 0);
    };

    let nlines = starts.len();
    if nlines == 0 {
        if inventory {
            *links = 0;
            *name_bytes = 0;
            *name_hash = HASH_OFFSET;
        }
        return (0, 0, 0);
    }

    let mut nth = read_env_int("FS_BENCH_THREADS", default_threads() as i32) as usize;
    nth = clamp_threads(nth);
    if nth > nlines {
        nth = nlines;
    }
    if nth < 1 {
        nth = 1;
    }

    let mut results: Vec<(u64, u64, u64, u64, u64, u64)> = vec![(0, 0, 0, 0, 0, HASH_OFFSET); nth];
    let mut handles = Vec::with_capacity(nth.saturating_sub(1));

    for tid in 1..nth {
        let buf = Arc::clone(&buf);
        let starts = Arc::clone(&starts);
        handles.push((
            tid,
            std::thread::spawn(move || -> (u64, u64, u64, u64, u64, u64) {
                let start = (nlines * tid) / nth;
                let end = (nlines * (tid + 1)) / nth;

                let mut files = 0u64;
                let mut dirs = 0u64;
                let mut bytes = 0u64;
                let mut links = 0u64;
                let mut name_bytes = 0u64;
                let mut name_hash = HASH_OFFSET;

                for li in start..end {
                    let s = starts[li];
                    let mut e = s;
                    while buf[e] != 0 {
                        e += 1;
                    }
                    if e <= s {
                        continue;
                    }
                    let line = &buf[s..e];

                    if inventory {
                        let len = hash_bytes(&mut name_hash, line);
                        name_bytes += len as u64;
                    }

                    let path = std::path::Path::new(OsStr::from_bytes(line));
                    let md = if follow {
                        fs::metadata(path)
                    } else {
                        fs::symlink_metadata(path)
                    };
                    if let Ok(md) = md {
                        let ft = md.file_type();
                        if ft.is_dir() {
                            dirs += 1;
                        } else if ft.is_file() {
                            files += 1;
                            if !count_only {
                                bytes += md.len();
                            }
                        } else if ft.is_symlink() && inventory {
                            links += 1;
                        }
                    }
                }

                (files, dirs, bytes, links, name_bytes, name_hash)
            }),
        ));
    }

    // Main thread is worker 0.
    {
        let tid = 0usize;
        let start = (nlines * tid) / nth;
        let end = (nlines * (tid + 1)) / nth;

        let mut files = 0u64;
        let mut dirs = 0u64;
        let mut bytes = 0u64;
        let mut links0 = 0u64;
        let mut name_bytes0 = 0u64;
        let mut name_hash0 = HASH_OFFSET;

        for li in start..end {
            let s = starts[li];
            let mut e = s;
            while buf[e] != 0 {
                e += 1;
            }
            if e <= s {
                continue;
            }
            let line = &buf[s..e];

            if inventory {
                let len = hash_bytes(&mut name_hash0, line);
                name_bytes0 += len as u64;
            }

            let path = std::path::Path::new(OsStr::from_bytes(line));
            let md = if follow {
                fs::metadata(path)
            } else {
                fs::symlink_metadata(path)
            };
            if let Ok(md) = md {
                let ft = md.file_type();
                if ft.is_dir() {
                    dirs += 1;
                } else if ft.is_file() {
                    files += 1;
                    if !count_only {
                        bytes += md.len();
                    }
                } else if ft.is_symlink() && inventory {
                    links0 += 1;
                }
            }
        }

        results[0] = (files, dirs, bytes, links0, name_bytes0, name_hash0);
    }

    for (tid, h) in handles {
        if let Ok(r) = h.join() {
            results[tid] = r;
        }
    }

    let mut tfiles = 0u64;
    let mut tdirs = 0u64;
    let mut tbytes = 0u64;
    let mut tlinks = 0u64;
    let mut tname_bytes = 0u64;
    let mut combined_hash = HASH_OFFSET;

    for (tid, (files, dirs, bytes, links0, name_bytes0, name_hash0)) in results.iter().enumerate() {
        let _ = tid;
        tfiles += *files;
        tdirs += *dirs;
        tbytes += *bytes;
        tlinks += *links0;
        tname_bytes += *name_bytes0;
        if inventory {
            let mut h = *name_hash0;
            for _ in 0..8 {
                combined_hash ^= h & 0xff;
                combined_hash = combined_hash.wrapping_mul(HASH_PRIME);
                h >>= 8;
            }
        }
    }

    if inventory {
        *links = tlinks;
        *name_bytes = tname_bytes;
        *name_hash = combined_hash;
    }

    (tfiles, tdirs, tbytes)
}

fn treewalk_list(
    list_path: &str,
    follow: bool,
    count_only: bool,
    inventory: bool,
    links: &mut u64,
    name_bytes: &mut u64,
    name_hash: &mut u64,
) -> (u64, u64, u64) {
    let Some((buf, starts)) = read_lines_file(list_path) else {
        if inventory {
            *links = 0;
            *name_bytes = 0;
            *name_hash = HASH_OFFSET;
        }
        return (0, 0, 0);
    };

    let nlines = starts.len();
    if nlines == 0 {
        if inventory {
            *links = 0;
            *name_bytes = 0;
            *name_hash = HASH_OFFSET;
        }
        return (0, 0, 0);
    }

    let mut nth = read_env_int("FS_BENCH_THREADS", default_threads() as i32) as usize;
    nth = clamp_threads(nth);
    if nth > nlines {
        nth = nlines;
    }
    if nth < 1 {
        nth = 1;
    }

    let mut results: Vec<(u64, u64, u64, u64, u64, u64)> = vec![(0, 0, 0, 0, 0, HASH_OFFSET); nth];
    let mut handles = Vec::with_capacity(nth.saturating_sub(1));

    for tid in 1..nth {
        let buf = Arc::clone(&buf);
        let starts = Arc::clone(&starts);
        handles.push((
            tid,
            std::thread::spawn(move || -> (u64, u64, u64, u64, u64, u64) {
                let start = (nlines * tid) / nth;
                let end = (nlines * (tid + 1)) / nth;

                let mut files = 0u64;
                let mut dirs = 0u64;
                let mut bytes = 0u64;
                let mut links = 0u64;
                let mut name_bytes = 0u64;
                let mut name_hash = HASH_OFFSET;

                for li in start..end {
                    let s = starts[li];
                    let mut e = s;
                    while buf[e] != 0 {
                        e += 1;
                    }
                    if e <= s {
                        continue;
                    }
                    let line = &buf[s..e];

                    if inventory {
                        let len = hash_bytes(&mut name_hash, line);
                        name_bytes += len as u64;
                    }

                    let path = std::path::Path::new(OsStr::from_bytes(line));
                    let md = fs::symlink_metadata(path);
                    if let Ok(md) = md {
                        let ftype = md.file_type();
                        if ftype.is_symlink() && !follow {
                            if inventory {
                                links += 1;
                            }
                        } else if ftype.is_dir() {
                            dirs += 1;
                            if let Ok(entries) = fs::read_dir(path) {
                                for entry in entries.flatten() {
                                    let p = entry.path();
                                    if inventory {
                                        let len = hash_bytes(&mut name_hash, p.as_os_str().as_bytes());
                                        name_bytes += len as u64;
                                    }
                                    let md2 = if follow {
                                        entry.metadata()
                                    } else {
                                        fs::symlink_metadata(&p)
                                    };
                                    if let Ok(md2) = md2 {
                                        let ft = md2.file_type();
                                        if ft.is_symlink() && !follow {
                                            if inventory {
                                                links += 1;
                                            }
                                            continue;
                                        }
                                        if ft.is_dir() {
                                            dirs += 1;
                                        } else if ft.is_file() {
                                            files += 1;
                                            if !count_only {
                                                bytes += md2.len();
                                            }
                                        } else if ft.is_symlink() && inventory {
                                            links += 1;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                (files, dirs, bytes, links, name_bytes, name_hash)
            }),
        ));
    }

    // Main thread is worker 0.
    {
        let tid = 0usize;
        let start = (nlines * tid) / nth;
        let end = (nlines * (tid + 1)) / nth;

        let mut files = 0u64;
        let mut dirs = 0u64;
        let mut bytes = 0u64;
        let mut links0 = 0u64;
        let mut name_bytes0 = 0u64;
        let mut name_hash0 = HASH_OFFSET;

        for li in start..end {
            let s = starts[li];
            let mut e = s;
            while buf[e] != 0 {
                e += 1;
            }
            if e <= s {
                continue;
            }
            let line = &buf[s..e];

            if inventory {
                let len = hash_bytes(&mut name_hash0, line);
                name_bytes0 += len as u64;
            }

            let path = std::path::Path::new(OsStr::from_bytes(line));
            let md = fs::symlink_metadata(path);
            if let Ok(md) = md {
                let ftype = md.file_type();
                if ftype.is_symlink() && !follow {
                    if inventory {
                        links0 += 1;
                    }
                } else if ftype.is_dir() {
                    dirs += 1;
                    if let Ok(entries) = fs::read_dir(path) {
                        for entry in entries.flatten() {
                            let p = entry.path();
                            if inventory {
                                let len = hash_bytes(&mut name_hash0, p.as_os_str().as_bytes());
                                name_bytes0 += len as u64;
                            }
                            let md2 = if follow {
                                entry.metadata()
                            } else {
                                fs::symlink_metadata(&p)
                            };
                            if let Ok(md2) = md2 {
                                let ft = md2.file_type();
                                if ft.is_symlink() && !follow {
                                    if inventory {
                                        links0 += 1;
                                    }
                                    continue;
                                }
                                if ft.is_dir() {
                                    dirs += 1;
                                } else if ft.is_file() {
                                    files += 1;
                                    if !count_only {
                                        bytes += md2.len();
                                    }
                                } else if ft.is_symlink() && inventory {
                                    links0 += 1;
                                }
                            }
                        }
                    }
                }
            }
        }

        results[0] = (files, dirs, bytes, links0, name_bytes0, name_hash0);
    }

    for (tid, h) in handles {
        if let Ok(r) = h.join() {
            results[tid] = r;
        }
    }

    let mut tfiles = 0u64;
    let mut tdirs = 0u64;
    let mut tbytes = 0u64;
    let mut tlinks = 0u64;
    let mut tname_bytes = 0u64;
    let mut combined_hash = HASH_OFFSET;

    for (_tid, (files, dirs, bytes, links0, name_bytes0, name_hash0)) in results.iter().enumerate() {
        tfiles += *files;
        tdirs += *dirs;
        tbytes += *bytes;
        tlinks += *links0;
        tname_bytes += *name_bytes0;
        if inventory {
            let mut h = *name_hash0;
            for _ in 0..8 {
                combined_hash ^= h & 0xff;
                combined_hash = combined_hash.wrapping_mul(HASH_PRIME);
                h >>= 8;
            }
        }
    }

    if inventory {
        *links = tlinks;
        *name_bytes = tname_bytes;
        *name_hash = combined_hash;
    }

    (tfiles, tdirs, tbytes)
}

fn main() {
    let mut args = env::args();
    let _prog = args.next();
    let root = match args.next() {
        Some(p) => p,
        None => {
            println!("usage: fswalk <path>");
            std::process::exit(1);
        }
    };

    let max_depth = read_env_int("FS_BENCH_MAX_DEPTH", 6);
    let follow = read_env_bool("FS_BENCH_FOLLOW_SYMLINKS", false);
    let list_path = read_env_str("FS_BENCH_LIST");
    let tree_list = read_env_str("FS_BENCH_TREEWALK_LIST");
    let count_only = read_env_bool("FS_BENCH_COUNT_ONLY", false);
    let inventory = read_env_bool("FS_BENCH_INVENTORY", false);
    let mut links: u64 = 0;
    let mut name_bytes: u64 = 0;
    let mut name_hash: u64 = HASH_OFFSET;

    if let Some(list_path) = list_path {
        let (files, dirs, bytes) = fswalk_list(
            &list_path,
            follow,
            count_only,
            inventory,
            &mut links,
            &mut name_bytes,
            &mut name_hash,
        );
        if inventory {
            println!(
                "files={} dirs={} bytes={} links={} name_bytes={} hash={}",
                files, dirs, bytes, links, name_bytes, name_hash
            );
        } else {
            println!("files={} dirs={} bytes={}", files, dirs, bytes);
        }
        return;
    }
    if let Some(tree_list) = tree_list {
        let (files, dirs, bytes) = treewalk_list(
            &tree_list,
            follow,
            count_only,
            inventory,
            &mut links,
            &mut name_bytes,
            &mut name_hash,
        );
        if inventory {
            println!(
                "files={} dirs={} bytes={} links={} name_bytes={} hash={}",
                files, dirs, bytes, links, name_bytes, name_hash
            );
        } else {
            println!("files={} dirs={} bytes={}", files, dirs, bytes);
        }
        return;
    }

    let mut files: u64 = 0;
    let mut dirs: u64 = 0;
    let mut bytes: u64 = 0;

    let mut stack: Vec<(PathBuf, i32)> = Vec::new();
    stack.push((PathBuf::from(root), 0));

    while let Some((path, depth)) = stack.pop() {
        let md = match fs::symlink_metadata(&path) {
            Ok(m) => m,
            Err(_) => continue,
        };

        let ftype = md.file_type();
        if inventory {
            let len = hash_bytes(&mut name_hash, path.as_os_str().as_bytes());
            name_bytes += len as u64;
        }
        if ftype.is_symlink() && !follow {
            if inventory {
                links += 1;
            }
            continue;
        }

        if ftype.is_dir() {
            dirs += 1;
            if max_depth >= 0 && depth >= max_depth {
                continue;
            }
            let entries = match fs::read_dir(&path) {
                Ok(e) => e,
                Err(_) => continue,
            };
            for entry in entries {
                if let Ok(e) = entry {
                    stack.push((e.path(), depth + 1));
                }
            }
        } else if ftype.is_file() {
            files += 1;
            if !count_only {
                bytes += md.len();
            }
        } else if ftype.is_symlink() && inventory {
            links += 1;
        }
    }

    if inventory {
        println!(
            "files={} dirs={} bytes={} links={} name_bytes={} hash={}",
            files, dirs, bytes, links, name_bytes, name_hash
        );
    } else {
        println!("files={} dirs={} bytes={}", files, dirs, bytes);
    }
}
