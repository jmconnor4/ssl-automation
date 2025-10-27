const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware for parsing JSON
app.use(express.json());

// Required for Let's Encrypt ACME challenge
app.use(express.static(path.join(__dirname, '.well-known/acme-challenge/')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Welcome to SSL-secured Node.js application',
    version: '1.0.0'
  });
});

// API endpoint example
app.get('/api/info', (req, res) => {
  res.status(200).json({
    nodeVersion: process.version,
    platform: process.platform,
    uptime: process.uptime()
  });
});

// POST endpoint example
app.post('/api/echo', (req, res) => {
  const { message } = req.body;

  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }

  res.status(200).json({
    echo: message,
    receivedAt: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found', path: req.path });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start server (only if not in test mode)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

module.exports = app;
