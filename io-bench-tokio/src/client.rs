#![feature(integer_atomics)]

use std::{sync::atomic::AtomicU128, time::SystemTime};

use tokio::io::{AsyncReadExt, AsyncWriteExt};

const TOTAL_CONNECTIONS: usize = 10000;
const ITERATIONS: usize = 2;
const BUF_SIZE: usize = 1024;
const SAMPLES: usize = 100;
const CONNECTIONS_PER_SECOND: usize = 2000;

static BARRIER: std::sync::LazyLock<tokio::sync::Barrier> =
    std::sync::LazyLock::new(|| tokio::sync::Barrier::new(TOTAL_CONNECTIONS));

const ALPHABET: &[u8] = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

static TIME_STARTED: AtomicU128 = AtomicU128::new(0);

async fn worker(id: usize) {
    tokio::time::sleep(std::time::Duration::from_millis(
        id as u64 * 1000 / CONNECTIONS_PER_SECOND as u64,
    ))
    .await;
    let mut socket = loop {
        match tokio::net::TcpStream::connect(("127.0.0.1", 8080)).await {
            Ok(s) => break s,
            Err(e) => {
                eprintln!("Failed to connect: {}", e);
                tokio::time::sleep(std::time::Duration::from_millis(100)).await;
            }
        }
    };
    BARRIER.wait().await;
    let _ = TIME_STARTED.compare_exchange(
        0,
        SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u128,
        std::sync::atomic::Ordering::Acquire,
        std::sync::atomic::Ordering::Relaxed,
    );

    for x in 0..ITERATIONS {
        let mut buf = [0; BUF_SIZE];
        let mut rbuf = [0; BUF_SIZE];
        buf.iter_mut().enumerate().for_each(|(i, p)| {
            *p = ALPHABET[(x * 3 + i * 10) % ALPHABET.len()];
        });

        socket.write_all(&buf).await.unwrap();
        socket.flush().await.unwrap();
        socket.read_exact(&mut rbuf).await.unwrap();
        if rbuf != buf {
            eprintln!("Data mismatch: sent {:?}, received {:?}", buf, rbuf);
        }
    }

    socket.shutdown().await.unwrap();
}

#[tokio::main]
async fn main() {
    // for _sample in 0..SAMPLES {
    let start = std::time::Instant::now();
    let jh = (0..TOTAL_CONNECTIONS)
        .map(|it| tokio::spawn(worker(it)))
        .collect::<Vec<_>>();
    for handle in jh {
        handle.await.unwrap();
    }
    let duration = start.elapsed();
    eprintln!("Total time taken: {:?}", duration);

    let time_since_start = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_millis() as u128
        - TIME_STARTED.load(std::sync::atomic::Ordering::Acquire);

    eprintln!(
        "Total connections: {TOTAL_CONNECTIONS}, iterations: {ITERATIONS}, time taken: {time_since_start}ms"
    );

    let dur_sec = duration.as_secs_f64();

    println!("{TOTAL_CONNECTIONS},{ITERATIONS},{BUF_SIZE},{dur_sec},{time_since_start}");

    TIME_STARTED.store(0, std::sync::atomic::Ordering::Release);

    // tokio::time::sleep(std::time::Duration::from_secs(10)).await;
    // }
}
