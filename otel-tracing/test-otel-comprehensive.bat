@echo off
setlocal enabledelayedexpansion

REM Comprehensive OpenTelemetry Test Script for Windows
REM Generates data for all Grafana dashboard panels

set BASE_URL=http://localhost:8080
set DURATION=300
set CONCURRENT_USERS=5

echo 🚀 Starting comprehensive OpenTelemetry test...
echo 📊 Generating data for Grafana dashboard panels
echo ⏱️  Test duration: %DURATION% seconds
echo 👥 Concurrent users: %CONCURRENT_USERS%

REM Function to check services
:check_services
echo 🏥 Checking service health...
curl -s %BASE_URL%/actuator/health | findstr "UP" >nul
if errorlevel 1 (
    echo ❌ Service A is not responding
    exit /b 1
) else (
    echo ✅ Service A is healthy
)

curl -s http://localhost:8081/actuator/health | findstr "UP" >nul
if errorlevel 1 (
    echo ❌ Service B is not responding
    exit /b 1
) else (
    echo ✅ Service B is healthy
)
goto :eof

REM Function to generate circuit breaker data
:generate_circuit_breaker_data
echo 🔴 Generating Circuit Breaker data...
for /l %%i in (1,1,20) do (
    start /b curl -s "%BASE_URL%/api/a/flaky?failRate=80" >nul
    timeout /t 1 /nobreak >nul
)
timeout /t 5 /nobreak >nul
for /l %%i in (1,1,10) do (
    start /b curl -s "%BASE_URL%/api/a/flaky?failRate=80" >nul
    timeout /t 1 /nobreak >nul
)
goto :eof

REM Function to generate timeout data
:generate_timeout_data
echo ⏰ Generating Timeout data...
for /l %%i in (1,1,15) do (
    start /b curl -s "%BASE_URL%/api/a/slow?delayMs=3000" >nul
    timeout /t 1 /nobreak >nul
)
goto :eof

REM Function to generate bulkhead data
:generate_bulkhead_data
echo 🚧 Generating Bulkhead data...
for /l %%i in (1,1,10) do (
    start /b curl -s "%BASE_URL%/api/a/bulkhead/x" >nul
)
for /l %%i in (1,1,8) do (
    start /b curl -s "%BASE_URL%/api/a/bulkhead/y" >nul
)
timeout /t 2 /nobreak >nul
goto :eof

REM Function to generate rate limiter data
:generate_rate_limiter_data
echo 🚦 Generating Rate Limiter data...
for /l %%i in (1,1,20) do (
    start /b curl -s "%BASE_URL%/api/a/limited" >nul
)
timeout /t 1 /nobreak >nul
goto :eof

REM Function to generate normal traffic
:generate_normal_traffic
echo ✅ Generating Normal traffic...
for /l %%i in (1,1,30) do (
    start /b curl -s "%BASE_URL%/api/a/ok" >nul
    timeout /t 1 /nobreak >nul
)
goto :eof

REM Function to generate retry data
:generate_retry_data
echo 🔄 Generating Retry pattern data...
for /l %%i in (1,1,15) do (
    start /b curl -s "%BASE_URL%/api/a/flaky?failRate=40" >nul
    timeout /t 1 /nobreak >nul
)
goto :eof

REM Test specific dashboard panels
:test_dashboard_panels
echo 📊 Testing specific dashboard panels...

echo   📡 Generating traces for reception rate...
for /l %%i in (1,1,50) do (
    start /b curl -s "%BASE_URL%/api/a/ok" >nul
)

echo   ⏱️  Generating latency variations...
start /b curl -s "%BASE_URL%/api/a/slow?delayMs=100" >nul
start /b curl -s "%BASE_URL%/api/a/slow?delayMs=500" >nul
start /b curl -s "%BASE_URL%/api/a/slow?delayMs=1000" >nul
start /b curl -s "%BASE_URL%/api/a/slow?delayMs=2000" >nul

echo   📈 Generating transaction rate data...
for /l %%i in (1,1,25) do (
    start /b curl -s "%BASE_URL%/api/a/ok" >nul
    start /b curl -s "%BASE_URL%/api/a/flaky?failRate=10" >nul
)

echo   ❌ Generating error rate data...
for /l %%i in (1,1,10) do (
    start /b curl -s "%BASE_URL%/api/a/flaky?failRate=70" >nul
)

echo   🔴 Triggering circuit breaker states...
call :generate_circuit_breaker_data

echo   🔄 Creating active request load...
for /l %%i in (1,1,15) do (
    start /b curl -s "%BASE_URL%/api/a/slow?delayMs=2000" >nul
)

echo   📤 Generating trace export data...
for /l %%i in (1,1,40) do (
    start /b curl -s "%BASE_URL%/api/a/ok" >nul
)

timeout /t 3 /nobreak >nul
goto :eof

REM Performance test
:run_performance_test
echo 🏃 Running performance test for 60 seconds...
set /a perf_end=%time:~6,2%+1
for /l %%t in (1,1,60) do (
    for /l %%u in (1,1,%CONCURRENT_USERS%) do (
        start /b curl -s "%BASE_URL%/api/a/ok" >nul
        start /b curl -s "%BASE_URL%/api/a/flaky?failRate=20" >nul
        start /b curl -s "%BASE_URL%/api/a/slow?delayMs=500" >nul
    )
    timeout /t 1 /nobreak >nul
)
goto :eof

REM Comprehensive test cycles
:run_comprehensive_test
echo 🔄 Running comprehensive test cycles...
for /l %%c in (1,1,10) do (
    echo 🔄 Test cycle %%c at %time%
    
    start /b call :generate_normal_traffic
    start /b call :generate_circuit_breaker_data
    start /b call :generate_timeout_data
    start /b call :generate_bulkhead_data
    start /b call :generate_rate_limiter_data
    start /b call :generate_retry_data
    
    echo 📈 Cycle %%c complete, waiting 10s...
    timeout /t 10 /nobreak >nul
)
goto :eof

REM Main execution
:main
call :check_services
if errorlevel 1 exit /b 1

echo 🎯 Starting dashboard panel tests...
call :test_dashboard_panels

echo 🚀 Starting comprehensive test...
start /b call :run_comprehensive_test

echo 🏃 Starting performance test...
call :run_performance_test

echo ✅ All tests completed!
echo 📊 Check Grafana dashboard: http://localhost:3000
echo 🔍 Check Jaeger traces: http://localhost:16686
echo 📈 Check Prometheus: http://localhost:9090

goto :eof

call :main