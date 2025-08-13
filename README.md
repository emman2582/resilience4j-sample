# Resilience4j + Spring Boot (Java) Sample — Gradle Kotlin DSL

This multi-module project demonstrates **circuit breaker, retry, timeout, bulkhead, and rate limiter** patterns using **Resilience4j** with **Spring Boot 3**, built via **Gradle (Kotlin DSL)**. It also exposes **Prometheus** metrics and enables **OpenTelemetry** tracing (OTLP).

**Modules**
- `service-a` — client-facing API that calls Service B and applies resilience patterns
- `service-b` — a downstream API that can be ok/slow/flaky

> Languages/tech used: Resilience4j, Gradle, Kotlin (Gradle Kotlin DSL), Java, Spring Boot

---

## Quick start

### Prereqs
- JDK 21+
- Gradle 8.5+ (or just use the `gradle` Docker images in the provided Dockerfiles)
choco install openjdk --version=21.0.0 -y
choco install gradle --version=8.5.0 -y


### Build
```bash
gradle clean build
```

### Run locally
Run **Service B** (port **8081**) first, then **Service A** (port **8080**):

```bash
gradle :service-b:bootRun
gradle :service-a:bootRun
```

### Exercise the endpoints
- OK path (A→B):  
  `curl http://localhost:8080/api/a/ok`
- Flaky path (A→B) — triggers **Retry + CircuitBreaker**:  
  `curl "http://localhost:8080/api/a/flaky?failRate=60"`
- Slow path (A→B) — triggers **TimeLimiter + fallback**:  
  `curl "http://localhost:8080/api/a/slow?delayMs=2500"`
- Bulkhead X/Y (A→B) — isolates resource pools:  
  `curl http://localhost:8080/api/a/bulkhead/x`  
  `curl http://localhost:8080/api/a/bulkhead/y`
- Rate-limited (A→B):  
  `curl http://localhost:8080/api/a/limited`

### Metrics & health
- Prometheus scrape endpoint:  
  `http://localhost:8080/actuator/prometheus` (A)  
  `http://localhost:8081/actuator/prometheus` (B)
- Health:  
  `http://localhost:8080/actuator/health`

> **Tracing:** This project includes Micrometer tracing with **OpenTelemetry bridge** and **OTLP exporter**. Point `management.otlp.tracing.endpoint` to your OTel Collector to emit traces. We’ll wire Prometheus + Grafana in a follow-up docker-compose as requested.

---

## What each pattern looks like

- **Circuit Breaker** (`@CircuitBreaker`): stops calling B after a failure threshold and uses a fallback.
- **Retry** (`@Retry`): automatically retries transient failures before failing or tripping the breaker.
- **TimeLimiter** (`@TimeLimiter` on a `CompletableFuture`): cancels slow calls after a deadline and returns a fallback.
- **Bulkhead** (`@Bulkhead(type=THREADPOOL)`): isolates thread pools for different traffic classes so one noisy neighbor can’t hog all threads.
- **RateLimiter** (`@RateLimiter`): limits how many requests per period can pass through.

Configuration lives in `service-a/src/main/resources/application.yml`.

---

## Docker

### Option A: build JARs locally, then build images
```bash
gradle :service-b:bootJar :service-a:bootJar

# From service-b directory
cd service-b
docker build -t r4j-sample-service-b:0.1.0 .

# From service-a directory
cd ../service-a
docker build -t r4j-sample-service-a:0.1.0 .
```

### Option B: let Docker do the Gradle build (multi-stage)
Just run `docker build` in each service directory. The Dockerfile uses a Gradle builder stage.

Run the containers:
```bash
# Service B first
docker run --rm -p 8081:8081 --name b r4j-sample-service-b:0.1.0

# In another shell, Service A
docker run --rm -p 8080:8080 --name a   -e B_URL="http://host.docker.internal:8081"   r4j-sample-service-a:0.1.0
```

> On Linux, replace `host.docker.internal` with the host IP or use a user-defined network and container name resolution.

---

## Configuration highlights

