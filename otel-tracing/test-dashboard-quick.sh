#!/bin/bash

# Quick Dashboard Test - Generates data for all 7 dashboard panels in 2 minutes

BASE_URL="http://localhost:8080"

echo "⚡ Quick OpenTelemetry Dashboard Test"
echo "🎯 Generating data for all 7 dashboard panels..."

# Panel 1: Trace Reception Rate
echo "1️⃣  Trace Reception Rate..."
for i in {1..30}; do curl -s "$BASE_URL/api/a/ok" > /dev/null & done; sleep 2

# Panel 2: Request Latency (P95/P99)
echo "2️⃣  Request Latency..."
curl -s "$BASE_URL/api/a/slow?delayMs=200" > /dev/null &
curl -s "$BASE_URL/api/a/slow?delayMs=800" > /dev/null &
curl -s "$BASE_URL/api/a/slow?delayMs=1500" > /dev/null &
sleep 3

# Panel 3: Transaction Rate by Service
echo "3️⃣  Transaction Rate..."
for i in {1..20}; do 
    curl -s "$BASE_URL/api/a/ok" > /dev/null &
    curl -s "$BASE_URL/api/a/flaky?failRate=20" > /dev/null &
done; sleep 2

# Panel 4: Error Rate by Service
echo "4️⃣  Error Rate..."
for i in {1..15}; do curl -s "$BASE_URL/api/a/flaky?failRate=60" > /dev/null & done; sleep 3

# Panel 5: Circuit Breaker States
echo "5️⃣  Circuit Breaker States..."
for i in {1..25}; do curl -s "$BASE_URL/api/a/flaky?failRate=80" > /dev/null & done; sleep 5

# Panel 6: Active Requests
echo "6️⃣  Active Requests..."
for i in {1..10}; do curl -s "$BASE_URL/api/a/slow?delayMs=3000" > /dev/null & done; sleep 2

# Panel 7: Trace Export Rate
echo "7️⃣  Trace Export Rate..."
for i in {1..25}; do curl -s "$BASE_URL/api/a/ok" > /dev/null & done

echo "✅ Quick test complete! Check dashboard: http://localhost:3000"