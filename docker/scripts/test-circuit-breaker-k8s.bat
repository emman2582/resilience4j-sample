@echo off
echo 🔧 Circuit Breaker Test (Kubernetes)
echo ====================================

echo.
echo 📊 Initial circuit breaker state:
curl -s http://localhost:8080/actuator/prometheus | findstr "resilience4j_circuitbreaker_state"

echo.
echo 🧪 Testing Service B directly with high fail rate:
for /L %%i in (1,1,3) do (
    echo Direct call %%i to Service B:
    curl -s "http://localhost:8081/api/b/flaky?failRate=90"
    echo.
)

echo.
echo 🚀 Testing through Service A with high fail rate (should trigger circuit breaker):
echo Making 10 requests with 95%% failure rate...

for /L %%i in (1,1,10) do (
    echo Request %%i:
    curl -s "http://localhost:8080/api/a/flaky?failRate=95"
    echo.
    timeout /t 1 /nobreak >nul
)

echo.
echo 📊 Circuit breaker state after load:
curl -s http://localhost:8080/actuator/prometheus | findstr "resilience4j_circuitbreaker_state"

echo.
echo 📊 Circuit breaker call counts:
curl -s http://localhost:8080/actuator/prometheus | findstr "resilience4j_circuitbreaker_calls_seconds_count"

echo.
echo 📊 Circuit breaker failure rate:
curl -s http://localhost:8080/actuator/prometheus | findstr "resilience4j_circuitbreaker_failure_rate"

echo.
echo 🔍 Testing if circuit breaker is open (should return fallback):
for /L %%i in (1,1,3) do (
    echo Test call %%i:
    curl -s "http://localhost:8080/api/a/flaky?failRate=95"
    echo.
)

echo.
echo 📊 Final circuit breaker metrics:
curl -s http://localhost:8080/actuator/prometheus | findstr "resilience4j_circuitbreaker"