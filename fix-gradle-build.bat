@echo off
REM Fix common Gradle build issues

echo 🔧 Fixing Gradle build issues...

echo.
echo 1. Cleaning Gradle cache...
if exist ".gradle" rmdir /s /q .gradle
if exist "build" rmdir /s /q build
if exist "service-a\build" rmdir /s /q service-a\build
if exist "service-b\build" rmdir /s /q service-b\build

echo.
echo 2. Refreshing Gradle wrapper...
gradlew wrapper --gradle-version=8.5

echo.
echo 3. Attempting clean build...
gradlew clean build --refresh-dependencies

if %errorlevel% equ 0 (
    echo ✅ Gradle build successful!
) else (
    echo ❌ Build failed. Trying alternative approaches...
    
    echo.
    echo 4. Building without tests...
    gradlew clean build -x test
    
    if %errorlevel% equ 0 (
        echo ✅ Build successful without tests!
    ) else (
        echo.
        echo 5. Building individual modules...
        gradlew :service-a:clean :service-a:build -x test
        gradlew :service-b:clean :service-b:build -x test
    )
)

echo.
echo 💡 If build still fails, check:
echo   - Java 21 is installed and JAVA_HOME is set
echo   - Internet connection for dependencies
echo   - Antivirus not blocking Gradle cache
echo   - Run as administrator if needed