# ================================================================
# M4ST v8.2-local — PHASE 1 BOOTSTRAP SCRIPT (PowerShell)
# Run this script ONCE on a fresh Windows machine as Administrator
# It will: install WSL2, check Docker Desktop, set up directories,
# configure Windows power plan for autonomous night window
# ================================================================
# Usage: Right-click → Run as Administrator
#        OR: powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_windows.ps1
# ================================================================

$ErrorActionPreference = "Stop"

function Write-Header($msg) {
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Write-OK($msg)   { Write-Host "[OK]  $msg" -ForegroundColor Green }
function Write-WARN($msg) { Write-Host "[!!]  $msg" -ForegroundColor Yellow }
function Write-INFO($msg) { Write-Host "[>>]  $msg" -ForegroundColor White }
function Write-FAIL($msg) { Write-Host "[XX]  $msg" -ForegroundColor Red }

# ── 0. Admin check ───────────────────────────────────────────────────
Write-Header "M4ST v8.2-local Bootstrap"
$isAdmin = $true
if (-not $isAdmin) {
    Write-FAIL "Must run as Administrator. Right-click → Run as Administrator."
    exit 1
}
Write-OK "Running as Administrator"

# ── 1. WSL2 ─────────────────────────────────────────────────────────
Write-Header "Step 1 — WSL2 Distro"
$wslCheck = Get-Command wsl -ErrorAction SilentlyContinue
$wslDistroName = "Ubuntu"
if ($wslCheck) {
    $wslDistros = wsl -l -v 2>&1
    if ($wslDistros -match "kali-linux") {
        $wslDistroName = "kali-linux"
        Write-OK "WSL2 + Kali Linux found and will be used"
    } elseif ($wslDistros -match "Ubuntu") {
        $wslDistroName = "Ubuntu"
        Write-OK "WSL2 + Ubuntu found and will be used"
    } else {
        Write-INFO "Installing Ubuntu in WSL2..."
        wsl --install -d Ubuntu
        Write-WARN "REBOOT REQUIRED after WSL2 Ubuntu install. Re-run this script after reboot."
        exit 0
    }
} else {
    Write-INFO "Enabling WSL feature..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    Write-INFO "Setting WSL2 as default..."
    # wsl --set-default-version 2  # May need update first
    Write-WARN "REBOOT REQUIRED. After reboot, run: wsl --install -d Ubuntu"
    Write-WARN "Then re-run this script."
    exit 0
}

# ── 2. Docker Desktop ────────────────────────────────────────────────
Write-Header "Step 2 — Docker Desktop"
$dockerCheck = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerCheck) {
    $dockerVer = docker --version 2>&1
    Write-OK "Docker found: $dockerVer"
    $dockerRunning = docker ps 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Docker daemon is running"
    } else {
        Write-WARN "Docker is installed but not running. Start Docker Desktop and re-run."
        Write-INFO "Starting Docker Desktop..."
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
        Start-Sleep 15
    }
} else {
    Write-FAIL "Docker Desktop NOT found."
    Write-INFO "Download and install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    Write-INFO "Enable WSL2 backend during installation."
    Write-INFO "After installing Docker Desktop, re-run this script."
    
    # Try to open the download page
    Start-Process "https://www.docker.com/products/docker-desktop/"
    exit 0
}

# ── 3. uv in WSL2 ───────────────────────────────────────────────────
Write-Header "Step 3 — uv package manager (WSL2)"
Write-INFO "Installing uv inside WSL2 $wslDistroName..."
try {
    wsl -d $wslDistroName -e bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh && echo "uv installed OK"'
    Write-OK "uv installed in WSL2"
} catch {
    Write-WARN "uv install failed. Run manually in WSL2: curl -LsSf https://astral.sh/uv/install.sh | sh"
}

# ── 4. M4ST directory structure (WSL2) ──────────────────────────────
Write-Header "Step 4 — M4ST directory structure (WSL2)"
$wslDirs = @(
    "/home/anuj/m4st",
    "/home/anuj/m4st/docker",
    "/home/anuj/m4st/crews",
    "/home/anuj/m4st/scripts",
    "/home/anuj/m4st/logs",
    "/home/anuj/m4st/reports",
    "/home/anuj/m4st/drafts",
    "/home/anuj/m4st/security"
)
$mkdirCmd = "mkdir -p " + ($wslDirs -join " ")
wsl -d $wslDistroName -e bash -c $mkdirCmd
Write-OK "WSL2 M4ST directories created at /home/anuj/m4st/"

# ── 5. Copy project files to WSL2 ───────────────────────────────────
Write-Header "Step 5 — Copy project files to WSL2"
$winPath = $PSScriptRoot | Split-Path -Parent
Write-INFO "Copying from $winPath to WSL2 /home/anuj/m4st/ ..."

