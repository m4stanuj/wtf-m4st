# ================================================================
# M4ST v8.2-local — Full Stack Health Check (Phase A)
# Usage: .\scripts\health_check_full.ps1
# ================================================================

Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
Write-Host "  M4ST v8.2-local — Stack Health Check" -ForegroundColor Cyan
Write-Host "$('=' * 50)`n" -ForegroundColor Cyan

$endpoints = @(
    @{ Name = "OpenClaw";          URL = "http://localhost:3001";           Port = 3001 },
    @{ Name = "9Router Dashboard"; URL = "http://localhost:20128/dashboard"; Port = 20128 },
    @{ Name = "FalkorDB";          URL = $null;                            Port = 6379 },
    @{ Name = "Graphiti MCP";      URL = "http://localhost:8001/sse";      Port = 8001 },
    @{ Name = "Cognee MCP";        URL = "http://localhost:8000";          Port = 8000 },
    @{ Name = "Langfuse";          URL = "http://localhost:3000";          Port = 3000 },
    @{ Name = "Uptime Kuma";       URL = "http://localhost:3002";          Port = 3002 },
    @{ Name = "OpenWork MCP";      URL = "http://localhost:8765";          Port = 8765 },
    @{ Name = "SEPCC";             URL = "http://localhost:8082";          Port = 8082 },
    @{ Name = "Crawl4AI";          URL = "http://localhost:11235";         Port = 11235 },
    @{ Name = "Perplexica (Vane)"; URL = "http://localhost:3010";          Port = 3010 },
    @{ Name = "LibreChat";         URL = "http://localhost:3080";          Port = 3080 }
)

$up = 0; $down = 0; $total = $endpoints.Count

foreach ($ep in $endpoints) {
    $status = $false
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.ConnectAsync("localhost", $ep.Port).Wait(2000) | Out-Null
        if ($tcp.Connected) { $status = $true }
        $tcp.Close()
    } catch {}

    if ($status) {
        Write-Host "  [OK]  $($ep.Name) — :$($ep.Port)" -ForegroundColor Green
        $up++
    } else {
        Write-Host "  [XX]  $($ep.Name) — :$($ep.Port)" -ForegroundColor Red
        $down++
    }
}

Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
Write-Host "  Results: $up/$total UP | $down/$total DOWN" -ForegroundColor $(if ($down -eq 0) { "Green" } else { "Yellow" })
Write-Host "$('=' * 50)" -ForegroundColor Cyan

# Docker containers
Write-Host "`n  Docker Containers:" -ForegroundColor Cyan
wsl -d kali-linux -- bash -c "docker ps --format '  {{.Names}}: {{.Status}}' 2>/dev/null"

# RAM usage
Write-Host "`n  WSL RAM Usage:" -ForegroundColor Cyan
wsl -d kali-linux -- bash -c "free -h | head -2"

Write-Host "`n  M4ST Endpoints:" -ForegroundColor Cyan
Write-Host "    LibreChat:   http://localhost:3080"
Write-Host "    Perplexica:  http://localhost:3010"
Write-Host "    9Router:     http://localhost:20128/dashboard"
Write-Host "    Langfuse:    http://localhost:3000"
Write-Host "    Uptime Kuma: http://localhost:3002"
Write-Host ""
Write-Host "  M4ST v8.2-local — @m4stanuj" -ForegroundColor Magenta
