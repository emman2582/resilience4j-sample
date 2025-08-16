# NodeJS Client for Resilience4j Service A

Minimal NodeJS client that consumes Resilience4j Service A microservices with performance testing capabilities.

## 🚀 Quick Start

### Prerequisites
```bash
# Install Node.js 18+ (tested with v24.6.0)
node --version  # Should be 18+
npm --version

# Windows: Install via chocolatey (run as admin)
choco install nodejs -y
```

### Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit .env for your environment:
# Local: SERVICE_A_URL=http://localhost:8080
# AWS: SERVICE_A_URL=https://your-alb-url.amazonaws.com
```

### Installation
```bash
cd nodejs-client
npm install
```

### Usage

**Local Development:**
```bash
# Run the client
npm start

# Run performance tests
npm run test:performance
```

**AWS Cloud:**
```bash
# Configure for AWS in .env file
# SERVICE_A_URL=https://your-alb-url.amazonaws.com

# Run with AWS settings
npm run start:aws
npm run test:aws
```

**Testing:**
```bash
# Unit tests (environment independent)
npm test

# All tests
npm run test:all
```

## 📋 API Endpoints

The client supports all Service A endpoints:

- `ok()` - Basic connectivity test
- `flaky(failRate)` - Circuit breaker testing
- `slow(delayMs)` - Timeout testing  
- `bulkheadX()` - Bulkhead pattern testing
- `bulkheadY()` - Bulkhead pattern testing
- `limited()` - Rate limiter testing

## 🧪 Testing

### Unit Tests
```bash
npm test
```

### Performance Tests
```bash
npm run test:performance
```

Performance tests use [autocannon](https://github.com/mcollina/autocannon) to measure:
- Requests per second
- Average latency
- Throughput
- Error rates

## 📊 Example Usage

```javascript
const ServiceAClient = require('./src/client');

const client = new ServiceAClient('http://localhost:8080');

// Test circuit breaker
const result = await client.flaky(60);
console.log(result);

// Test rate limiter
const limited = await client.limited();
console.log(limited);
```

## 🔧 Troubleshooting

### Node.js Version Issues

**"Node.js version too old"**
```bash
# Check current version
node --version

# Windows: Upgrade via chocolatey (run as admin)
choco install nodejs -y

# Alternative: Download from nodejs.org
# Restart terminal after installation
```

**"npm install fails"**
```bash
# Clear npm cache
npm cache clean --force

# Remove old dependencies
rmdir /s /q node_modules
del package-lock.json

# Reinstall
npm install
```

### Connection Issues

**"ECONNREFUSED"**
```bash
# Check if Service A is running
curl http://localhost:8080/actuator/health

# Start services from project root
cd ..
gradle :service-b:bootRun  # Terminal 1
gradle :service-a:bootRun  # Terminal 2

# Or use Docker Compose
cd docker && docker compose up -d
```

**"Port 8080 already in use"**
```bash
# Find process using port
netstat -ano | findstr :8080

# Kill process (replace PID)
taskkill /F /PID <PID>
```

**"Timeout of 5000ms exceeded"**
- Expected for bulkhead endpoints (2-5s processing time)
- Increase timeout in client.js:
```javascript
this.client = axios.create({
  timeout: 10000  // Increase to 10s
});
```

### Performance Test Issues

**"High error rates"**
- **Rate limiter**: Expected for /limited (5 req/sec limit)
- **Circuit breaker**: Reduce failRate parameter
- **Bulkhead**: Expected timeouts due to permit limits

**"Low throughput"**
- **OK endpoint**: Should be ~2000+ req/sec
- **Limited endpoint**: Should be ~5 req/sec (rate limited)
- **Bulkhead**: Should be ~30 req/sec (permit limited)

**"TimeoutNegativeWarning"**
- Harmless warning from autocannon
- Add to suppress: `node --no-warnings src/performance-test.js`

### Test Failures

**"Jest tests failing"**
```bash
# Check Node.js version
node --version  # Should be 18+

# Clear Jest cache
npx jest --clearCache

# Run with verbose output
npm test -- --verbose
```

**"Module not found"**
```bash
# Verify dependencies installed
ls node_modules

# Reinstall if missing
npm install
```

### Service Dependencies

**"Service A fails to start"**
```bash
# Service A requires Service B
# Start Service B first on port 8081
gradle :service-b:bootRun

# Wait for startup, then start Service A
gradle :service-a:bootRun
```

**"Circuit breaker always open"**
```bash
# Reset circuit breaker state
curl http://localhost:8080/actuator/circuitbreakers

# Test with lower fail rate
curl "http://localhost:8080/api/a/flaky?failRate=20"
```

### Windows-Specific Issues

**"Command not found"**
```bash
# Restart terminal after Node.js installation
# Or add to PATH manually
```

**"Permission denied"**
```bash
# Run terminal as administrator for chocolatey
# Or use regular user for npm commands
```

## ☁️ Cloud Support

The client supports both **local** and **AWS cloud** deployments:

### Local Environment
- Direct connection to localhost:8080
- Fast timeouts (10s)
- Higher concurrency (10 connections)

### AWS Cloud Environment  
- ALB/ELB endpoints
- API Gateway endpoints
- Longer timeouts (15-30s)
- Lower concurrency (3-5 connections)
- Auto-detection via environment variables

See [aws-deploy.md](aws-deploy.md) for complete AWS setup guide.

## 🏗️ Project Structure

```
nodejs-client/
├── src/
│   ├── client.js          # Service A client
│   ├── index.js           # Main application
│   └── performance-test.js # Performance testing
├── test/
│   └── client.test.js     # Unit tests
├── .env.example           # Environment template
├── aws-deploy.md          # AWS deployment guide
├── package.json           # Dependencies
└── README.md             # Documentation
```

## 📈 Latest Updates

**v1.0.0 - Current**
- ✅ Node.js v24.6.0 compatibility
- ✅ Latest dependencies (axios ^1.7.0, jest ^29.7.0)
- ✅ Performance testing with autocannon
- ✅ All Resilience4j patterns tested
- ✅ Comprehensive error handling
- ✅ Windows compatibility verified

**Performance Benchmarks** (Node.js v24.6.0):
- OK endpoint: ~2,749 req/sec
- Rate limited: ~5.5 req/sec (working as designed)
- Bulkhead X: ~29 req/sec (permit constrained)

## 🧹 Cleanup

```bash
# Stop running processes
Ctrl+C

# Clean dependencies and cache
rmdir /s /q node_modules
del package-lock.json
npm cache clean --force

# Remove environment file
del .env

# Stop services (from project root)
cd ..
taskkill /F /IM java.exe  # Stop gradle processes
```