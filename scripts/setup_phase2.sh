#!/bin/bash
# ================================================================
# M4ST v8.2-local — Phase 2 Setup (Memory + Observability)
# Run INSIDE WSL2 after Phase 1 is verified
# Usage: bash /home/anuj/m4st/scripts/setup_phase2.sh
# ================================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
ok()     { echo -e "${GREEN}[OK]${NC}  $1"; }
warn()   { echo -e "${YELLOW}[!!]${NC}  $1"; }
info()   { echo -e "${CYAN}[>>]${NC}  $1"; }
header() { echo -e "\n${BOLD}${CYAN}══ $1 ══${NC}"; }

M4ST_HOME="/home/anuj/m4st"
cd "$M4ST_HOME/docker"

# ── 1. FalkorDB verify (should already be running from Phase 1) ──────
header "Step 2.1 — FalkorDB verify"
if redis-cli -p 6379 ping 2>/dev/null | grep -q "PONG"; then
    ok "FalkorDB: PONG ✅ (redis-cli -p 6379 ping)"
else
    info "Starting FalkorDB..."
    docker compose up -d falkordb
    sleep 5
    ok "FalkorDB started"
fi

# ── 2. Graphiti MCP server ───────────────────────────────────────────
header "Step 2.2 — Graphiti MCP server (SSE)"
source "$M4ST_HOME/.env" 2>/dev/null || true

info "Starting Graphiti MCP + test config..."
docker compose up -d graphiti-mcp
sleep 8

if curl -sf http://localhost:8001/sse &>/dev/null; then
    ok "Graphiti MCP: http://localhost:8001/sse ✅"
else
    warn "Graphiti MCP not ready. Check: docker logs graphiti-mcp"
fi

# ── 3. Cognee MCP ────────────────────────────────────────────────────
header "Step 2.3 — Cognee MCP"
docker compose up -d cognee-mcp
sleep 8

if curl -sf http://localhost:8000/ &>/dev/null; then
    ok "Cognee MCP: http://localhost:8000 ✅"
else
    warn "Cognee not ready. Check: docker logs cognee-mcp"
fi

# Initial index of M4ST project
info "Initial Cognee index of $M4ST_HOME..."
source "$M4ST_HOME/.venv/bin/activate"
python -c "
import asyncio, cognee
async def index():
    await cognee.add('$M4ST_HOME')
    await cognee.make()
    print('Cognee index complete')
asyncio.run(index())
" 2>&1 | tail -5 || warn "Cognee index failed — check API keys in .env"
deactivate

# ── 4. Langfuse ──────────────────────────────────────────────────────
header "Step 2.4 — Langfuse (LLM observability)"
docker compose up -d langfuse
sleep 12

if curl -sf http://localhost:3000/ &>/dev/null; then
    ok "Langfuse: http://localhost:3000 ✅"
    info "Create an account at http://localhost:3000 and add LANGFUSE_PUBLIC_KEY + LANGFUSE_SECRET_KEY to .env"
else
    warn "Langfuse not ready. Check: docker logs langfuse"
fi

# ── 5. Uptime Kuma monitors ──────────────────────────────────────────
header "Step 2.5 — Uptime Kuma monitors"
if curl -sf http://localhost:3002/ &>/dev/null; then
    ok "Uptime Kuma: http://localhost:3002 ✅"
    info "Add monitors for these endpoints:"
    echo "  - http://localhost:3001  (OpenClaw)"
    echo "  - http://localhost:20128 (9Router)"
    echo "  - http://localhost:8001  (Graphiti MCP)"
    echo "  - http://localhost:8000  (Cognee MCP)"
    echo "  - http://localhost:3000  (Langfuse)"
    echo "  - localhost:6379         (FalkorDB TCP)"
    info "Set Telegram alert: Bot Token + Chat ID from .env"
fi

# ── 6. OpenWork MCP ──────────────────────────────────────────────────
header "Step 2.6 — OpenWork MCP bridge"
docker compose up -d openwork-mcp
sleep 5

if curl -sf http://localhost:8765/health &>/dev/null; then
    ok "OpenWork MCP: http://localhost:8765 ✅"
else
    warn "OpenWork MCP not ready. Check: docker logs openwork-mcp"
fi

# ── 7. SEPCC proxy ───────────────────────────────────────────────────
header "Step 2.7 — SEPCC (Claude Code session proxy)"
docker compose up -d sepcc
sleep 5

if curl -sf http://localhost:8082/ &>/dev/null; then
    ok "SEPCC: http://localhost:8082 ✅"
else
    warn "SEPCC not ready. Check: docker logs sepcc"
fi

# ── 8. Memory verification ───────────────────────────────────────────
header "Step 2.8 — Memory verification test"
source "$M4ST_HOME/.venv/bin/activate"
python - << 'PYEOF'
import os
from dotenv import load_dotenv
load_dotenv("/home/anuj/m4st/.env")

try:
    from graphiti_core import Graphiti
    from graphiti_core.llm_client import OpenAIClient, OpenAIConfig
    
    llm_client = OpenAIClient(OpenAIConfig(
        api_key=os.getenv("NINEROUTER_API_KEY", "9router-key"),
        base_url=os.getenv("NINEROUTER_BASE_URL", "http://localhost:20128/v1"),
        model=os.getenv("MODEL_FAST", "groq/llama-3.3-70b-versatile")
    ))
    
    g = Graphiti(
        uri=os.getenv("FALKORDB_URI", "bolt://localhost:6379"),
        user=os.getenv("FALKORDB_USER", ""),
        password=os.getenv("FALKORDB_PASSWORD", ""),
        llm_client=llm_client
    )
    print("[OK]  Graphiti connected to FalkorDB")
except Exception as e:
    print(f"[!!]  Graphiti connection error: {e}")
PYEOF
deactivate

# ── SUMMARY ──────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  M4ST Phase 2 Complete!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Services running:${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps
echo ""
echo -e "${CYAN}NEXT: Phase 3 — Tools Layer${NC}"
echo "  bash $M4ST_HOME/scripts/setup_phase3.sh"
echo ""
echo -e "🥀 Phase 2 Done — Memory + Observability live — @m4stanuj"
