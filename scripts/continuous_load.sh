#!/usr/bin/env bash
# Continuous load generator for rate() queries
echo "🔄 Generating continuous load for 3 minutes..."
echo "   This provides active traffic for rate() and increase() queries"

end_time=$((SECONDS + 180))
count=0
rps=10

while [ $SECONDS -lt $end_time ]; do
  for i in $(seq 1 $rps); do
    curl -s http://localhost:3000/ >/dev/null &
  done
  wait
  ((count += rps))
  
  # Progress indicator every 30 seconds
  if [ $((count % 300)) -eq 0 ]; then
    elapsed=$((SECONDS))
    remaining=$((180 - elapsed))
    echo "   ⏱️  ${elapsed}s elapsed | ${count} requests sent | ${remaining}s remaining"
  fi
  
  sleep 1
done

echo "✅ Continuous load finished: $count requests in 3 minutes (~10 RPS)"
