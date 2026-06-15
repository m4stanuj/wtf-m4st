#!/bin/bash
# ================================================================
# M4ST v8.2-local — WSL2 Phase 1 Setup Script
# Run INSIDE WSL2 Ubuntu after bootstrap_windows.ps1 has run
# Usage: bash /home/anuj/m4st/scripts/setup_wsl2.sh
# ================================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

ok()   { echo -e "${GREEN}[OK]${NC}  $1"; }
warn() { echo -e "${YELLOW}[!!]${NC}  $1"; }
info() { echo -e "${CYAN}[>>]${NC}  $1"; }
fail() { echo -e "${RED}[XX]${NC}  $1"; exit 1; }
header() { echo -e "\n${BOLD}${CYAN}══ $1 ══${NC}"; }

M4ST_HOME="/home/anuj/m4st"

# ── 1. Verify Docker works from WSL2 ────────────────────────────────
header "Step 1 — Docker WSL2 Integration"
if docker ps &>/dev/null; then
    ok "Docker accessible from WSL2"
    docker --version
else
    fail "Docker NOT accessible from WSL2. Open Docker Desktop → Settings → Resources → WSL Integration → Enable your WSL distro (e.g. kali-linux or Ubuntu)"
fi

# ── 2. uv ───────────────────────────────────────────────────────────
header "Step 2 — uv package manager"
if command -v uv &>/dev/null; then
    ok "uv already installed: $(uv --version)"
else
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env" 2>/dev/null || source "$HOME/.cargo/env" 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"
    ok "uv installed: $(uv --version)"
fi

# ── 3. Directory structure ───────────────────────────────────────────
header "Step 3 — M4ST directory structure"
dirs=(
    "$M4ST_HOME"
    "$M4ST_HOME/docker"
    "$M4ST_HOME/crews"
    "$M4ST_HOME/scripts"
    "$M4ST_HOME/logs"
    "$M4ST_HOME/reports"
    "$M4ST_HOME/drafts"
    "$M4ST_HOME/security"
    "$M4ST_HOME/.venv"
)
for d in "${dirs[@]}"; do
    mkdir -p "$d"
done
ok "Directories ready at $M4ST_HOME"

# ── 4. Python venv + CrewAI deps ────────────────────────────────────
header "Step 4 — Python venv + CrewAI dependencies"
cd "$M4ST_HOME"

if [ ! -f ".venv/pyvenv.cfg" ]; then
    info "Creating Python venv with uv..."
    uv venv .venv --python 3.12
fi

info "Installing CrewAI + dependencies (this takes ~2 min)..."
source .venv/bin/activate

uv pip install \
    crewai==1.14.6 \
    crewai-tools==1.14.6 \
    langchain-openai \
    graphiti-core \
    cognee \
    python-dotenv \
    httpx \
    fastapi \
    uvicorn \
    openai \
    tiktoken

ok "Python packages installed"
deactivate

# ── 5. .env check ───────────────────────────────────────────────────
header "Step 5 — .env configuration"
if [ -f "$M4ST_HOME/.env" ]; then
    ok ".env file exists"
else
    warn ".env not found — copying from .env.example"
    if [ -f "$M4ST_HOME/.env.example" ]; then
        cp "$M4ST_HOME/.env.example" "$M4ST_HOME/.env"
        warn "IMPORTANT: Edit $M4ST_HOME/.env and add your API keys!"
    else
        warn ".env.example not found. Skipping."
    fi
fi

# ── 6. Cognee git post-commit hook ──────────────────────────────────
header "Step 6 — Cognee git post-commit hook"
cd "$M4ST_HOME"
if [ ! -d ".git" ]; then
    git init
    ok "git initialized"
fi

cat > .git/hooks/post-commit << 'HOOK'
#!/bin/bash
# Cognee auto-index on every commit
CHANGED_FILES=$(git diff-tree --no-commit-id -r --name-only HEAD 2>/dev/null)
if [ -n "$CHANGED_FILES" ]; then
    M4ST_HOME="/home/anuj/m4st"
    source "$M4ST_HOME/.venv/bin/activate"
    python "$M4ST_HOME/scripts/cognee_index_changed.py" "$CHANGED_FILES" &
fi
HOOK
chmod +x .git/hooks/post-commit

cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# env-guardian: Block .env from being committed
if git diff --cached --name-only | grep -qE '^\.env$|\.env\.local$|\.env\.production$'; then
    echo '[env-guardian] BLOCKED: .env contains secrets. Not committing.'
    exit 1
fi
HOOK
chmod +x .git/hooks/pre-commit
ok "git hooks installed: env-guardian (pre-commit) + cognee-index (post-commit)"

# ── 7. Phase 1 Docker services ──────────────────────────────────────
header "Step 7 — Phase 1 Docker services"

COMPOSE_FILE="$M4ST_HOME/docker/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    warn "docker-compose.yml not found at $COMPOSE_FILE"
    warn "Copy your docker-compose.yml there and run: docker compose up -d openclaw ninerouter falkordb uptime-kuma"
else
    info "Starting Phase 1 core services..."
    cd "$M4ST_HOME/docker"
    docker compose pull openclaw ninerouter falkordb uptime-kuma 2>&1 | tail -5
    docker compose up -d openclaw ninerouter falkordb uptime-kuma
    ok "Phase 1 services started!"
    
    info "Waiting 10s for services to be ready..."
    sleep 10
    docker compose ps
fi

# ── 8. Verify 9Router ───────────────────────────────────────────────
header "Step 8 — 9Router verify"
if curl -sf http://localhost:20128/dashboard &>/dev/null; then
    ok "9Router dashboard: http://localhost:20128/dashboard ✅"
else
    warn "9Router not reachable yet. Check: docker logs ninerouter"
fi

# ── 9. Verify OpenClaw ──────────────────────────────────────────────
header "Step 9 — OpenClaw verify"
if curl -sf http://localhost:3001/api/status &>/dev/null; then
    ok "OpenClaw running: http://localhost:3001 ✅"
else
    warn "OpenClaw not reachable yet. Check: docker logs openclaw"
fi

# ── SUMMARY ─────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  M4ST WSL2 Phase 1 Setup Complete!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}NEXT:${NC}"
echo "  1. Edit .env: nano $M4ST_HOME/.env"
echo "  2. Add API keys to 9Router: http://localhost:20128/dashboard"
echo "  3. Connect Telegram bot to OpenClaw"
echo "  4. Test: send 'Hello' via Telegram → OpenClaw → 9Router → response"
echo "  5. Phase 2: docker compose up -d graphiti-mcp cognee-mcp langfuse"
echo ""
echo -e "🥀 M4ST v8.2-local — WSL2 Phase 1 Done — @m4stanuj"
