const express = require('express');

/**
 * SSL Automation Test Server
 * This is a test/example server for the SSL automation setup
 */
function createApp() {
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

// Start server if this file is run directly
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  const app = createApp();

  const server = app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
  });

  // Graceful shutdown
  process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
      console.log('HTTP server closed');
    });
  });

  process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    server.close(() => {
      console.log('HTTP server closed');
      process.exit(0);
    });
  });
}

module.exports = createApp;