**`service-a/src/main/resources/application.yml`**
- Resilience4j instances `backendB`, `timelimiterB`, `bhX`, `bhY`
- Prometheus metrics enabled
- Tracing sampling set to 100%
- `b.url` defines Service B base URL (default `http://localhost:8081`)

**`service-b/src/main/resources/application.yml`**
- Prometheus metrics enabled

---

## Project layout

```
resilience4j-sample/
├─ build.gradle.kts
├─ settings.gradle.kts
├─ service-a/
│  ├─ build.gradle.kts
│  ├─ Dockerfile
│  └─ src/main/{java,resources}/...
└─ service-b/
   ├─ build.gradle.kts
   ├─ Dockerfile
   └─ src/main/{java,resources}/...
```

---

## Notes

- This sample intentionally keeps it simple: RestTemplate + annotations. In production you may choose **WebClient** (reactive) and more granular configuration (per-route).
- For bulkheads to show impact, hit `/bulkhead/x` and `/bulkhead/y` with high concurrency (e.g., `hey`, `wrk`, or `ab`) and observe independent thread pools.
- To observe **circuit breaker** states and other metrics, scrape the Prometheus endpoint or query actuator `metrics` endpoints.

Enjoy tripping breakers (in the safe way)!

## Docker Compose

You can run both Service A and Service B together using Docker Compose:

1. Build both images as described above.
2. Create a `docker-compose.yml` file in the project root with the following content:

    ```yaml
    version: "3.8"
    services:
      service-b:
        image: r4j-sample-service-b:0.1.0
        container_name: service-b
        ports:
          - "8081:8081"
        networks:
          - r4j-net

      service-a:
        image: r4j-sample-service-a:0.1.0
        container_name: service-a
        ports:
          - "8080:8080"
        environment:
          - B_URL=http://service-b:8081
        depends_on:
          - service-b
        networks:
          - r4j-net

    networks:
      r4j-net:
        driver: bridge
    ```

3. Start both containers:

    ```sh
    docker compose up
    ```

4. Access the Prometheus endpoints:

    - [http://localhost:8080/actuator/prometheus](http://localhost:8080/actuator/prometheus) (Service A)
    - [http://localhost:8081/actuator/prometheus](http://localhost:8081/actuator/prometheus) (Service B)

To stop and remove the containers, run:

```sh
docker compose down

============================
Prometheus UI: http://localhost:9090
Grafana UI: http://localhost:3000 (default login: admin / admin)
Service A metrics: http://localhost:8080/actuator/prometheus
Service B metrics: http://localhost:8081/actuator/prometheus

========================
## Grafana Dashboard Setup

1. **Access Grafana**  
   Open [http://localhost:3000](http://localhost:3000) in your browser.  
   Login with the default credentials:  
   - **Username:** `admin`  
   - **Password:** `admin`  

2. **Add Prometheus as a Data Source**  
   - Go to **Gear (⚙️) > Data Sources**.
   - Click **Add data source**.
   - Select **Prometheus**.
   - Set the URL to `http://prometheus:9090`.
   - Click **Save & Test**. You should see a success message.

3. **Import a Dashboard**  
   - Go to **+ > Import**.
   - You can use a community dashboard (e.g., [Resilience4j dashboard](https://grafana.com/grafana/dashboards/12139-resilience4j-dashboard/)) or create your own.
   - For a quick start, paste the dashboard ID `12139` and click **Load**.
   - Select your Prometheus data source and click **Import**.

4. **Explore Metrics**  
   - Use the dashboard panels or **Explore** tab to query metrics like:
     - `resilience4j_circuitbreaker_state`
     - `resilience4j_retry_calls`
     - `resilience4j_timelimiter_calls`
     - `http_server_requests_seconds_count`
   - You can also visualize JVM, Spring Boot, and custom application metrics.

---

**Note:**  
- The provided `prometheus.yml` configures Prometheus to scrape both Service A and Service B at `/actuator/prometheus`.
- For OpenTelemetry, ensure your services are exporting traces to your collector or backend. Grafana can visualize traces if a compatible data source is configured.

Enjoy monitoring and analyzing your microservices!