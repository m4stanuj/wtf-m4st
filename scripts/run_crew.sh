#!/bin/bash
# run_crew.sh — Safe crew runner with RAM check
# Usage: bash scripts/run_crew.sh [nightly|content|bugfix|all]

set -e
M4ST_HOME="/home/anuj/m4st"
CREW=${1:-nightly}

source "$M4ST_HOME/.venv/bin/activate"
source "$M4ST_HOME/.env" 2>/dev/null || true

echo "════════════════════════════════"
echo "  M4ST Crew Runner: $CREW"
echo "════════════════════════════════"
echo ""

# RAM check first
bash "$M4ST_HOME/scripts/ram_check.sh"
echo ""

run_crew() {
    local name=$1
    local script=$2
    echo "[crew] Starting $name..."
    python "$M4ST_HOME/crews/$script" 2>&1 | tee -a "$M4ST_HOME/logs/automation_log.jsonl"
    echo "[crew] $name complete."
}

case "$CREW" in
  nightly)
    run_crew "Nightly Crew" "nightly_crew.py"
    ;;
  content)
    run_crew "Content Crew" "content_crew.py"
    ;;
  bugfix)
    run_crew "Bugfix Crew" "bugfix_crew.py"
    ;;
  all)
    echo "[crew] Running full nightly cycle (dry run mode)..."
    run_crew "Nightly Crew"  "nightly_crew.py"
    sleep 5
    run_crew "Content Crew"  "content_crew.py"
    sleep 5
    python "$M4ST_HOME/scripts/cognee_full_reindex.py"
    sleep 5
    run_crew "Bugfix Crew"   "bugfix_crew.py"
    sleep 5
    python "$M4ST_HOME/scripts/nightly_telegram_report.py"
    echo "[crew] Full cycle complete."
    ;;
  *)
    echo "Usage: $0 [nightly|content|bugfix|all]"
    exit 1
    ;;
esac

deactivate
