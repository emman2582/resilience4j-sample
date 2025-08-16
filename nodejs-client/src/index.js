require('dotenv').config();
const ServiceAClient = require('./client');

async function main() {
  const client = new ServiceAClient();
  
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'local'}`);
  console.log(`🔗 Service URL: ${process.env.SERVICE_A_URL || 'http://localhost:8080'}`);
  
  console.log('🚀 Testing Resilience4j Service A endpoints...\n');

  try {
    // Test basic connectivity
    console.log('✅ Testing /ok endpoint:');
    const okResult = await client.ok();
    console.log(`   Response: ${okResult}\n`);

    // Test circuit breaker
    console.log('🔄 Testing /flaky endpoint (Circuit Breaker):');
    const flakyResult = await client.flaky(30);
    console.log(`   Response: ${flakyResult}\n`);

    // Test rate limiter
    console.log('⏱️  Testing /limited endpoint (Rate Limiter):');
    const limitedResult = await client.limited();
    console.log(`   Response: ${limitedResult}\n`);

    // Test bulkhead
    console.log('🏗️  Testing /bulkhead/x endpoint:');
    const bulkheadResult = await client.bulkheadX();
    console.log(`   Response: ${bulkheadResult}\n`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Data: ${error.response.data}`);
    }
  }
}

if (require.main === module) {
  main();
}

module.exports = { main };