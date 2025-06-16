use std::sync::atomic::AtomicUsize;

use tokio::io::{AsyncReadExt, AsyncWriteExt};

const TOTAL_CONNECTIONS: usize = 10000;
const ITERATIONS: usize = 4;

static CONNECTIONS: AtomicUsize = AtomicUsize::new(0);

const ALPHABET: &[u8] = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

async fn worker() {
    let mut socket = tokio::net::TcpStream::connect(("127.0.0.1", 8080))
        .await
        .unwrap();
    CONNECTIONS.fetch_add(1, std::sync::atomic::Ordering::SeqCst);

    while CONNECTIONS.load(std::sync::atomic::Ordering::SeqCst) < TOTAL_CONNECTIONS {
        tokio::task::yield_now().await;
    }

    println!("Starting test, loaded {} connections", CONNECTIONS.load(std::sync::atomic::Ordering::SeqCst));

    for x in 0..ITERATIONS {
        let mut buf = [0; 1024];
        let mut rbuf = [0; 1024];
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

    CONNECTIONS.fetch_sub(1, std::sync::atomic::Ordering::SeqCst);
}

#[tokio::main]
async fn main() {
    let start = std::time::Instant::now();
    let jh = (0..TOTAL_CONNECTIONS)
        .map(|_| tokio::spawn(worker()))
        .collect::<Vec<_>>();
    for handle in jh {
        handle.await.unwrap();
    }
    let duration = start.elapsed();
    println!("Total time taken: {:?}", duration);
}
