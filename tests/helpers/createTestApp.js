const express = require('express');

/**
 * Factory function to create a test Express app
 * This simulates the app that would exist in app/server.js
 */
function createTestApp() {
  const app = express();

  // Middleware
  app.use(express.json());
  app.use(express.static('.well-known/acme-challenge/'));

  // Routes
  app.get('/', (req, res) => {
    res.json({
      message: 'Welcome to SSL-secured Node.js application',
      version: '1.0.0'
    });
  });

  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString()
    });
  });

  app.get('/api/info', (req, res) => {
    res.json({
      nodeVersion: process.version,
      platform: process.platform,
      uptime: process.uptime()
    });
  });

  app.post('/api/echo', (req, res) => {
    const { message } = req.body;

    if (!message || message.trim() === '') {
      return res.status(400).json({ error: 'Message is required' });
    }

    res.json({
      echo: message,
      receivedAt: new Date().toISOString()
    });
  });

  // 404 handler
  app.use((req, res) => {
    res.status(404).json({
      error: 'Not Found',
      path: req.path
    });
  });

  return app;
}

module.exports = createTestApp;
