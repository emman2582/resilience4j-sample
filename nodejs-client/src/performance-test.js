const autocannon = require('autocannon');

async function runPerformanceTest() {
  console.log('🚀 Starting performance tests...\n');

  const tests = [
    {
      name: 'OK Endpoint',
      url: 'http://localhost:8080/api/a/ok',
      connections: 10,
      duration: 10
    },
    {
      name: 'Rate Limited Endpoint',
      url: 'http://localhost:8080/api/a/limited',
      connections: 5,
      duration: 10
    },
    {
      name: 'Bulkhead X Endpoint',
      url: 'http://localhost:8080/api/a/bulkhead/x',
      connections: 5,
      duration: 10
    }
  ];

  for (const test of tests) {
    console.log(`📊 Testing: ${test.name}`);
    
    try {
      const result = await autocannon({
        url: test.url,
        connections: test.connections,
        duration: test.duration
      });

      console.log(`   Requests/sec: ${result.requests.average}`);
      console.log(`   Latency avg: ${result.latency.average}ms`);
      console.log(`   Throughput: ${(result.throughput.average / 1024 / 1024).toFixed(2)} MB/s`);
      console.log(`   Errors: ${result.errors}`);
      console.log('');
    } catch (error) {
      console.error(`   ❌ Error testing ${test.name}: ${error.message}\n`);
    }
  }
}

if (require.main === module) {
  runPerformanceTest();
}

module.exports = { runPerformanceTest };