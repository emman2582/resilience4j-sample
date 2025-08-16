const axios = require('axios');

class ServiceAClient {
  constructor(baseURL) {
    // Auto-detect environment if no baseURL provided
    if (!baseURL) {
      baseURL = process.env.SERVICE_A_URL || 
                process.env.AWS_SERVICE_A_URL || 
                'http://localhost:8080';
    }
    
    this.client = axios.create({
      baseURL,
      timeout: parseInt(process.env.REQUEST_TIMEOUT) || 10000,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  async ok() {
    const response = await this.client.get('/api/a/ok');
    return response.data;
  }

  async flaky(failRate = 50) {
    const response = await this.client.get(`/api/a/flaky?failRate=${failRate}`);
    return response.data;
  }

  async slow(delayMs = 2000) {
    const response = await this.client.get(`/api/a/slow?delayMs=${delayMs}`);
    return response.data;
  }

  async bulkheadX() {
    const response = await this.client.get('/api/a/bulkhead/x');
    return response.data;
  }

  async bulkheadY() {
    const response = await this.client.get('/api/a/bulkhead/y');
    return response.data;
  }

  async limited() {
    const response = await this.client.get('/api/a/limited');
    return response.data;
  }
}

module.exports = ServiceAClient;