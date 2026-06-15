#!/bin/bash
# start_crawl.sh — On-demand Crawl4AI + Scrapling
# Usage: ./scripts/start_crawl.sh [start|stop|status]
# ⚠ Must use v0.8.9+ (CVE-2026-26216 CVSS 10.0 patched)

set -e
ACTION=${1:-start}

case "$ACTION" in
  start)
    echo "[crawl] Pulling latest Crawl4AI (CVE patch required)..."
    docker pull unclecode/crawl4ai:latest

    echo "[crawl] Starting Crawl4AI on port 11235..."
    docker run -d \
      --name crawl4ai \
      --rm \
      -p 11235:11235 \
      -e MAX_CONCURRENT_TASKS=5 \
      unclecode/crawl4ai:latest
    echo "[crawl] Crawl4AI started: http://localhost:11235"
    echo "[crawl] Stop when done: ./scripts/start_crawl.sh stop"
    ;;

  stop)
    echo "[crawl] Stopping Crawl4AI..."
    docker stop crawl4ai 2>/dev/null || echo "[crawl] Already stopped"
    echo "[crawl] Done. Container removed (--rm flag)."
    ;;

  status)
    docker ps --filter "name=crawl4ai" --format "{{.Names}}: {{.Status}}"
    ;;

  *)
    echo "Usage: $0 [start|stop|status]"
    exit 1
    ;;
esac
