package com.example.a;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@SpringBootApplication
public class ServiceAApplication {
    private static final Logger logger = LoggerFactory.getLogger(ServiceAApplication.class);

    public static void main(String[] args) {
        logger.info("Starting ServiceAApplication...");
        SpringApplication.run(ServiceAApplication.class, args);
        logger.info("ServiceAApplication started successfully.");
    }
}
