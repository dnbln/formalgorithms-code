#!/usr/bin/env bash

cd io-bench-tokio
cargo build --release --bin io-bench-tokio
cd ..
sleep 1
io-bench-tokio/target/release/io-bench-tokio &
bench_pid=$!
if kill -0 $bench_pid 2>/dev/null; then
    echo "bench started successfully."
else
    echo "Failed to start bench."
    exit 1
fi
sleep 5
netstat -anvp tcp | awk 'NR<3 || /LISTEN/' | grep 8080
python3 test.py
sleep 1
kill -9 $bench_pid >/dev/null
sleep 1
if kill -0 $bench_pid 2>/dev/null; then
    echo "bench did not terminate as expected."
    exit 1
else
    echo "bench terminated successfully."
fi