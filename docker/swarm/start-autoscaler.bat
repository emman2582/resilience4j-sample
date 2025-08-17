@echo off
REM Start Docker Autoscaler (Windows)

echo 🤖 Starting Docker Autoscaler...

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python is required for autoscaler
    echo 💡 Install Python from: https://www.python.org/downloads/
    exit /b 1
)

echo 🐍 Using Python: python

REM Install required Python packages
echo 📦 Installing Python dependencies...
pip install requests

REM Check if Docker Swarm is active
docker info | findstr "Swarm: active" >nul
if %errorlevel% neq 0 (
    echo ❌ Docker Swarm is not active. Run setup-swarm.sh first
    exit /b 1
)

REM Start autoscaler
echo 🚀 Starting autoscaler...
python autoscaler.py