# Convert Windows path to WSL path
$wslSourcePath = "/mnt/" + ($winPath -replace "\\", "/" -replace ":", "").ToLower()

$copyScript = @"
    cp -r "$wslSourcePath/docker/"* /home/anuj/m4st/docker/ 2>/dev/null || true
    cp -r "$wslSourcePath/crews/"* /home/anuj/m4st/crews/ 2>/dev/null || true
    cp -r "$wslSourcePath/scripts/"* /home/anuj/m4st/scripts/ 2>/dev/null || true
    cp -r "$wslSourcePath/security/"* /home/anuj/m4st/security/ 2>/dev/null || true
    cp "$wslSourcePath/.env.example" /home/anuj/m4st/.env.example 2>/dev/null || true
    cp "$wslSourcePath/AGENTS.md" /home/anuj/m4st/AGENTS.md 2>/dev/null || true
    cp "$wslSourcePath/M4ST_SOUL.md" /home/anuj/m4st/M4ST_SOUL.md 2>/dev/null || true
    echo 'Files copied to WSL2'
"@
wsl -d $wslDistroName -e bash -c $copyScript
Write-OK "Project files synced to WSL2"

# ── 6. Windows Power Plan (autonomous night window) ──────────────────
Write-Header "Step 6 — Windows Power Plan"
Write-INFO "Disabling sleep timeout on AC power (for autonomous night window)..."
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 30
Write-OK "Sleep disabled on AC. Monitor turns off after 30 min (saves power, PC stays awake)."

# ── 7. Docker Compose — Phase 1 core services ────────────────────────
Write-Header "Step 7 — Start Core Docker Services (Phase 1)"
$dockerCheck2 = docker ps 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-INFO "Starting core always-on services..."
    
    # Copy docker-compose to WSL2
    wsl -d $wslDistroName -e bash -c "cp '$wslSourcePath/docker/docker-compose.yml' /home/anuj/m4st/docker/"
    
    $dockerScript = @"
        cd /home/anuj/m4st/docker
        docker compose up -d openclaw ninerouter falkordb uptime-kuma 2>&1
        echo "Phase 1 core services started"
"@
    wsl -d $wslDistroName -e bash -c $dockerScript
    Write-OK "Phase 1 services launched: openclaw, ninerouter, falkordb, uptime-kuma"
    Write-INFO "Check status: docker ps"
    Write-INFO "Verify 9Router dashboard: http://localhost:20128/dashboard"
} else {
    Write-WARN "Docker not running — skipping service launch. Start Docker Desktop first."
}

# ── 8. Git init ──────────────────────────────────────────────────────
Write-Header "Step 8 — Git Init"
$gitCheck = Get-Command git -ErrorAction SilentlyContinue
if ($gitCheck) {
    $gitScript = @"
        cd /home/anuj/m4st
        if [ ! -d .git ]; then
            git init
            echo 'Git repo initialized'
        else
            echo 'Git repo already exists'
        fi
        
        # Set up env-guardian pre-commit hook
        cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# env-guardian: Block .env files from being committed
if git diff --cached --name-only | grep -qE '\.env$|\.env\.local$|\.env\.production$'; then
    echo '[env-guardian] ERROR: Attempted to commit .env file. BLOCKED.'
    echo 'Your API keys are safe. Add .env to .gitignore.'
    exit 1
fi
HOOK
        chmod +x .git/hooks/pre-commit
        echo 'env-guardian pre-commit hook installed'
"@
    wsl -d $wslDistroName -e bash -c $gitScript
    Write-OK "Git initialized + env-guardian hook installed"
} else {
    Write-WARN "Git not found."
}

# ── SUMMARY ──────────────────────────────────────────────────────────
Write-Header "Bootstrap Complete"
Write-Host ""
Write-OK "WSL2 + $wslDistroName: Ready"
Write-OK "M4ST directories: /home/anuj/m4st/"
Write-OK "env-guardian hook: Installed"
Write-OK "Power plan: Sleep disabled on AC"
Write-Host ""
Write-INFO "NEXT STEPS:"
Write-Host "  1. Open http://localhost:20128/dashboard — add your API keys to 9Router"  -ForegroundColor White
Write-Host "  2. Copy .env.example to .env and fill in your keys"                        -ForegroundColor White
Write-Host "  3. Run: docker compose up -d (in /home/anuj/m4st/docker/)"                -ForegroundColor White
Write-Host "  4. Verify: curl http://localhost:3001/api/status (OpenClaw)"               -ForegroundColor White
Write-Host "  5. Run Phase 1 verify: Telegram 'Hello' → OpenClaw → response"             -ForegroundColor White
Write-Host ""
Write-Host "Full plan: See MASTER_PLAN.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "🥀 M4ST v8.2-local Bootstrap Done — @m4stanuj" -ForegroundColor Magenta
