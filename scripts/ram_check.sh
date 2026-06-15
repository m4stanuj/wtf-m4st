#!/bin/bash
# ram_check.sh — CrewAI run se pehle RAM check karo
# Rule: >11GB in use → stop on-demand containers first
# Usage: source scripts/ram_check.sh  OR  bash scripts/ram_check.sh

echo "[ram-check] Checking Docker memory usage..."

TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_MEM_KB/1024/1024}")

# Docker stats — sum up memory usage
DOCKER_USED_MB=$(docker stats --no-stream --format "{{.MemUsage}}" 2>/dev/null \
  | awk -F'/' '{gsub(/[^0-9.]/,"",$1); sum += $1} END {print int(sum)}')

DOCKER_USED_GB=$(awk "BEGIN {printf \"%.2f\", $DOCKER_USED_MB/1024}")

echo "[ram-check] Total RAM: ${TOTAL_MEM_GB}GB"
echo "[ram-check] Docker containers: ${DOCKER_USED_GB}GB"

# Threshold: 11GB
THRESHOLD=11264  # MB

if [ "$DOCKER_USED_MB" -gt "$THRESHOLD" ] 2>/dev/null; then
    echo "[ram-check] ⚠ RAM > 11GB — stopping on-demand containers..."
    docker stop crawl4ai   2>/dev/null && echo "  stopped: crawl4ai"   || true
    docker stop browser-use 2>/dev/null && echo "  stopped: browser-use" || true
    docker stop pentest-mcp 2>/dev/null && echo "  stopped: pentest-mcp" || true

    NEW_USED=$(docker stats --no-stream --format "{{.MemUsage}}" 2>/dev/null \
      | awk -F'/' '{gsub(/[^0-9.]/,"",$1); sum += $1} END {print int(sum/1024*100)/100}')
    echo "[ram-check] After cleanup: ${NEW_USED}GB in use"
    echo "[ram-check] ✅ Safe to start CrewAI"
else
    echo "[ram-check] ✅ RAM OK (${DOCKER_USED_GB}GB < 11GB) — safe to start crew"
fi
