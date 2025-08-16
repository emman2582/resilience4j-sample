"""
Locust Performance Tests for AWS Lambda Resilience4j Functions

This module provides comprehensive load testing for Lambda functions
implementing resilience patterns including circuit breaker, retry,
bulkhead, rate limiter, and timeout patterns.

Usage:
    locust -f load_test.py --host=https://your-api-gateway-url
"""

import random
import time
from locust import HttpUser, task, between, events
from locust.exception import RescheduleTask


class ResiliencePatternUser(HttpUser):
    """
    User class for testing resilience patterns in Lambda functions.
    
    Simulates realistic user behavior with different request patterns
    and validates resilience pattern responses.
    """
    
    # Wait time between requests (1-3 seconds)
    wait_time = between(1, 3)
    
    def on_start(self):
        """Initialize user session and perform health check."""
        # WARNING: SSL verification disabled for testing only
        # In production, use proper SSL certificates
        self.client.verify = False
        
        # Perform initial health check
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed: {response.status_code}")

    @task(30)
    def test_normal_operation(self):
        """Test normal operation endpoint (30% of requests)."""
        with self.client.get("/api/a/ok", name="normal_operation") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Normal operation failed: {response.status_code}")

    @task(20)
    def test_circuit_breaker(self):
        """Test circuit breaker pattern with varying failure rates (20% of requests)."""
        fail_rate = random.randint(20, 80)
        
        with self.client.get(
            f"/api/a/flaky?failRate={fail_rate}",
            name="circuit_breaker"
        ) as response:
            # Circuit breaker should handle failures gracefully
            if response.status_code in [200, 500]:
                response.success()
                
                # Check for fallback response
                if response.status_code == 200:
                    try:
                        data = response.json()
                        if data.get('fallback'):
                            print(f"Circuit breaker fallback triggered (fail_rate: {fail_rate}%)")
                    except:
                        pass
            else:
                response.failure(f"Unexpected circuit breaker response: {response.status_code}")

    @task(15)
    def test_timeout_pattern(self):
        """Test timeout and fallback pattern (15% of requests)."""
        delay_ms = random.randint(500, 4000)
        
        with self.client.get(
            f"/api/a/slow?delayMs={delay_ms}",
            name="timeout_pattern"
        ) as response:
            # Should succeed or provide fallback
            if response.status_code == 200:
                response.success()
                
                try:
                    data = response.json()
                    if data.get('fallback'):
                        print(f"Timeout fallback triggered (delay: {delay_ms}ms)")
                except (ValueError, KeyError) as e:
                    print(f"Failed to parse response JSON: {e}")
            else:
                response.failure(f"Timeout pattern failed: {response.status_code}")

    @task(15)
    def test_bulkhead_pattern(self):
        """Test bulkhead isolation pattern (15% of requests)."""
        bulkhead_type = random.choice(['x', 'y'])
        
        with self.client.get(
            f"/api/a/bulkhead/{bulkhead_type}",
            name=f"bulkhead_{bulkhead_type}"
        ) as response:
            # Should succeed or be rejected due to bulkhead limits
            if response.status_code in [200, 429]:
                response.success()
                
                if response.status_code == 429:
                    print(f"Bulkhead {bulkhead_type} limit exceeded")
            else:
                response.failure(f"Bulkhead pattern failed: {response.status_code}")

    @task(10)
    def test_rate_limiter(self):
        """Test rate limiter pattern (10% of requests)."""
        with self.client.get("/api/a/limited", name="rate_limiter") as response:
            # Should succeed or be rate limited
            if response.status_code in [200, 429]:
                response.success()
                
                if response.status_code == 429:
                    print("Rate limiter triggered")
            else:
                response.failure(f"Rate limiter failed: {response.status_code}")

    @task(5)
    def test_service_b_direct(self):
        """Test Service B directly for comparison (5% of requests)."""
        endpoint = random.choice(['ok', 'flaky?failRate=30', 'slow?delayMs=1000'])
        
        with self.client.get(f"/{endpoint}", name="service_b_direct") as response:
            # Service B responses vary based on endpoint
            if response.status_code in [200, 500]:
                response.success()
            else:
                response.failure(f"Service B direct call failed: {response.status_code}")

    @task(5)
    def test_health_check(self):
        """Periodic health checks (5% of requests)."""
        with self.client.get("/health", name="health_check") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed: {response.status_code}")


