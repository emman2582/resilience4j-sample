package com.example.b;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Random;

@RestController
public class BController {

    private static final Logger log = LoggerFactory.getLogger(BController.class);
    private final Random random = new Random();

    @GetMapping("/api/b/ok")
    public ResponseEntity<String> ok() {
        log.info("B /ok called");
        return ResponseEntity.ok("B says OK");
    }

    @GetMapping("/api/b/slow")
    public ResponseEntity<String> slow(@RequestParam(defaultValue = "2000") long delayMs) {
        log.info("B /slow called, delay {}ms", delayMs);
        try {
            Thread.sleep(delayMs);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return ResponseEntity.ok("B finally responded after " + delayMs + "ms");
    }

    @GetMapping("/api/b/flaky")
    public ResponseEntity<String> flaky(@RequestParam(defaultValue = "50") int failRate) {
        int r = random.nextInt(100);
        log.info("B /flaky called, failRate {}%, roll {}", failRate, r);
        if (r < failRate) {
            return ResponseEntity.internalServerError().body("B failed randomly");
        }
        return ResponseEntity.ok("B succeeded this time");
    }
}
