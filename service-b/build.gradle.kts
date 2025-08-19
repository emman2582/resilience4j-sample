// Plugins applied from root build.gradle.kts

dependencies {
    // Service B uses only common dependencies from root
    // OpenTelemetry with proper autoconfiguration
    implementation("io.micrometer:micrometer-tracing")
    implementation("io.micrometer:micrometer-tracing-bridge-otel")
    implementation("io.opentelemetry:opentelemetry-exporter-otlp:1.32.0")
    implementation("io.opentelemetry.instrumentation:opentelemetry-instrumentation-annotations:1.32.0")
}