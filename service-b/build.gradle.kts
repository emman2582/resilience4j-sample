// Plugins applied from root build.gradle.kts

dependencies {
    // Service B uses only common dependencies from root
    // Additional metrics support for consistency
    implementation("io.micrometer:micrometer-tracing")
    runtimeOnly("io.micrometer:micrometer-tracing-bridge-brave")
}