// Plugins applied from root build.gradle.kts

dependencies {
    // Service A specific dependencies
    implementation("org.springframework.boot:spring-boot-starter-aop")
    implementation("io.github.resilience4j:resilience4j-spring-boot3:2.2.0")
}
