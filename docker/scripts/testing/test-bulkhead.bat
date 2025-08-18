@echo off
REM Bulkhead Testing Script for Windows
REM This script generates concurrent requests to test bulkhead behavior

echo 🔧 Bulkhead Testing Script
echo ==========================

set SERVICE_URL=http://localhost:8080

echo.
echo 📊 Current Bulkhead Metrics (before load):
curl -s %SERVICE_URL%/actuator/prometheus | findstr bulkhead

echo.
echo 🚀 Starting concurrent requests to bulkhead/x (3 permits)...
echo This will create contention and make metrics visible

REM Generate 6 concurrent requests to bhX (which has only 3 permits)
for /L %%i in (1,1,6) do (
    echo Starting request %%i to bulkhead/x...
    start /B curl -s "%SERVICE_URL%/api/a/bulkhead/x" > nul
)

echo.
echo ⏳ Waiting 3 seconds for some requests to start...
timeout /t 3 /nobreak > nul

echo.
echo 📊 Bulkhead Metrics (during load):
curl -s %SERVICE_URL%/actuator/prometheus | findstr bulkhead

echo.
echo 🚀 Starting concurrent requests to bulkhead/y (2 permits)...

REM Generate 4 concurrent requests to bhY (which has only 2 permits)
for /L %%i in (1,1,4) do (
    echo Starting request %%i to bulkhead/y...
    start /B curl -s "%SERVICE_URL%/api/a/bulkhead/y" > nul
)

echo.
echo ⏳ Waiting 5 seconds...
timeout /t 5 /nobreak > nul

echo.
echo 📊 All Bulkhead Metrics (during mixed load):
curl -s %SERVICE_URL%/actuator/prometheus | findstr bulkhead

echo.
echo ⏳ Waiting for all requests to complete...
timeout /t 10 /nobreak > nul

echo.
echo 📊 Final Bulkhead Metrics (after load):
curl -s %SERVICE_URL%/actuator/prometheus | findstr bulkhead

echo.
echo ✅ Test completed!
echo.
echo 🔍 Available Bulkhead Metrics:
echo - resilience4j_bulkhead_available_concurrent_calls: Available permits
echo - resilience4j_bulkhead_max_allowed_concurrent_calls: Maximum permits
echo.
echo 📈 To see metrics in Grafana:
echo 1. Go to http://localhost:3000
echo 2. Use query: resilience4j_bulkhead_available_concurrent_calls
echo 3. Use query: resilience4j_bulkhead_max_allowed_concurrent_calls - resilience4j_bulkhead_available_concurrent_calls