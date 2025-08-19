@echo off

REM Quick Dashboard Test - Generates data for all 7 dashboard panels in 2 minutes

set BASE_URL=http://localhost:8080

echo ⚡ Quick OpenTelemetry Dashboard Test
echo 🎯 Generating data for all 7 dashboard panels...

REM Panel 1: Trace Reception Rate
echo 1️⃣  Trace Reception Rate...
for /l %%i in (1,1,30) do start /b curl -s "%BASE_URL%/api/a/ok" >nul
timeout /t 2 /nobreak >nul

REM Panel 2: Request Latency
echo 2️⃣  Request Latency...
start /b curl -s "%BASE_URL%/api/a/slow?delayMs=200" >nul
start /b curl -s "%BASE_URL%/api/a/slow?delayMs=800" >nul
start /b curl -s "%BASE_URL%/api/a/slow?delayMs=1500" >nul
timeout /t 3 /nobreak >nul

REM Panel 3: Transaction Rate
echo 3️⃣  Transaction Rate...
for /l %%i in (1,1,20) do (
    start /b curl -s "%BASE_URL%/api/a/ok" >nul
    start /b curl -s "%BASE_URL%/api/a/flaky?failRate=20" >nul
)
timeout /t 2 /nobreak >nul

REM Panel 4: Error Rate
echo 4️⃣  Error Rate...
for /l %%i in (1,1,15) do start /b curl -s "%BASE_URL%/api/a/flaky?failRate=60" >nul
timeout /t 3 /nobreak >nul

REM Panel 5: Circuit Breaker States
echo 5️⃣  Circuit Breaker States...
for /l %%i in (1,1,25) do start /b curl -s "%BASE_URL%/api/a/flaky?failRate=80" >nul
timeout /t 5 /nobreak >nul

REM Panel 6: Active Requests
echo 6️⃣  Active Requests...
for /l %%i in (1,1,10) do start /b curl -s "%BASE_URL%/api/a/slow?delayMs=3000" >nul
timeout /t 2 /nobreak >nul

REM Panel 7: Trace Export Rate
echo 7️⃣  Trace Export Rate...
for /l %%i in (1,1,25) do start /b curl -s "%BASE_URL%/api/a/ok" >nul

echo ✅ Quick test complete! Check dashboard: http://localhost:3000