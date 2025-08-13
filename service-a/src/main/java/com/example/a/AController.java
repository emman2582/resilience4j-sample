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
        String response = client.callFlaky(failRate);
        logger.info("Response from client.callFlaky({}): {}", failRate, response);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/slow")
    public ResponseEntity<String> slow(@RequestParam(defaultValue = "2000") long delayMs) {
        logger.info("Received request: /api/a/slow with delayMs={}", delayMs);
        String response = client.callSlowWithTimeout(delayMs);
        logger.info("Response from client.callSlowWithTimeout({}): {}", delayMs, response);
        return ResponseEntity.ok(response);
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

    @GetMapping("/limited")
    public ResponseEntity<String> limited() {
        logger.info("Received request: /api/a/limited");
        String response = client.rateLimitedCall();
        logger.info("Response from client.rateLimitedCall(): {}", response);
        return ResponseEntity.ok(response);
    }
}
