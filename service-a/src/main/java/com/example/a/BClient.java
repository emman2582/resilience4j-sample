package com.example.a;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.ratelimiter.annotation.RateLimiter;
import io.github.resilience4j.retry.annotation.Retry;
import io.github.resilience4j.timelimiter.annotation.TimeLimiter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

@Service
public class BClient {

    private static final Logger log = LoggerFactory.getLogger(BClient.class);
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${b.url:http://localhost:8081}")
    private String baseUrl;

    /**
     * Demonstrates CircuitBreaker + Retry against a flaky downstream.
     * Fallback returns cached/default data.
     */
    @CircuitBreaker(name = "backendB", fallbackMethod = "fallbackString")
    @Retry(name = "backendB")
    public String callFlaky(int failRate) {
        return restTemplate.getForObject(baseUrl + "/api/b/flaky?failRate=" + failRate, String.class);
    }

    /**
     * Demonstrates a simple successful call.
     */
    @CircuitBreaker(name = "backendB", fallbackMethod = "fallbackString")
    public String callOk() {
        return restTemplate.getForObject(baseUrl + "/api/b/ok", String.class);
    }

    /**
     * Demonstrates TimeLimiter + fallback: wraps a blocking call into a CompletableFuture.
     */
    @TimeLimiter(name = "timelimiterB", fallbackMethod = "fallbackString")
    public String callSlowWithTimeout(long delayMs) {
        try {
            return CompletableFuture.supplyAsync(() -> 
                restTemplate.getForObject(baseUrl + "/api/b/slow?delayMs=" + delayMs, String.class)
            ).get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return "interrupted";
        } catch (ExecutionException e) {
            return "error: " + e.getCause().getMessage();
        }
    }

    /**
     * Demonstrates Semaphore Bulkhead isolation for two traffic classes.
     */
    @Bulkhead(name = "bhX", fallbackMethod = "fallbackString")
    public String bulkheadCallX() {
        busyWork();
        return restTemplate.getForObject(baseUrl + "/api/b/ok", String.class) + " [via bhX]";
    }

    @Bulkhead(name = "bhY", fallbackMethod = "fallbackString")
    public String bulkheadCallY() {
        busyWork();
        return restTemplate.getForObject(baseUrl + "/api/b/ok", String.class) + " [via bhY]";
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

    private void busyWork() {
        long x = 0;
        for (int i = 0; i < 50000; i++) x += i;
    }
}
