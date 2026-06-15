# ================================================================
# M4ST v8.2-local — Crawl4AI On-Demand Start/Stop (Windows)
# Usage: .\scripts\start_crawl4ai.ps1 -Action start|stop|status
# ⚠ MUST use v0.8.9+ (CVE-2026-26216 CVSS 10.0 patched)
# ================================================================

param(
    [ValidateSet("start", "stop", "status")]
    [string]$Action = "start"
)

switch ($Action) {
    "start" {
        Write-Host "[crawl] Starting Crawl4AI on port 11235..." -ForegroundColor Cyan
        wsl -d kali-linux -e bash -c "docker run -d --name crawl4ai --rm -p 11235:11235 -e MAX_CONCURRENT_TASKS=5 --network m4st_m4st unclecode/crawl4ai:latest"
        Write-Host "[crawl] Crawl4AI started: http://localhost:11235" -ForegroundColor Green
        Write-Host "[crawl] Stop when done: .\scripts\start_crawl4ai.ps1 -Action stop" -ForegroundColor Yellow
    }
    "stop" {
        Write-Host "[crawl] Stopping Crawl4AI..." -ForegroundColor Cyan
        wsl -d kali-linux -e bash -c "docker stop crawl4ai 2>/dev/null || echo 'Already stopped'"
        Write-Host "[crawl] Done. Container removed (--rm flag)." -ForegroundColor Green
    }
    "status" {
        wsl -d kali-linux -e bash -c "docker ps --filter 'name=crawl4ai' --format '{{.Names}}: {{.Status}}'"
    }
}
