# M4ST v8.2-local — 9Router MITM Certificate Install Guide
# 
# Yeh certificate install karna ZAROORI hai taaki:
# Antigravity / Cursor / Windsurf ke LLM calls transparently
# 9Router ke through route ho sakein.
#
# Steps:
# ======
# 1. 9Router start karo: docker compose up -d ninerouter
# 2. CA cert download karo: http://localhost:20129/ca.crt
#    (Browser mein open karo ya curl se download karo)
# 3. Install karo Windows cert store mein:
#    certlm.msc → Trusted Root Certification Authorities → Certificates
#    → Right click → All Tasks → Import → Browse to ca.crt → OK
# 4. System proxy set karo:
#    Settings → Network & Internet → Proxy → Manual proxy setup
#    Address: localhost, Port: 20129, ON
#
# PowerShell se auto-install (Admin required):
# ============================================

param(
    [string]$CertPath = "$env:TEMP\9router-ca.crt"
)

Write-Host "9Router MITM Certificate Installer" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# 1. Download cert from running 9Router
Write-Host "[1] Downloading 9Router CA cert from http://localhost:20129/ca.crt ..."
try {
    Invoke-WebRequest -Uri "http://localhost:20129/ca.crt" -OutFile $CertPath
    Write-Host "[OK] Cert downloaded to $CertPath" -ForegroundColor Green
} catch {
    Write-Host "[!!] Could not download cert. Is 9Router running? (docker compose up -d ninerouter)" -ForegroundColor Yellow
    Write-Host "     Or manually download: http://localhost:20129/ca.crt" -ForegroundColor Yellow
    exit 1
}

# 2. Install into Windows Trusted Root store
Write-Host "[2] Installing cert into Windows Trusted Root store..."
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!!] Need Admin rights to install cert. Re-run as Administrator." -ForegroundColor Red
    exit 1
}
Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root
Write-Host "[OK] Certificate installed in Trusted Root store" -ForegroundColor Green

# 3. Set system proxy
Write-Host "[3] Setting system proxy to localhost:20129 ..."
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path $regPath -Name ProxyEnable   -Value 1
Set-ItemProperty -Path $regPath -Name ProxyServer   -Value "localhost:20129"
Set-ItemProperty -Path $regPath -Name ProxyOverride -Value "localhost;127.0.0.1;<local>"
Write-Host "[OK] System proxy: localhost:20129" -ForegroundColor Green

# 4. Notify WinINet
$signature = @"
[DllImport("wininet.dll")]
public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
"@
$type = Add-Type -MemberDefinition $signature -Name WinINet -Namespace WinAPI -PassThru
$type::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0)  # INTERNET_OPTION_SETTINGS_CHANGED
$type::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)  # INTERNET_OPTION_REFRESH
Write-Host "[OK] WinINet notified of proxy change" -ForegroundColor Green

Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host "  MITM Setup Complete!" -ForegroundColor Green
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host "  All IDEs (Antigravity/Cursor/Windsurf) will now"
Write-Host "  have LLM calls intercepted by 9Router."
Write-Host ""
Write-Host "  Verify: Open Antigravity, send a message."
Write-Host "  Check 9Router dashboard: http://localhost:20128/dashboard"
Write-Host "  You should see the intercepted LLM call in traces."
Write-Host ""
Write-Host "  To DISABLE proxy: run this script with -Disable flag"
Write-Host "  Or: Settings → Network → Proxy → OFF"
