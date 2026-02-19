@echo off
REM ============================================================================
REM STARTUP SCRIPT FOR CLOUDFLARE TUNNEL + FASTAPI + FLOWER SERVER
REM ============================================================================
REM
REM This batch file starts all services needed for production:
REM   1. FastAPI backend (port 8002)
REM   2. Flower HTTP server (port 8265) - optional
REM   3. Cloudflare Tunnel
REM
REM Run this once to start everything. It will keep running.
REM
REM ============================================================================

REM Set working directory
cd /d %~dp0

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

REM Set log file with timestamp
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set LOGFILE=logs\production-%mydate%_%mytime%.log

echo.
echo ============================================================================
echo STARTING PRODUCTION SERVICES
echo ============================================================================
echo.
echo Logs will be saved to: %LOGFILE%
echo.

REM Start FastAPI backend
echo.
echo [%time%] Starting FastAPI backend on port 8002...
echo [%time%] Starting FastAPI backend on port 8002... >> %LOGFILE%
start "FastAPI Backend" cmd /k ".\.venv311\Scripts\python.exe -m uvicorn api.main:app --host 0.0.0.0 --port 8002 >> %LOGFILE% 2>&1"

REM Wait for backend to start
echo [%time%] Waiting for backend to start...
timeout /t 5 /nobreak

REM Optional: Start Flower server (comment out if not needed)
echo.
echo [%time%] Starting Flower HTTP server on port 8265 (optional)...
echo [%time%] Starting Flower HTTP server on port 8265... >> %LOGFILE%
start "Flower Server" cmd /k "cd fl_server && ..\\.venv311\Scripts\celery.exe -A flower_app worker --loglevel=info >> ..\%LOGFILE% 2>&1"

REM Wait for both services
timeout /t 3 /nobreak

REM Start Cloudflare Tunnel
echo.
echo [%time%] Starting Cloudflare Tunnel...
echo [%time%] Starting Cloudflare Tunnel... >> %LOGFILE%
echo.
echo Tunnel command:
echo   cloudflared tunnel --config %%USERPROFILE%%\.cloudflared\config.yml run federated-backend
echo.
start "Cloudflare Tunnel" cmd /k "cloudflared tunnel --config %USERPROFILE%\.cloudflared\config.yml run federated-backend >> %LOGFILE% 2>&1"

REM Wait for tunnel to start
timeout /t 3 /nobreak

echo.
echo ============================================================================
echo SERVICES STARTED
echo ============================================================================
echo.
echo Services running:
echo   - FastAPI Backend: http://localhost:8002
echo   - Flower Server: http://localhost:8265 (optional)
echo   - Cloudflare Tunnel: Connecting...
echo.
echo Publicly accessible:
echo   - API: https://api.YOUR_DOMAIN.com (update with your domain!)
echo   - Docs: https://api.YOUR_DOMAIN.com/docs
echo   - Health: https://api.YOUR_DOMAIN.com/health
echo.
echo Logs: %LOGFILE%
echo.
echo To stop all services:
echo   1. Close each window (FastAPI, Flower, Tunnel)
echo   2. Or run: %~dp0STOP_SERVICES.bat
echo.
echo ============================================================================
echo.
echo Monitoring... Press Ctrl+C to view logs or close windows to stop services.
pause
