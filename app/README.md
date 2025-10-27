# SSL Automation - Node.js Application

This is a sample Express.js application configured to work with the SSL automation Docker setup. It demonstrates proper configuration for Let's Encrypt SSL certificate generation and renewal.

## Features

- Express.js web server running on port 3000
- ACME challenge support for Let's Encrypt certificate verification
- Health check endpoint
- System information API
- Echo API endpoint for testing
- Comprehensive test coverage with Jest
- Docker-ready configuration

## Prerequisites

- Node.js (latest version)
- npm or yarn

## Installation

```bash
npm install
```

## Running the Application

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

## Testing

### Run all tests with coverage
```bash
npm test
```

### Run tests in watch mode
```bash
npm run test:watch
```

### Run tests in CI mode
```bash
npm run test:ci
```

## API Endpoints

### GET /
Returns welcome message and application version.

**Response:**
```json
{
  "message": "Welcome to SSL-secured Node.js application",
  "version": "1.0.0"
}
```

### GET /health
Health check endpoint for monitoring.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2023-10-27T12:00:00.000Z"
}
```

### GET /api/info
Returns system information.

**Response:**
```json
{
  "nodeVersion": "v18.0.0",
  "platform": "linux",
  "uptime": 123.456
}
```

### POST /api/echo
Echoes back the provided message.

**Request Body:**
```json
{
  "message": "Hello, World!"
}
```

**Response:**
```json
{
  "echo": "Hello, World!",
  "receivedAt": "2023-10-27T12:00:00.000Z"
}
```

## ACME Challenge Support

The application includes the required middleware for Let's Encrypt ACME challenges:

```javascript
app.use(express.static(path.join(__dirname, '.well-known/acme-challenge/')));
```

This allows Certbot to verify domain ownership by serving challenge files through the application.

## Test Coverage

The application includes comprehensive test coverage with:

- Unit tests for all API endpoints
- Integration tests for middleware
- Error handling tests
- Edge case validation
- HTTP method validation
- JSON parsing tests

Current coverage: **92.3%** (Lines), **83.33%** (Branches), **85.71%** (Functions)

## Docker Integration

This application is designed to run in the `nodeserver` container as part of the Docker Compose setup. The Dockerfile handles:

- Node.js installation
- Dependency installation
- Port exposure (3000)
- Application startup

## Customization

To customize this application for your needs:

1. Modify the API endpoints in `server.js`
2. Add your business logic
3. Update tests in `__tests__/` directory
4. Ensure the ACME challenge middleware remains in place
5. Keep the application running on port 3000 (or update docker-compose.yml)

## Important Notes

- **Do not remove** the ACME challenge middleware - it's required for SSL certificate generation
- The application must run on **port 3000** to work with the default Nginx configuration
- Keep the health check endpoint for monitoring purposes
- Run tests before deploying changes

## License

ISC
