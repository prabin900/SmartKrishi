# SmartKrishi - One Click Startup Script
# Run this every time you want to start the project: .\start.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SmartKrishi - Starting Services..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ROOT = $PSScriptRoot

# Step 1: Clean up ports 8080 and 3000
Write-Host "[1/4] Checking ports 8080 and 3000..." -ForegroundColor Yellow
$existing8080 = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($existing8080) {
    foreach ($conn in $existing8080) {
        if ($conn.OwningProcess -gt 0) {
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "      Killed old process on port 8080." -ForegroundColor Gray
    Start-Sleep -Seconds 2
} else {
    Write-Host "      Port 8080 is free." -ForegroundColor Gray
}

$existing3000 = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
if ($existing3000) {
    foreach ($conn in $existing3000) {
        if ($conn.OwningProcess -gt 0) {
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "      Killed old process on port 3000." -ForegroundColor Gray
    Start-Sleep -Seconds 2
} else {
    Write-Host "      Port 3000 is free." -ForegroundColor Gray
}

# Step 2: Delete MongoDB lock files (caused by unclean shutdown)
Write-Host "[2/4] Cleaning MongoDB lock files..." -ForegroundColor Yellow
Remove-Item -Path "$ROOT\backend\mongodb-data\mongod.lock" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ROOT\backend\mongodb-data\WiredTiger.lock" -Force -ErrorAction SilentlyContinue
Write-Host "      Lock files cleaned." -ForegroundColor Gray

# Step 3: Start Backend in a new window
Write-Host "[3/4] Starting Backend (Spring Boot)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ROOT\backend'; mvn spring-boot:run" -WindowStyle Normal
Write-Host "      Backend starting... (wait ~12 seconds for it to be ready)" -ForegroundColor Gray

# Step 4: Wait for backend then start Flutter
Write-Host "[4/4] Waiting 12s for backend, then launching Flutter Web..." -ForegroundColor Yellow
Start-Sleep -Seconds 12
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ROOT\frontend'; flutter run -d chrome --web-port 3000" -WindowStyle Normal

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  SmartKrishi is starting!" -ForegroundColor Green
Write-Host "  Backend:  http://localhost:8080" -ForegroundColor Green
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Open Chrome: http://localhost:3000" -ForegroundColor Cyan
