#!/usr/bin/env bash


/opt/local/bin/tcpkali 127.0.0.1:8080 \
  -c 10000 \
  --message-rate 1 \
  --message "ping\n" \
  -T 30 \
  --connect-rate 3000 -w 2 &    # connection/sec
tcpkalipid=$!

sleep 1
while kill -0 $tcpkalipid 2>/dev/null; do
    # echo "Sending ping..."
    echo | nc 127.0.0.1 8080
    sleep 1
done

wait $tcpkalipid