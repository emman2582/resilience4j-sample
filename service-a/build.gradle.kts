// Plugins applied from root build.gradle.kts

dependencies {
    // Resilience4j - latest version compatible with Spring Boot 3.3.x
    implementation("io.github.resilience4j:resilience4j-spring-boot3:2.2.0")
    implementation("io.github.resilience4j:resilience4j-micrometer:2.2.0")
    
    // Additional metrics support
    implementation("io.micrometer:micrometer-tracing")
    runtimeOnly("io.micrometer:micrometer-tracing-bridge-brave")
}