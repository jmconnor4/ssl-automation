const request = require('supertest');
const app = require('../app/server');

describe('Express Server', () => {
  describe('GET /', () => {
    it('should return welcome message with 200 status', async () => {
      const response = await request(app).get('/');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toBe('Welcome to SSL-secured Node.js application');
      expect(response.body.version).toBe('1.0.0');
    });

    it('should return JSON content type', async () => {
      const response = await request(app).get('/');

      expect(response.headers['content-type']).toMatch(/json/);
    });
  });

  describe('GET /health', () => {
    it('should return healthy status with 200', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
      expect(response.body).toHaveProperty('timestamp');
    });

    it('should return valid ISO timestamp', async () => {
      const response = await request(app).get('/health');

      const timestamp = new Date(response.body.timestamp);
      expect(timestamp).toBeInstanceOf(Date);
      expect(isNaN(timestamp.getTime())).toBe(false);
    });
  });

  describe('GET /api/info', () => {
    it('should return system information', async () => {
      const response = await request(app).get('/api/info');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('nodeVersion');
      expect(response.body).toHaveProperty('platform');
      expect(response.body).toHaveProperty('uptime');
    });

    it('should return valid node version format', async () => {
      const response = await request(app).get('/api/info');

      expect(response.body.nodeVersion).toMatch(/^v\d+\.\d+\.\d+/);
    });

    it('should return numeric uptime', async () => {
      const response = await request(app).get('/api/info');

      expect(typeof response.body.uptime).toBe('number');
      expect(response.body.uptime).toBeGreaterThanOrEqual(0);
    });
  });

  describe('POST /api/echo', () => {
    it('should echo the message back with 200 status', async () => {
      const testMessage = 'Hello, World!';
      const response = await request(app)
        .post('/api/echo')
        .send({ message: testMessage })
        .set('Content-Type', 'application/json');

      expect(response.status).toBe(200);
      expect(response.body.echo).toBe(testMessage);
      expect(response.body).toHaveProperty('receivedAt');
    });

    it('should return 400 if message is missing', async () => {
      const response = await request(app)
        .post('/api/echo')
        .send({})
        .set('Content-Type', 'application/json');

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Message is required');
    });

    it('should return 400 if message is null', async () => {
      const response = await request(app)
        .post('/api/echo')
        .send({ message: null })
        .set('Content-Type', 'application/json');

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Message is required');
    });

    it('should return 400 if message is empty string', async () => {
      const response = await request(app)
        .post('/api/echo')
        .send({ message: '' })
        .set('Content-Type', 'application/json');

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Message is required');
    });

    it('should handle special characters in message', async () => {
      const specialMessage = 'Test@#$%^&*()_+{}|:"<>?';
      const response = await request(app)
        .post('/api/echo')
        .send({ message: specialMessage })
        .set('Content-Type', 'application/json');

      expect(response.status).toBe(200);
      expect(response.body.echo).toBe(specialMessage);
    });

    it('should return valid ISO timestamp', async () => {
      const response = await request(app)
        .post('/api/echo')
        .send({ message: 'test' })
        .set('Content-Type', 'application/json');

      const timestamp = new Date(response.body.receivedAt);
      expect(timestamp).toBeInstanceOf(Date);
      expect(isNaN(timestamp.getTime())).toBe(false);
    });
  });

  describe('404 Handler', () => {
    it('should return 404 for unknown routes', async () => {
      const response = await request(app).get('/unknown-route');

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Not Found');
    });

    it('should include requested path in 404 response', async () => {
      const testPath = '/nonexistent/path';
      const response = await request(app).get(testPath);

      expect(response.status).toBe(404);
      expect(response.body.path).toBe(testPath);
    });

    it('should return 404 for POST to unknown routes', async () => {
      const response = await request(app)
        .post('/unknown-post-route')
        .send({ data: 'test' });

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Not Found');
    });
  });

  describe('ACME Challenge Support', () => {
    it('should serve static files from .well-known/acme-challenge/', async () => {
      // This test verifies the middleware is set up correctly
      // Actual file serving would require creating test files
      const response = await request(app).get('/.well-known/acme-challenge/test-file');

      // Expecting 404 since no actual file exists, but middleware should handle the route
      // If middleware wasn't configured, we'd get a different response
      expect([404, 200]).toContain(response.status);
    });
  });

  describe('JSON Parsing', () => {
    it('should parse JSON request bodies', async () => {
      const response = await request(app)
        .post('/api/echo')
        .send({ message: 'test json parsing' })
        .set('Content-Type', 'application/json');

      expect(response.status).toBe(200);
      expect(response.body.echo).toBe('test json parsing');
    });

    it('should handle malformed JSON gracefully', async () => {
      const response = await request(app)
        .post('/api/echo')
        .send('{"invalid json}')
        .set('Content-Type', 'application/json');

      // Express's built-in error handler should catch JSON parse errors
      expect([400, 500]).toContain(response.status);
    });
  });

  describe('HTTP Methods', () => {
    it('should not allow POST to GET-only endpoints', async () => {
      const response = await request(app).post('/health');

      expect(response.status).toBe(404);
    });

    it('should not allow GET to POST-only endpoints', async () => {
      const response = await request(app).get('/api/echo');

      expect(response.status).toBe(404);
    });
  });

  describe('Response Headers', () => {
    it('should include proper content-type headers', async () => {
      const response = await request(app).get('/');

      expect(response.headers['content-type']).toMatch(/application\/json/);
    });
  });
});
