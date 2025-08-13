    package com.example.b;

    import org.springframework.boot.SpringApplication;
    import org.springframework.boot.autoconfigure.SpringBootApplication;
    import org.slf4j.Logger;
    import org.slf4j.LoggerFactory;

    @SpringBootApplication
    public class ServiceBApplication {

        private static final Logger logger = LoggerFactory.getLogger(ServiceBApplication.class);

        public static void main(String[] args) {
            logger.info("Starting ServiceBApplication...");
            SpringApplication.run(ServiceBApplication.class, args);
            logger.info("ServiceBApplication started successfully.");
        }

        // Example method with logging
        public void exampleMethod() {
            logger.info("exampleMethod called.");
            // method logic here
            logger.debug("exampleMethod is executing logic.");
            // more logic
            logger.info("exampleMethod finished.");
        }
    }