class StressTestUser(HttpUser):
    """
    Stress test user for high-load scenarios.
    
    Generates aggressive load to test system limits and
    resilience pattern behavior under stress.
    """
    
    wait_time = between(0.1, 0.5)  # Aggressive load
    
    @task(50)
    def stress_circuit_breaker(self):
        """Stress test circuit breaker with high failure rates."""
        fail_rate = random.randint(60, 90)
        
        with self.client.get(
            f"/api/a/flaky?failRate={fail_rate}",
            name="stress_circuit_breaker"
        ) as response:
            if response.status_code in [200, 500]:
                response.success()
            else:
                response.failure(f"Stress circuit breaker failed: {response.status_code}")

    @task(30)
    def stress_rate_limiter(self):
        """Stress test rate limiter with rapid requests."""
        with self.client.get("/api/a/limited", name="stress_rate_limiter") as response:
            if response.status_code in [200, 429]:
                response.success()
            else:
                response.failure(f"Stress rate limiter failed: {response.status_code}")

    @task(20)
    def stress_bulkhead(self):
        """Stress test bulkhead with concurrent requests."""
        bulkhead_type = random.choice(['x', 'y'])
        
        with self.client.get(
            f"/api/a/bulkhead/{bulkhead_type}",
            name="stress_bulkhead"
        ) as response:
            if response.status_code in [200, 429]:
                response.success()
            else:
                response.failure(f"Stress bulkhead failed: {response.status_code}")


class ChaosTestUser(HttpUser):
    """
    Chaos engineering user for unpredictable load patterns.
    
    Simulates chaotic user behavior to test system resilience
    under unpredictable conditions.
    """
    
    wait_time = between(0, 2)
    
    @task
    def chaos_requests(self):
        """Generate chaotic request patterns."""
        # Random endpoint selection
        endpoints = [
            "/api/a/ok",
            "/api/a/flaky?failRate=50",
            "/api/a/slow?delayMs=2000",
            "/api/a/bulkhead/x",
            "/api/a/bulkhead/y",
            "/api/a/limited"
        ]
        
        endpoint = random.choice(endpoints)
        
        with self.client.get(endpoint, name="chaos_request") as response:
            # Accept any reasonable response
            if response.status_code in [200, 429, 500]:
                response.success()
            else:
                response.failure(f"Chaos request failed: {response.status_code}")
        
        # Random additional delay
        if random.random() < 0.3:
            time.sleep(random.uniform(0, 1))


# Event handlers for custom metrics and logging
@events.request.add_listener
def on_request(request_type, name, response_time, response_length, exception, context, **kwargs):
    """Log request details for analysis."""
    if exception:
        print(f"Request failed: {name} - {exception}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Initialize test environment."""
    print("Starting AWS Lambda resilience pattern performance tests...")
    print(f"Target URL: {environment.host}")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Clean up after test completion."""
    print("Performance tests completed.")
    print("Check Locust web UI for detailed results and metrics.")


# Custom task sets for specific scenarios
from locust import TaskSet

class CircuitBreakerTaskSet(TaskSet):
    """Focused testing of circuit breaker pattern."""
    
    @task
    def test_circuit_breaker_progression(self):
        """Test circuit breaker state progression."""
        # Start with low failure rate
        for fail_rate in [10, 30, 50, 70, 90]:
            with self.client.get(
                f"/api/a/flaky?failRate={fail_rate}",
                name=f"cb_progression_{fail_rate}"
            ) as response:
                if response.status_code in [200, 500]:
                    response.success()
                else:
                    response.failure(f"CB progression failed: {response.status_code}")
            
            time.sleep(0.1)


class BulkheadTaskSet(TaskSet):
    """Focused testing of bulkhead pattern."""
    
    @task(70)
    def test_bulkhead_x(self):
        """Test bulkhead X heavily."""
        with self.client.get("/api/a/bulkhead/x", name="bulkhead_x_focused") as response:
            if response.status_code in [200, 429]:
                response.success()
            else:
                response.failure(f"Bulkhead X failed: {response.status_code}")
    
    @task(30)
    def test_bulkhead_y(self):
        """Test bulkhead Y lightly."""
        with self.client.get("/api/a/bulkhead/y", name="bulkhead_y_focused") as response:
            if response.status_code in [200, 429]:
                response.success()
            else:
                response.failure(f"Bulkhead Y failed: {response.status_code}")


# Example usage and configuration
if __name__ == "__main__":
    print("Locust performance test configuration loaded.")
    print("Run with: locust -f load_test.py --host=https://your-api-gateway-url")
    print("Available user classes:")
    print("  - ResiliencePatternUser (default)")
    print("  - StressTestUser")
    print("  - ChaosTestUser")