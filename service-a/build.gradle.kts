// Plugins applied from root build.gradle.kts

dependencies {
    // Resilience4j - latest version compatible with Spring Boot 3.3.x
    implementation("io.github.resilience4j:resilience4j-spring-boot3:2.2.0")
    implementation("io.github.resilience4j:resilience4j-micrometer:2.2.0")
    
    // OpenTelemetry with proper autoconfiguration
    implementation("io.micrometer:micrometer-tracing")
    implementation("io.micrometer:micrometer-tracing-bridge-otel")
    implementation("io.opentelemetry:opentelemetry-exporter-otlp:1.32.0")
    implementation("io.opentelemetry.instrumentation:opentelemetry-instrumentation-annotations:1.32.0")
}