# ============================================================================
# STARTUP SCRIPT FOR CLOUDFLARE TUNNEL + FASTAPI + FLOWER SERVER
# PowerShell Version
# ============================================================================
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File ".\START_PRODUCTION.ps1"
#
# Or in PowerShell:
#   . .\START_PRODUCTION.ps1
#
# This script starts all services needed for production:
#   1. FastAPI backend (port 8002)
#   2. Flower HTTP server (port 8265) - optional
#   3. Cloudflare Tunnel
#
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"

# Set working directory
Set-Location -Path $PSScriptRoot

# Create logs directory
if (!(Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Set log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LOGFILE = "logs\production-$timestamp.log"

Write-Host ""
Write-Host "============================================================================"
Write-Host "STARTING PRODUCTION SERVICES"
Write-Host "============================================================================"
Write-Host ""
Write-Host "Logs will be saved to: $LOGFILE"
Write-Host ""

# Function to log messages
function Log-Message {
    param([string]$message)
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] $message"
    "[$time] $message" | Add-Content -Path $LOGFILE -Encoding UTF8
}

# Kill any existing processes on ports (optional - comment out if not needed)
Write-Host ""
Write-Host "Checking for existing services on ports 8002, 8265..."
Write-Host ""

$procs = Get-NetTcpConnection -State Listen -ErrorAction SilentlyContinue | Where-Object {
    $_.LocalPort -eq 8002 -or $_.LocalPort -eq 8265
}

if ($procs) {
    Write-Host "Found existing services. Stopping them..."
    foreach ($proc in $procs) {
        Get-Process -Id $proc.OwningProcess -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Log-Message "Killed process on port $($proc.LocalPort)"
    }
    Start-Sleep -Seconds 2
}

# Start FastAPI backend
Log-Message "Starting FastAPI backend on port 8002..."
Write-Host "Opening FastAPI terminal..."

$fastApiCommand = {
    cd $args[0]
    .\.venv311\Scripts\python.exe -m uvicorn api.main:app --host 0.0.0.0 --port 8002 2>&1 | Tee-Object -FilePath $args[1] -Append
}

$fastApiJob = Start-Job -ScriptBlock $fastApiCommand -ArgumentList $PSScriptRoot, $LOGFILE -Name "FastAPI"

# Wait for backend to start
Start-Sleep -Seconds 5

# Verify backend is running
$backendCheck = Invoke-RestMethod -Uri "http://localhost:8002/health" -Method Get -ErrorAction SilentlyContinue
if ($backendCheck) {
    Log-Message "✅ FastAPI backend started successfully"
    Log-Message "Backend status: $($backendCheck | ConvertTo-Json)"
} else {
    Log-Message "⚠️  FastAPI may not have started. Check logs."
}

# Optional: Start Flower server
Write-Host ""
Write-Host "Starting Flower HTTP server (optional)..."
Write-Host "If you don't use Flower, this can be skipped."
Write-Host ""

$flowerCommand = {
    cd "$($args[0])\fl_server"
    ..\\.venv311\Scripts\python.exe -m flower --port=8265 2>&1 | Tee-Object -FilePath $args[1] -Append
}

$flowerJob = Start-Job -ScriptBlock $flowerCommand -ArgumentList $PSScriptRoot, $LOGFILE -Name "Flower"

Start-Sleep -Seconds 3

# Start Cloudflare Tunnel
Log-Message "Starting Cloudflare Tunnel..."
Write-Host ""
Write-Host "Cloudflare Tunnel will run in a new window..."
Write-Host ""

$tunnelCommand = {
    cloudflared tunnel --config $env:USERPROFILE\.cloudflared\config.yml run federated-backend 2>&1 | Tee-Object -FilePath $args[0] -Append
}

$tunnelJob = Start-Job -ScriptBlock $tunnelCommand -ArgumentList $LOGFILE -Name "CloudflareTunnel"

Start-Sleep -Seconds 3

# Display status
Write-Host ""
Write-Host "============================================================================"
Write-Host "SERVICES STARTED"
Write-Host "============================================================================"
Write-Host ""
Write-Host "Background Jobs:"
Get-Job | Select-Object Name, Id, State, PSBeginTime | Format-Table -AutoSize
Write-Host ""
Write-Host "Services running:"
Write-Host "  - FastAPI Backend: http://localhost:8002"
Write-Host "  - Flower Server: http://localhost:8265 (optional)"
Write-Host "  - Cloudflare Tunnel: Connecting..."
Write-Host ""
Write-Host "Publicly accessible:"
Write-Host "  - API: https://api.YOUR_DOMAIN.com (update with your domain!)"
Write-Host "  - Docs: https://api.YOUR_DOMAIN.com/docs"
Write-Host "  - Health: https://api.YOUR_DOMAIN.com/health"
Write-Host ""
Write-Host "Logs: $LOGFILE"
Write-Host ""
Write-Host "To stop all services:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\STOP_PRODUCTION.ps1"
Write-Host ""
Write-Host "Or manually:"
Write-Host "  Stop-Job -Name FastAPI"
Write-Host "  Stop-Job -Name Flower"
Write-Host "  Stop-Job -Name CloudflareTunnel"
Write-Host ""
Write-Host "============================================================================"
Write-Host ""

# Keep script running and show logs
Write-Host "Monitoring logs (Ctrl+C to stop):"
Write-Host ""

# Stream logs
while ($true) {
    if (Test-Path $LOGFILE) {
        $newLines = Get-Content -Path $LOGFILE -Tail 5 -ErrorAction SilentlyContinue
        if ($newLines) {
            # Clear previous output and show latest
            Write-Host -NoNewLine "."
        }
    }
    Start-Sleep -Seconds 2
}

# Note: User would Ctrl+C here to stop, then manually close service windows
