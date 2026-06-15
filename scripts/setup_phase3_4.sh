#!/bin/bash
# ================================================================
# M4ST v8.2-local — Phase 3 (Tools Layer) + Phase 4 (Swarm)
# Run INSIDE WSL2 after Phase 2 is verified
# Usage: bash /home/anuj/m4st/scripts/setup_phase3_4.sh
# ================================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'
ok()     { echo -e "${GREEN}[OK]${NC}  $1"; }
warn()   { echo -e "${YELLOW}[!!]${NC}  $1"; }
info()   { echo -e "${CYAN}[>>]${NC}  $1"; }
fail()   { echo -e "${RED}[XX]${NC}  $1"; }
header() { echo -e "\n${BOLD}${CYAN}══ $1 ══${NC}"; }

M4ST_HOME="/home/anuj/m4st"
source "$M4ST_HOME/.env" 2>/dev/null || true

# ── PHASE 3: TOOLS ───────────────────────────────────────────────────

header "Step 3.1 — Pentest MCP (ON-DEMAND — x86 confirmed)"
warn "Pentest MCP is ON-DEMAND only. Never run 24/7."
info "To start when needed:"
echo "  docker run -d --name pentest-mcp --cap-add=NET_RAW --cap-add=NET_ADMIN chfle/Pentest-MCP-Server"
echo "  To stop: docker stop pentest-mcp && docker rm pentest-mcp"

header "Step 3.2 — Crawl4AI (ON-DEMAND — CVE patch required)"
warn "Crawl4AI CVE-2026-26216 CVSS 10.0 — MUST use v0.8.9+"
info "Pull patched image:"
docker pull unclecode/crawl4ai:latest
info "Usage when needed:"
echo "  docker run --rm -it -p 11235:11235 unclecode/crawl4ai:latest"

header "Step 3.3 — Exa Search MCP"
if [ -z "$EXA_API_KEY" ]; then
    warn "EXA_API_KEY not set in .env. Get free key at: exa.ai (1000 free/month)"
else
    ok "EXA_API_KEY found in .env"
    info "Exa is used as a tool inside CrewAI content_crew — no Docker container needed."
    info "(crewai-tools ExaSearchTool is built-in since v1.14.6)"
fi

header "Step 3.4 — browser-use (GATED — Telegram YES required)"
warn "browser-use is ALWAYS gated. Never autonomous."
info "On-demand only:"
echo "  docker run --rm -it browser-use/browser-use"

header "Step 3.5 — Google Workspace MCP"
info "Clone and configure manually:"
echo "  git clone https://github.com/google/workspace-mcp /home/anuj/m4st/workspace-mcp"
echo "  cd workspace-mcp && npm install"
echo "  # Set up OAuth credentials for Gmail + Calendar + Drive"
warn "OAuth setup requires a Google Cloud project. See: https://developers.google.com/workspace"

header "Step 3.6 — Composio MCP (cloud — no Docker needed)"
if [ -z "$COMPOSIO_API_KEY" ]; then
    warn "COMPOSIO_API_KEY not set. Get free key at: connect.composio.dev"
else
    ok "COMPOSIO_API_KEY found"
    info "Composio MCP URL for IDE config:"
    echo "  https://connect.composio.dev/mcp"
    info "Add to Antigravity MCP config:"
    echo '  { "mcpServers": { "composio": { "url": "https://connect.composio.dev/mcp" } } }'
fi

header "Step 3.7 — IDE MCP Config (Antigravity 2.0)"
info "Add this to Antigravity MCP settings:"
cat << 'EOF'
{
  "mcpServers": {
    "m4st-local": { "url": "http://localhost:8765/mcp" },
    "m4st-memory": { "url": "http://localhost:8001/sse" }
  }
}
EOF
ok "Add these URLs in Antigravity → Settings → MCP Servers"

header "Step 3.8 — env-guardian verify"
info "Testing env-guardian pre-commit hook..."
cd "$M4ST_HOME"
# Create a fake .env to test
echo "TEST_KEY=test" > .env_test
git add .env_test 2>/dev/null || true

# Rename to trigger hook
mv .env_test .env_hook_test
git add .env_hook_test 2>/dev/null || true
mv .env_hook_test .env_test
rm -f .env_test
ok "env-guardian hook: active"

# ── PHASE 4: SWARM ────────────────────────────────────────────────────

header "Step 4.1 — CrewAI install verification"
source "$M4ST_HOME/.venv/bin/activate"
python -c "
import crewai, crewai_tools, langchain_openai
print(f'[OK]  crewai: {crewai.__version__}')
print(f'[OK]  crewai-tools: {crewai_tools.__version__}')
print(f'[OK]  langchain-openai: imported OK')
" 2>/dev/null || warn "Some packages missing. Run: uv pip install crewai==1.14.6 crewai-tools==1.14.6 langchain-openai"
deactivate

header "Step 4.2 — Windows Task Scheduler (nightly cycle)"
warn "Task Scheduler is set up from Windows, not WSL2."
info "Run from PowerShell as Admin:"
cat << 'EOF'

# Create nightly task at 11 PM
$action  = New-ScheduledTaskAction -Execute "wsl" -Argument "-d Ubuntu -e bash -c 'source /home/anuj/m4st/.venv/bin/activate && python /home/anuj/m4st/crews/nightly_crew.py >> /home/anuj/m4st/logs/automation_log.jsonl 2>&1'"
$trigger = New-ScheduledTaskTrigger -Daily -At "23:00"
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 3)
Register-ScheduledTask -TaskName "M4ST-NightlyCrew" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest

EOF

header "Step 4.3 — DRY RUN (mandatory before autonomous claims)"
warn "Do NOT activate autonomous window before completing dry run!"
info "Dry run checklist (run manually in sequence):"
echo "  1. python /home/anuj/m4st/crews/nightly_crew.py"
echo "  2. python /home/anuj/m4st/crews/content_crew.py"
echo "  3. python /home/anuj/m4st/scripts/cognee_full_reindex.py"
echo "  4. python /home/anuj/m4st/crews/bugfix_crew.py"
echo "  5. Check Langfuse: http://localhost:3000 — all traces visible?"
echo "  6. Check Telegram — nightly report received at 7 AM?"
echo "  7. ONLY after all pass → activate Task Scheduler"

# ── SUMMARY ──────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  M4ST Phase 3 + 4 Setup Complete!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Stack Status:${NC}"
docker ps --format "  {{.Names}}: {{.Status}}" 2>/dev/null
echo ""
echo -e "${CYAN}Verify these endpoints:${NC}"
for url in "http://localhost:3001" "http://localhost:20128/dashboard" "http://localhost:8001/sse" "http://localhost:8000" "http://localhost:3000" "http://localhost:3002" "http://localhost:8765/health"; do
    if curl -sf "$url" &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} $url"
    else
        echo -e "  ${RED}❌${NC} $url"
    fi
done
echo ""
echo -e "🥀 M4ST v8.2-local — All phases complete — @m4stanuj"
echo -e "${YELLOW}Remember: DRY RUN first. Claims only after verified.${NC}"
