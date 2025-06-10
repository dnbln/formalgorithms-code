#!/usr/bin/env bash

perform_test() {
    (for i in {1..1000}; do echo "Hello world"; sleep 1; done) | nc 127.0.0.1 8080
}

for conc in {1..10000}; do
    if (( conc % 50 == 0 )); then
        echo "Waiting a bit" >&2
        sleep 1
    fi
    perform_test & sleep_pid=$!
done

wait $sleep_pid
