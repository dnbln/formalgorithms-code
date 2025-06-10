#!/usr/bin/env bash

perform_test() {
    (for i in {1..100}; do echo "Hello world"; sleep 0.01; done) | nc 127.0.0.1 8080
}

for conc in {1..10000}; do
    sleep 0.005
    perform_test & sleep_pid=$!
done

wait $sleep_pid
