#!/usr/bin/env bash

tcpkali 127.0.0.1:8080 \
  -c 2 \
  --message-rate 1000 \
  --message "ping\n" \
  -T 30 \
  --connect-rate 3000 --nagle off    # connection/sec
