package com.example.a;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/a")
public class AController {

    private static final Logger logger = LoggerFactory.getLogger(AController.class);

    private final BClient client;

    public AController(BClient client) {
        this.client = client;
    }

    @GetMapping("/ok")
    public ResponseEntity<String> ok() {
        logger.info("Received request: /api/a/ok");
        String response = client.callOk();
        logger.info("Response from client.callOk(): {}", response);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/flaky")
    public ResponseEntity<String> flaky(@RequestParam(defaultValue = "50") int failRate) {
        logger.info("Received request: /api/a/flaky with failRate={}", failRate);
        try {
            String response = client.callFlaky(failRate);
            logger.info("Response from client.callFlaky({}): {}", failRate, response);
            return ResponseEntity.ok(response);
        } catch (io.github.resilience4j.circuitbreaker.CallNotPermittedException e) {
            logger.warn("Circuit breaker is open: {}", e.getMessage());
            return ResponseEntity.status(503).body("Circuit breaker is open - service unavailable");
        } catch (Exception e) {
            logger.error("Exception in flaky endpoint: {}", e.getMessage());
            return ResponseEntity.status(500).body("Service error: " + e.getClass().getSimpleName());
        }
    }

    @GetMapping("/slow")
    public ResponseEntity<String> slow(@RequestParam(defaultValue = "2000") long delayMs) {
        logger.info("Received request: /api/a/slow with delayMs={}", delayMs);
        try {
            String response = client.callSlowWithTimeout(delayMs).get();
            logger.info("Response from client.callSlowWithTimeout({}): {}", delayMs, response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Exception in slow endpoint: {}", e.getMessage());
            return ResponseEntity.status(500).body("TimeLimiter Error: " + e.getClass().getSimpleName());
        }
    }

    @GetMapping("/bulkhead/x")
    public ResponseEntity<String> bulkheadX() {
        logger.info("Received request: /api/a/bulkhead/x");
        String response = client.bulkheadCallX();
        logger.info("Response from client.bulkheadCallX(): {}", response);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/bulkhead/y")
    public ResponseEntity<String> bulkheadY() {
        logger.info("Received request: /api/a/bulkhead/y");
        String response = client.bulkheadCallY();
        logger.info("Response from client.bulkheadCallY(): {}", response);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/bulkhead/stress")
    public ResponseEntity<String> bulkheadStress() {
        logger.info("Received request: /api/a/bulkhead/stress");
        String response = client.bulkheadStressX();
        logger.info("Response from client.bulkheadStressX(): {}", response);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/limited")
    public ResponseEntity<String> limited() {
        logger.info("Received request: /api/a/limited");
        String response = client.rateLimitedCall();
        logger.info("Response from client.rateLimitedCall(): {}", response);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/timeout")
    public ResponseEntity<String> timeout(@RequestParam(defaultValue = "3000") long delayMs) {
        logger.info("Received request: /api/a/timeout with delayMs={}", delayMs);
        try {
            String response = client.callWithTimeoutProtection(delayMs);
            logger.info("Response from client.callWithTimeoutProtection({}): {}", delayMs, response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Exception in timeout endpoint: {}", e.getMessage());
            return ResponseEntity.status(500).body("Timeout protection error: " + e.getClass().getSimpleName());
        }
    }

    @GetMapping("/bulkhead/info")
    public ResponseEntity<String> bulkheadInfo() {
        return ResponseEntity.ok(
            "Bulkhead Test Endpoints:\n" +
            "- /api/a/bulkhead/x (3 permits, 2s work)\n" +
            "- /api/a/bulkhead/y (2 permits, 1.5s work)\n" +
            "- /api/a/bulkhead/stress (3 permits, 5s work)\n\n" +
            "Test with concurrent requests to see metrics change:\n" +
            "curl http://localhost:8080/api/a/bulkhead/x &\n" +
            "curl http://localhost:8080/api/a/bulkhead/x &\n" +
            "curl http://localhost:8080/api/a/bulkhead/x &\n" +
            "curl http://localhost:8080/api/a/bulkhead/x &"
        );
    }
}
