# ================================================================
# M4ST v8.2-local — Windows Task Scheduler Setup
# Run as Administrator in PowerShell
# Sets up the full nightly autonomous cycle (11 PM – 7 AM)
# ================================================================
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\setup_task_scheduler.ps1
# ================================================================

$M4ST_WSL = "/home/anuj/m4st"
$VENV_ACTIVATE = "source $M4ST_WSL/.venv/bin/activate"

$wslDistroName = "Ubuntu"
$wslCheck2 = Get-Command wsl -ErrorAction SilentlyContinue
if ($wslCheck2) {
    $wslDistros = wsl -l -v 2>&1
    if ($wslDistros -match "kali-linux") {
        $wslDistroName = "kali-linux"
    }
}

function New-M4STTask {
    param($Name, $Time, $Script, $Description)
    $cmd = "$VENV_ACTIVATE && python $M4ST_WSL/$Script >> $M4ST_WSL/logs/automation_log.jsonl 2>&1"
    $action   = New-ScheduledTaskAction -Execute "wsl" -Argument "-d $wslDistroName -e bash -c '$cmd'"
    $trigger  = New-ScheduledTaskTrigger -Daily -At $Time
    $settings = New-ScheduledTaskSettingsSet `
        -ExecutionTimeLimit (New-TimeSpan -Hours 4) `
        -WakeToRun $false `
        -StartWhenAvailable $true
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest

    Unregister-ScheduledTask -TaskName "M4ST-$Name" -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask `
        -TaskName "M4ST-$Name" `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description $Description
    Write-Host "[OK] Task registered: M4ST-$Name at $Time" -ForegroundColor Green
}

Write-Host "Setting up M4ST Nightly Task Scheduler..." -ForegroundColor Cyan

# Power plan — no sleep on AC
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 30
Write-Host "[OK] Power plan: sleep disabled on AC, monitor off after 30min" -ForegroundColor Green

# ── Nightly cycle task (Sequential Runner) ──────────────────────────
New-M4STTask -Name "SequentialRunner" -Time "23:00" -Script "scripts/run_all_crews.py" -Description "M4ST: Sequential execution of all nightly crews and tasks"


# ── Docker Desktop startup on login ─────────────────────────────────
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    $dockerAction = New-ScheduledTaskAction -Execute $dockerPath
    $loginTrigger = New-ScheduledTaskTrigger -AtLogOn
    $dockerSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 0)

    Unregister-ScheduledTask -TaskName "M4ST-DockerAutoStart" -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask `
        -TaskName "M4ST-DockerAutoStart" `
        -Action $dockerAction `
        -Trigger $loginTrigger `
        -Settings $dockerSettings `
        -Description "M4ST: Start Docker Desktop on login"
    Write-Host "[OK] Docker Desktop auto-start on login registered" -ForegroundColor Green
} else {
    Write-Host "[!!] Docker Desktop not found at $dockerPath — skipping auto-start" -ForegroundColor Yellow
}

# ── Morning container cleanup (7:30 AM) ─────────────────────────────
$cleanupCmd = "docker container prune -f && docker system prune -f --volumes=false"
$cleanupAction  = New-ScheduledTaskAction -Execute "wsl" -Argument "-d $wslDistroName -e bash -c '$cleanupCmd'"
$cleanupTrigger = New-ScheduledTaskTrigger -Daily -At "07:30"
$cleanupSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

Unregister-ScheduledTask -TaskName "M4ST-DockerCleanup" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask `
    -TaskName "M4ST-DockerCleanup" `
    -Action $cleanupAction `
    -Trigger $cleanupTrigger `
    -Settings $cleanupSettings `
    -Description "M4ST: Morning Docker container prune"
Write-Host "[OK] Morning Docker cleanup at 7:30 AM registered" -ForegroundColor Green

# ── Show all M4ST tasks ──────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  M4ST Scheduled Tasks:" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Get-ScheduledTask | Where-Object { $_.TaskName -like "M4ST-*" } | `
    Format-Table TaskName, State -AutoSize

Write-Host ""
Write-Host "⚠ IMPORTANT: DRY RUN FIRST before activating!" -ForegroundColor Yellow
Write-Host "  Run each crew manually once. Verify Langfuse traces." -ForegroundColor Yellow
Write-Host "  Only THEN leave PC on for the nightly window." -ForegroundColor Yellow
Write-Host ""
Write-Host "🥀 Task Scheduler setup complete — @m4stanuj" -ForegroundColor Magenta
