@echo off

echo 📊 Port Forwarding Status
echo =========================

echo.
echo 🔍 Active kubectl port-forward processes:
tasklist /FI "IMAGENAME eq kubectl.exe" 2>nul | findstr kubectl || echo None found

echo.
echo 📊 Port status:
for %%p in (8080 8081 9090 3000 9464) do (
    netstat -an | findstr :%%p >nul 2>&1
    if !errorlevel! equ 0 (
        echo   Port %%p: ✅ In use
    ) else (
        echo   Port %%p: ❌ Available
    )
)

echo.
echo 🌐 If ports are active, access services at:
echo   - Service A: http://localhost:8080
echo   - Service B: http://localhost:8081
echo   - Prometheus: http://localhost:9090
echo   - Grafana: http://localhost:3000
echo   - OTel Collector: http://localhost:9464/metrics