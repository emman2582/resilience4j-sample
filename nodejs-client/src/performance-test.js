require('dotenv').config();
const autocannon = require('autocannon');

async function runPerformanceTest() {
  const baseURL = process.env.SERVICE_A_URL || 'http://localhost:8080';
  const isAWS = process.env.NODE_ENV === 'aws';
  
  console.log('🚀 Starting performance tests...');
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'local'}`);
  console.log(`🔗 Target URL: ${baseURL}\n`);

  const tests = [
    {
      name: 'OK Endpoint',
      url: `${baseURL}/api/a/ok`,
      connections: isAWS ? 5 : 10,
      duration: isAWS ? 15 : 10
    },
    {
      name: 'Rate Limited Endpoint',
      url: `${baseURL}/api/a/limited`,
      connections: isAWS ? 3 : 5,
      duration: isAWS ? 15 : 10
    },
    {
      name: 'Bulkhead X Endpoint',
      url: `${baseURL}/api/a/bulkhead/x`,
      connections: isAWS ? 3 : 5,
      duration: isAWS ? 15 : 10
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
      console.error(`   ❌ Error testing ${test.name}: ${encodeURIComponent(error.message)}\n`);
    }
  }
}

if (require.main === module) {
  runPerformanceTest();
}

module.exports = { runPerformanceTest };