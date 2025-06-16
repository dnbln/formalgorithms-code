#!/usr/bin/env bash

alr build --release

sleep 1
bin/formalgorithms &
formalgorithms_pid=$!
if kill -0 $formalgorithms_pid 2>/dev/null; then
    echo "Formalgorithms started successfully."
else
    echo "Failed to start Formalgorithms."
    exit 1
fi
sleep 5
netstat -anvp tcp | awk 'NR<3 || /LISTEN/' | grep 8080
python3 test.py
sleep 1
kill -9 $formalgorithms_pid >/dev/null
sleep 1
if kill -0 $formalgorithms_pid 2>/dev/null; then
    echo "Formalgorithms did not terminate as expected."
    exit 1
else
    echo "Formalgorithms terminated successfully."
fi