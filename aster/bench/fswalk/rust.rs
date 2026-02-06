use std::env;
use std::ffi::OsStr;
use std::fs;
use std::os::unix::ffi::OsStrExt;
use std::path::PathBuf;

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

fn fswalk_list(
    list_path: &str,
    follow: bool,
    count_only: bool,
    inventory: bool,
    links: &mut u64,
    name_bytes: &mut u64,
    name_hash: &mut u64,
) -> (u64, u64, u64) {
    let mut files = 0u64;
    let mut dirs = 0u64;
    let mut bytes = 0u64;

    if let Ok(mut buf) = fs::read(list_path) {
        let read = buf.len();
        buf.push(0);
        let mut start: usize = 0;
        let mut i: usize = 0;
        while i <= read {
            let c = buf[i];
            if c == b'\n' || c == b'\r' || c == 0 {
                if i > start {
                    if inventory {
                        let len = hash_bytes(name_hash, &buf[start..i]);
                        *name_bytes += len as u64;
                    }
                    let path = std::path::Path::new(OsStr::from_bytes(&buf[start..i]));
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
                            *links += 1;
                        }
                    }
                }
                let mut j = i + 1;
                while j < read {
                    let d = buf[j];
                    if d == b'\n' || d == b'\r' {
                        j += 1;
                    } else {
                        break;
                    }
                }
                start = j;
                i = j;
                continue;
            }
            i += 1;
        }
    }

    (files, dirs, bytes)
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
    let mut files = 0u64;
    let mut dirs = 0u64;
    let mut bytes = 0u64;

    if let Ok(mut buf) = fs::read(list_path) {
        let read = buf.len();
        buf.push(0);
        let mut start: usize = 0;
        let mut i: usize = 0;
        while i <= read {
            let c = buf[i];
            if c == b'\n' || c == b'\r' || c == 0 {
                if i > start {
                    if inventory {
                        let len = hash_bytes(name_hash, &buf[start..i]);
                        *name_bytes += len as u64;
                    }
                    let path = std::path::Path::new(OsStr::from_bytes(&buf[start..i]));
                    let md = fs::symlink_metadata(path);
                    if let Ok(md) = md {
                        let ftype = md.file_type();
                        if ftype.is_symlink() && !follow {
                            // skip
                            if inventory {
                                *links += 1;
                            }
                        } else if ftype.is_dir() {
                            dirs += 1;
                            if let Ok(entries) = fs::read_dir(path) {
                                for entry in entries.flatten() {
                                    if inventory {
                                        let p = entry.path();
                                        let len = hash_bytes(name_hash, p.as_os_str().as_bytes());
                                        *name_bytes += len as u64;
                                    }
                                    let md2 = if follow {
                                        entry.metadata()
                                    } else {
                                        fs::symlink_metadata(entry.path())
                                    };
                                    if let Ok(md2) = md2 {
                                        let ft = md2.file_type();
                                        if ft.is_symlink() && !follow {
                                            if inventory {
                                                *links += 1;
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
                                            *links += 1;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                let mut j = i + 1;
                while j < read {
                    let d = buf[j];
                    if d == b'\n' || d == b'\r' {
                        j += 1;
                    } else {
                        break;
                    }
                }
                start = j;
                i = j;
                continue;
            }
            i += 1;
        }
    }

    (files, dirs, bytes)
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
