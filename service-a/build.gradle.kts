plugins {
    id("java")
    id("org.springframework.boot") version "3.3.2"
    id("io.spring.dependency-management")
}

group = "com.example"
version = "0.1.0"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-aop")

    // Resilience4j Spring Boot 3 integration
    implementation("io.github.resilience4j:resilience4j-spring-boot3:2.2.0")

    // Micrometer + Prometheus
    implementation("io.micrometer:micrometer-registry-prometheus")

    // OpenTelemetry (Micrometer Tracing bridge + OTLP exporter for traces)
    implementation("io.micrometer:micrometer-tracing-bridge-otel")
    implementation("io.opentelemetry:opentelemetry-exporter-otlp")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
}
