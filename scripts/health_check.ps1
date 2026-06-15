# M4ST Local Health Check Script (Windows / Powershell)

Write-Host "=====================================" -ForegroundColor Green
Write-Host "   M4ST local stack health check" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$services = @{
    "OpenClaw"       = 3001
    "9Router"        = 20128
    "FalkorDB"       = 6379
    "Graphiti MCP"   = 8001
    "Cognee MCP"     = 8000
    "Langfuse"       = 3000
    "Uptime Kuma"    = 3002
    "OpenWork MCP"   = 8765
    "SEPCC proxy"    = 8082
}

$degraded = $false

foreach ($service in $services.Keys) {
    $port = $services[$service]
    $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
    
    if ($connection.TcpTestSucceeded) {
        Write-Host "[ONLINE] $service is running on port $port" -ForegroundColor Green
    } else {
        Write-Host "[OFFLINE] $service is down on port $port" -ForegroundColor Red
        $degraded = $true
    }
}

Write-Host "-------------------------------------"

if ($degraded) {
    Write-Host "Status: DEGRADED. Check offline services." -ForegroundColor Yellow
} else {
    Write-Host "Status: ALL SERVICES HEALTHY." -ForegroundColor Green
}
