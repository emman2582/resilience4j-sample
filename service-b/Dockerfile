# Build and run Service B
FROM gradle:8.7.0-jdk21-alpine AS build
WORKDIR /workspace
COPY ../.. /workspace
RUN gradle :service-b:bootJar --no-daemon

FROM eclipse-temurin:21-jre
WORKDIR /app
# Create logs directory
RUN mkdir -p /app/logs
COPY --from=build /workspace/service-b/build/libs/service-b-*.jar /app/app.jar

ENV JAVA_OPTS="-XX:+UseG1GC -Dlogging.config=classpath:logback-spring.xml"
EXPOSE 8081
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
