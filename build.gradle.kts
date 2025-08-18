plugins {
    java
    id("org.springframework.boot") version "3.3.4" apply false
    id("io.spring.dependency-management") version "1.1.6" apply false
}

allprojects {
    group = "com.example"
    version = "0.1.0"
    
    repositories {
        mavenCentral()
    }
}

subprojects {
    apply(plugin = "java")
    apply(plugin = "org.springframework.boot")
    apply(plugin = "io.spring.dependency-management")
    
    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(21))
        }
    }
    
    dependencies {
        // Spring Boot starters
        implementation("org.springframework.boot:spring-boot-starter-web")
        implementation("org.springframework.boot:spring-boot-starter-actuator")
        implementation("org.springframework.boot:spring-boot-starter-aop")
        
        // Metrics and monitoring
        implementation("io.micrometer:micrometer-registry-prometheus")
        implementation("io.micrometer:micrometer-core")
        
        // Testing
        testImplementation("org.springframework.boot:spring-boot-starter-test")
    }
    
    tasks.withType<Test> {
        useJUnitPlatform()
    }
}