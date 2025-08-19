package com.example.a;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.ratelimiter.annotation.RateLimiter;
import io.github.resilience4j.retry.annotation.Retry;
import io.github.resilience4j.timelimiter.annotation.TimeLimiter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

@Service
public class BClient {

    private static final Logger log = LoggerFactory.getLogger(BClient.class);
    private final RestTemplate restTemplate = new RestTemplate();
    private final RestTemplate timeoutRestTemplate = createTimeoutRestTemplate();

    @Value("${b.url:http://localhost:8081}")
    private String baseUrl;

    /**
     * Demonstrates CircuitBreaker + Retry against a flaky downstream.
     * Fallback returns cached/default data.
     */
    @CircuitBreaker(name = "backendB", fallbackMethod = "fallbackFlaky")
    @Retry(name = "backendB")
    public String callFlaky(int failRate) {
        log.info("Calling flaky endpoint with failRate: {}", failRate);
        String result = restTemplate.getForObject(baseUrl + "/api/b/flaky?failRate=" + failRate, String.class);
        log.info("Flaky call succeeded: {}", result);
        return result;
    }

    /**
     * Demonstrates a simple successful call.
     */
    @CircuitBreaker(name = "backendB", fallbackMethod = "fallbackString")
    public String callOk() {
        return restTemplate.getForObject(baseUrl + "/api/b/ok", String.class);
    }

    /**
     * Demonstrates Time Limiter with async execution.
     */
    @TimeLimiter(name = "timelimiterB", fallbackMethod = "fallbackTimeout")
    public CompletableFuture<String> callSlowWithTimeout(long delayMs) {
        log.info("Calling slow endpoint with TimeLimiter, delayMs: {}", delayMs);
        return CompletableFuture.supplyAsync(() -> {
            try {
                String result = restTemplate.getForObject(baseUrl + "/api/b/slow?delayMs=" + delayMs, String.class);
                log.info("TimeLimiter call completed: {}", result);
                return result;
            } catch (Exception e) {
                log.error("Error in TimeLimiter call: {}", e.getMessage());
                throw new RuntimeException(e);
            }
        });
    }

    /**
     * Creates RestTemplate with 2-second timeout.
     */
    private RestTemplate createTimeoutRestTemplate() {
        return new RestTemplateBuilder()
                .setConnectTimeout(Duration.ofSeconds(2))
                .setReadTimeout(Duration.ofSeconds(2))
                .build();
    }

    /**
     * Demonstrates Semaphore Bulkhead isolation for two traffic classes.
     * Uses longer processing time to make metrics visible.
     */
    @Bulkhead(name = "bhX", fallbackMethod = "fallbackString")
    public String bulkheadCallX() {
        log.info("Starting bulkheadCallX - simulating work");
        simulateWork(10000); // 10 second work for maximum visibility
        String result = restTemplate.getForObject(baseUrl + "/api/b/ok", String.class) + " [via bhX]";
        log.info("Completed bulkheadCallX");
        return result;
    }

    @Bulkhead(name = "bhY", fallbackMethod = "fallbackString")
    public String bulkheadCallY() {
        log.info("Starting bulkheadCallY - simulating work");
        simulateWork(8000); // 8 second work
        String result = restTemplate.getForObject(baseUrl + "/api/b/ok", String.class) + " [via bhY]";
        log.info("Completed bulkheadCallY");
        return result;
    }

    /**
     * Bulkhead stress test endpoint - creates high contention
     */
    @Bulkhead(name = "bhX", fallbackMethod = "fallbackString")
    public String bulkheadStressX() {
        log.info("Starting bulkheadStressX - long running task");
        simulateWork(5000); // 5 second work
        String result = restTemplate.getForObject(baseUrl + "/api/b/ok", String.class) + " [stress-bhX]";
        log.info("Completed bulkheadStressX");
        return result;
    }



    private String fallbackString(String param, Throwable t) {
        log.warn("Bulkhead fallback triggered: {}", t.getMessage());
        return "bulkhead-fallback: " + t.getClass().getSimpleName();
    }

    private String fallbackFlaky(int failRate, Throwable t) {
        log.warn("Circuit breaker fallback triggered for failRate {}: {}", failRate, t.getMessage());
        return "circuit-breaker-fallback: " + t.getClass().getSimpleName();
    }

    private String fallbackString(int param, Throwable t) {
        log.warn("Bulkhead fallback triggered: {}", t.getMessage());
        return "bulkhead-fallback: " + t.getClass().getSimpleName();
    }

    private String fallbackString(long param, Throwable t) {
        log.warn("Bulkhead fallback triggered: {}", t.getMessage());
        return "bulkhead-fallback: " + t.getClass().getSimpleName();
    }

    /**
     * Demonstrates timeout resilience using Circuit Breaker with slow call detection.
     */
    @CircuitBreaker(name = "timeoutBreaker", fallbackMethod = "fallbackTimeout")
    public String callWithTimeoutProtection(long delayMs) {
        log.info("Calling with timeout protection, delayMs: {}", delayMs);
        return timeoutRestTemplate.getForObject(baseUrl + "/api/b/slow?delayMs=" + delayMs, String.class);
    }

    /**
     * Demonstrates RateLimiter: allow only N requests per second.
     */
    @RateLimiter(name = "backendB", fallbackMethod = "fallbackString")
    public String rateLimitedCall() {
        return restTemplate.getForObject(baseUrl + "/api/b/ok", String.class) + " [rate-limited]";
    }

    private String fallbackString(Throwable t) {
        log.warn("Fallback: {}", t.getMessage());
        return "fallback-default";
    }

    private String fallbackTimeout(long delayMs, Throwable t) {
        log.warn("Timeout circuit breaker fallback for delayMs {}: {}", delayMs, t.getMessage());
        return "timeout-circuit-breaker-fallback: " + t.getClass().getSimpleName();
    }

    private CompletableFuture<String> fallbackTimeout(long delayMs, Exception e) {
        log.warn("TimeLimiter fallback triggered for delayMs {}: {}", delayMs, e.getMessage());
        return CompletableFuture.completedFuture("timelimiter-fallback: exceeded 2s timeout");
    }



    private void busyWork() {
        long x = 0;
        for (int i = 0; i < 50000; i++) x += i;
    }

    /**
     * Simulates meaningful work that takes time - makes bulkhead metrics visible
     */
    private void simulateWork(long durationMs) {
        log.info("Starting work simulation for {}ms", durationMs);
        try {
            Thread.sleep(durationMs);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Work simulation interrupted");
        }
        log.info("Completed work simulation");
    }
}
