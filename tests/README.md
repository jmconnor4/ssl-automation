# Test Suite Documentation

This directory contains both unit tests for the Node.js application and integration tests for the bash automation scripts.

## Test Structure

```
tests/
├── server.test.js              # Unit tests for Express endpoints
├── server.startup.test.js      # Unit tests for server module behavior
├── setup-agent.bats           # Tests for setup-agent.sh script (42 tests)
├── deploy-to-ec2.bats         # Tests for deploy-to-ec2.sh script (87 tests)
└── README.md                  # This file
```

## Running Tests

### All Tests
```bash
npm test
```

### Unit Tests Only (Jest)
```bash
npm run test:unit
```

### Bash Script Tests Only (BATS)
```bash
npm run test:bash
```

### Watch Mode (for development)
```bash
npm run test:watch
```

### CI Mode
```bash
npm run test:ci
```

## Test Framework

### Unit Tests (Jest)
- **Framework**: Jest 29.7.0
- **Location**: `tests/*.test.js`
- **Coverage**: Minimum 80% across all metrics
- **Dependencies**: supertest for HTTP assertions

### Bash Tests (BATS)
- **Framework**: BATS (Bash Automated Testing System)
- **Location**: `tests/*.bats`
- **Purpose**: Validate shell script structure, functions, and logic
- **Dependencies**: bats, bats-support, bats-assert

## Unit Test Coverage

### `server.test.js` (25 tests)
Tests for Express server endpoints:
- ✅ GET / - Welcome endpoint
- ✅ GET /health - Health check endpoint
- ✅ GET /api/info - System information endpoint
- ✅ POST /api/echo - Echo endpoint with validation
- ✅ 404 handler for unknown routes
- ✅ ACME challenge support
- ✅ JSON parsing and error handling
- ✅ HTTP method validation
- ✅ Response headers

### `server.startup.test.js` (3 tests)
Tests for server module behavior:
- ✅ Module exports Express app correctly
- ✅ Server doesn't auto-start when required as module
- ✅ Main module check pattern exists

## Bash Test Coverage

### `setup-agent.bats` (42 tests)

**Script Structure Tests:**
- File existence and executability
- Correct shebang (`#!/bin/bash`)
- Error handling (`set -e`)
- Color code definitions

**Function Existence Tests:**
- log_info, log_success, log_warning, log_error
- check_docker_installation
- check_app_folder
- configure_domain
- download_init_script
- run_certificate_generation
- start_containers
- show_menu, main

**Docker Installation Tests:**
- Checks for `docker` command
- Checks for `docker-compose` command
- Checks for `docker compose` (v2)
- Installation prompts and logic

**Application Validation Tests:**
- Validates `app/` directory exists
- Validates `app/package.json` exists
- Validates `app/Dockerfile` exists
- Checks for npm start script
- Warns about missing start script

**Domain Configuration Tests:**
- Validates `data/nginx/app.conf` exists
- Checks for `<domain>` placeholder
- Creates backup before modification
- Skips if already configured

**Certificate Generation Tests:**
- Downloads from correct nginx-certbot URL
- Makes init script executable
- Checks staging vs production mode
- Handles staging to production flow

**Container Management Tests:**
- Uses `docker-compose up --build -d`
- Includes logs and status commands
- Includes down command

**User Interface Tests:**
- Menu system exists and displays options
- All menu options are present
- Supports `--auto` flag for automation
- Appropriate prompts for user input

### `deploy-to-ec2.bats` (87 tests)

**Script Structure Tests:**
- File existence and executability
- Shebang and color codes
- Error handling

**Configuration Management Tests:**
- Uses `.ec2-deploy-config` file
- save_config and load_config functions
- Sets config permissions to 600
- Saves EC2_IP, PEM_FILE, EC2_USER, PROJECT_PATH

**SSH Connection Tests:**
- Tests with ConnectTimeout
- Disables StrictHostKeyChecking for initial connection
- Validates connection before proceeding

**PEM File Validation Tests:**
- Checks file existence
- Validates permissions
- Fixes permissions to 400 if needed
- Expands tilde (~) in paths

