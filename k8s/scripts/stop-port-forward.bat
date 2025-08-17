@echo off

echo 🛑 Stopping all port forwarding processes...

echo 🔄 Stopping kubectl processes...
taskkill /F /IM kubectl.exe >nul 2>&1

timeout /t 2 >nul

echo 📊 Checking remaining processes...
tasklist /FI "IMAGENAME eq kubectl.exe" 2>nul | findstr kubectl >nul
if %errorlevel% equ 0 (
    echo ⚠️  Some kubectl processes may still be running
    echo Manual cleanup may be required
) else (
    echo ✅ All kubectl processes stopped
)

echo.
echo 📊 Port status:
for %%p in (8080 8081 9090 3000 9464) do (
    netstat -an | findstr :%%p >nul 2>&1
    if !errorlevel! equ 0 (
        echo   Port %%p: In use
    ) else (
        echo   Port %%p: Available
    )
)