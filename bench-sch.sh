#!/usr/bin/env bash

alr build --release

bin/formalgorithms &
formalgorithms_pid=$!
sleep 1
if kill -0 $formalgorithms_pid 2>/dev/null; then
    echo "Formalgorithms started successfully."
else
    echo "Failed to start Formalgorithms."
    exit 1
fi
sleep 5
netstat -anvp tcp | awk 'NR<3 || /LISTEN/' | grep 8080
timeout 10s io-bench-tokio/target/release/io-bench-tokio-client 1>> results-sch.txt
sleep 1
kill -9 $formalgorithms_pid >/dev/null
sleep 1
if kill -0 $formalgorithms_pid 2>/dev/null; then
    echo "Formalgorithms did not terminate as expected."
    exit 1
else
    echo "Formalgorithms terminated successfully."
fi