**Remote Docker Installation Tests:**
- Checks for Docker on remote
- Uses get.docker.com for installation
- Installs docker-compose
- Verifies installation

**File Transfer Tests:**
- Uses rsync for efficient transfer
- Falls back to scp if rsync unavailable
- Excludes: node_modules, .git, .env, logs
- Excludes .ec2-deploy-config

**Remote Setup Tests:**
- Runs setup-agent.sh on remote
- Makes script executable first
- Supports --auto mode
- Can restart containers after update

**Menu System Tests:**
- Full deployment option
- Configure deployment settings
- Test SSH connection
- Install Docker on EC2
- Copy files to EC2
- Run setup on EC2
- Open SSH session
- Show deployment status
- Update files only (rsync)

**User Interface Tests:**
- Prompts for EC2 IP, PEM file, username, path
- Default username: ubuntu
- Default path: ~/ssl-automation
- Asks to save configuration

**Security Tests:**
- Reminds about security group ports (22, 80, 443)
- Validates EC2 IP not empty
- Secure permission handling

## Running Specific Tests

### Run specific test file
```bash
npx jest tests/server.test.js
npx bats tests/setup-agent.bats
```

### Run specific test by name
```bash
npx jest -t "should return welcome message"
npx bats --filter "script exists" tests/setup-agent.bats
```

### Run tests with output
```bash
npx jest --verbose
npx bats --tap tests/setup-agent.bats
```

## Test Coverage Reports

After running `npm test` or `npm run test:unit`, coverage reports are generated in:
- `coverage/` - Full coverage report (HTML, LCOV, JSON)
- `coverage/lcov-report/index.html` - Interactive HTML report

To view coverage:
```bash
npm test
open coverage/lcov-report/index.html
```

## Writing New Tests

### Adding Unit Tests
1. Create test file in `tests/` directory
2. Name it `*.test.js`
3. Import the module to test
4. Write describe/it blocks using Jest
5. Run `npm test` to verify

Example:
```javascript
const request = require('supertest');
const app = require('../app/server');

describe('My Feature', () => {
  it('should do something', async () => {
    const response = await request(app).get('/my-endpoint');
    expect(response.status).toBe(200);
  });
});
```

### Adding Bash Tests
1. Create test file in `tests/` directory
2. Name it `*.bats`
3. Add test cases using `@test` syntax
4. Run `npm run test:bash` to verify

Example:
```bash
#!/usr/bin/env bats

@test "my function exists" {
  run grep -q "my_function()" ./my-script.sh
  assert_success
}
```

## CI/CD Integration

Tests run automatically on:
- Pull requests to `main` branch
- Pushes to `main` branch

See `.github/workflows/pr-checks.yml` for CI configuration.

GitHub Actions runs:
1. Unit tests (Jest) with coverage
2. Bash script tests (BATS)
3. Linting (if configured)
4. Docker build validation
5. Nginx config validation
6. Security scanning

## Troubleshooting

### BATS tests are slow
Some BATS tests source the actual scripts which can be slow. Use `--filter` to run specific tests during development.

### Jest tests fail to find modules
Make sure you're running from the project root and `node_modules` are installed in both root and `app/` directories.

### Coverage below threshold
Ensure all code paths are tested. Check `coverage/lcov-report/index.html` to see untested lines.

### Bash tests fail on file not found
Check that you're running from the project root directory where the scripts exist.

## Best Practices

1. **Keep tests focused** - One assertion per test when possible
2. **Use descriptive test names** - Test names should explain what they test
3. **Mock external dependencies** - Don't make real API calls or SSH connections
4. **Clean up after tests** - Use teardown/cleanup functions
5. **Test edge cases** - Empty inputs, null values, error conditions
6. **Maintain coverage** - Keep above 80% threshold
7. **Run tests before committing** - Ensure all tests pass locally

## Test Statistics

- **Total Test Suites**: 4 (2 Jest + 2 BATS)
- **Total Tests**: 157 (28 unit + 129 bash)
- **Code Coverage**: >80% (lines, branches, functions, statements)
- **Test Execution Time**: ~2-3 seconds (unit), ~30+ seconds (bash)
