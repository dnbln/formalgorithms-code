#!/usr/bin/env bash

tcpkali 127.0.0.1:8080 \
  -c 10000 \
  --message-rate 10 \
  --message "ping\n" \
  -T 30 \
  --connect-rate 3000 --nagle on    # connection/sec
