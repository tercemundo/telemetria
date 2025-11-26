#!/usr/bin/env bash
# Load generator: controlled concurrent requests
echo "Generating load: 1000 requests in batches of 20..."
for batch in {1..50}; do
  for i in {1..20}; do
    curl -s http://localhost:3000/ >/dev/null &
  done
  wait
  sleep 0.5
done
echo "✅ Load generation finished: 1000 requests completed"
