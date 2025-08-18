@echo off
setlocal enabledelayedexpansion

set RELEASE_NAME=%1
set NAMESPACE=%2
set CLEAN_ALL=%3

if "%RELEASE_NAME%"=="" set RELEASE_NAME=resilience4j-stack
if "%NAMESPACE%"=="" set NAMESPACE=default
if "%1"=="--all" set CLEAN_ALL=true
if "%3"=="--all" set CLEAN_ALL=true

echo Helm Cleanup for Resilience4j Stack

echo Stopping port forwarding processes...
taskkill /F /IM kubectl.exe >nul 2>&1

if "%CLEAN_ALL%"=="true" (
    echo Cleaning ALL resilience4j Helm releases...
    
    echo Finding all resilience4j releases...
    for /f "tokens=1,2" %%a in ('helm list --all-namespaces ^| findstr resilience4j') do (
        echo Uninstalling release: %%a in namespace: %%b
        helm uninstall %%a -n %%b
    )
    
    echo Cleaning resilience4j namespaces...
    kubectl delete namespace resilience4j-local --timeout=60s >nul 2>&1
    kubectl delete namespace resilience4j-aws-single --timeout=60s >nul 2>&1
    kubectl delete namespace resilience4j-aws-multi --timeout=60s >nul 2>&1
    
) else (
    echo Cleaning Helm release: %RELEASE_NAME% in namespace: %NAMESPACE%
    
    helm list -n %NAMESPACE% | findstr %RELEASE_NAME% >nul
    if !errorlevel! equ 0 (
        echo Uninstalling Helm release: %RELEASE_NAME%
        helm uninstall %RELEASE_NAME% -n %NAMESPACE%
    ) else (
        echo Release %RELEASE_NAME% not found in namespace %NAMESPACE%
    )
    
    echo Checking if namespace can be cleaned up...
    if "%NAMESPACE:~0,12%"=="resilience4j" (
        kubectl get all -n %NAMESPACE% >nul 2>&1
        if !errorlevel! neq 0 (
            echo Deleting empty namespace: %NAMESPACE%
            kubectl delete namespace %NAMESPACE% --timeout=60s
        )
    )
)

echo Cleanup completed!
echo Remaining Helm releases:
helm list --all-namespaces | findstr resilience4j
echo Remaining namespaces:
kubectl get namespaces | findstr resilience4j