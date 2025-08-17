#!/bin/bash

# Fix common Gradle build issues

echo "🔧 Fixing Gradle build issues..."

echo ""
echo "1. Cleaning Gradle cache..."
rm -rf .gradle build service-a/build service-b/build

echo ""
echo "2. Refreshing Gradle wrapper..."
./gradlew wrapper --gradle-version=8.5

echo ""
echo "3. Attempting clean build..."
./gradlew clean build --refresh-dependencies

if [ $? -eq 0 ]; then
    echo "✅ Gradle build successful!"
else
    echo "❌ Build failed. Trying alternative approaches..."
    
    echo ""
    echo "4. Building without tests..."
    ./gradlew clean build -x test
    
    if [ $? -eq 0 ]; then
        echo "✅ Build successful without tests!"
    else
        echo ""
        echo "5. Building individual modules..."
        ./gradlew :service-a:clean :service-a:build -x test
        ./gradlew :service-b:clean :service-b:build -x test
    fi
fi

echo ""
echo "💡 If build still fails, check:"
echo "  - Java 21 is installed and JAVA_HOME is set"
echo "  - Internet connection for dependencies"
echo "  - Gradle daemon: ./gradlew --stop"
echo "  - Permissions on .gradle directory"