const ServiceAClient = require('../src/client');

// Mock axios
jest.mock('axios');
const axios = require('axios');

describe('ServiceAClient', () => {
  let client;
  let mockAxios;

  beforeEach(() => {
    mockAxios = {
      get: jest.fn()
    };
    axios.create.mockReturnValue(mockAxios);
    client = new ServiceAClient();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('should call ok endpoint', async () => {
    mockAxios.get.mockResolvedValue({ data: 'OK from Service B' });
    
    const result = await client.ok();
    
    expect(mockAxios.get).toHaveBeenCalledWith('/api/a/ok');
    expect(result).toBe('OK from Service B');
  });

  test('should call flaky endpoint with failRate', async () => {
    mockAxios.get.mockResolvedValue({ data: 'Success' });
    
    const result = await client.flaky(30);
    
    expect(mockAxios.get).toHaveBeenCalledWith('/api/a/flaky?failRate=30');
    expect(result).toBe('Success');
  });

  test('should call slow endpoint with delay', async () => {
    mockAxios.get.mockResolvedValue({ data: 'Slow response' });
    
    const result = await client.slow(1500);
    
    expect(mockAxios.get).toHaveBeenCalledWith('/api/a/slow?delayMs=1500');
    expect(result).toBe('Slow response');
  });

  test('should handle errors', async () => {
    mockAxios.get.mockRejectedValue(new Error('Network error'));
    
    await expect(client.ok()).rejects.toThrow('Network error');
  });
});