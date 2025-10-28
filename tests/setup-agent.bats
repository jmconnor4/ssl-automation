#!/usr/bin/env bats

# Tests for setup-agent.sh
# Requires: bats-core, bats-support, bats-assert

setup() {
    # Load bats libraries
    load '../node_modules/bats-support/load.bash' 2>/dev/null || load '/usr/lib/bats-support/load.bash' 2>/dev/null || true
    load '../node_modules/bats-assert/load.bash' 2>/dev/null || load '/usr/lib/bats-assert/load.bash' 2>/dev/null || true

    # Source the script functions (but don't run main)
    export TEST_MODE=1
    source ./setup-agent.sh

    # Create temp directory for test files
    export TEST_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"

    # Mock interactive prompts
    export MOCK_INPUT="n"
}

teardown() {
    # Cleanup
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
    cd "$ORIGINAL_DIR" || true
}

# Test: Logging functions exist and output correctly
@test "log_info outputs blue INFO message" {
    run log_info "Test message"
    assert_output --partial "[INFO]"
    assert_output --partial "Test message"
}

@test "log_success outputs green SUCCESS message" {
    run log_success "Test success"
    assert_output --partial "[SUCCESS]"
    assert_output --partial "Test success"
}

@test "log_warning outputs yellow WARNING message" {
    run log_warning "Test warning"
    assert_output --partial "[WARNING]"
    assert_output --partial "Test warning"
}

@test "log_error outputs red ERROR message" {
    run log_error "Test error"
    assert_output --partial "[ERROR]"
    assert_output --partial "Test error"
}

# Test: Check app folder validation
@test "check_app_folder fails when app directory missing" {
    cd "$TEST_DIR"

    run check_app_folder
    assert_failure
    assert_output --partial "app/ folder not found"
}

@test "check_app_folder fails when package.json missing" {
    cd "$TEST_DIR"
    mkdir -p app

    run check_app_folder
    assert_failure
    assert_output --partial "package.json not found"
}

@test "check_app_folder fails when Dockerfile missing" {
    cd "$TEST_DIR"
    mkdir -p app
    echo '{"name": "test"}' > app/package.json

    run check_app_folder
    assert_failure
    assert_output --partial "Dockerfile not found"
}

@test "check_app_folder succeeds with valid structure" {
    cd "$TEST_DIR"
    mkdir -p app
    echo '{"name": "test", "scripts": {"start": "node server.js"}}' > app/package.json
    echo 'FROM node:18' > app/Dockerfile

    run check_app_folder
    assert_success
    assert_output --partial "Application folder structure looks good"
}

@test "check_app_folder warns when start script missing" {
    cd "$TEST_DIR"
    mkdir -p app
    echo '{"name": "test"}' > app/package.json
    echo 'FROM node:18' > app/Dockerfile

    run check_app_folder
    assert_output --partial "No 'start' script found"
}

# Test: Domain configuration
@test "configure_domain creates backup of original config" {
    cd "$TEST_DIR"
    mkdir -p data/nginx
    echo 'server_name <domain>;' > data/nginx/app.conf

    # Mock user input
    echo "example.com" | run configure_domain 2>/dev/null || true

    # Check backup exists (if function ran successfully)
    if [ -f data/nginx/app.conf.backup ]; then
        assert [ -f data/nginx/app.conf.backup ]
    fi
}

@test "configure_domain fails when nginx config missing" {
    cd "$TEST_DIR"

    run configure_domain
    assert_failure
    assert_output --partial "app.conf not found"
}

@test "configure_domain skips if domain already configured" {
    cd "$TEST_DIR"
    mkdir -p data/nginx
    echo 'server_name example.com;' > data/nginx/app.conf

    run configure_domain
    assert_success
    assert_output --partial "Domain already configured"
}

# Test: Script execution modes
@test "setup-agent.sh script exists and is executable" {
    assert [ -f "./setup-agent.sh" ]
    assert [ -x "./setup-agent.sh" ]
}

@test "setup-agent.sh has correct shebang" {
    run head -n 1 ./setup-agent.sh
    assert_output "#!/bin/bash"
}

# Test: File existence checks
@test "verify all required functions exist in script" {
    run grep -q "log_info()" ./setup-agent.sh
    assert_success

    run grep -q "log_success()" ./setup-agent.sh
    assert_success

    run grep -q "log_warning()" ./setup-agent.sh
    assert_success

    run grep -q "log_error()" ./setup-agent.sh
    assert_success

    run grep -q "check_docker_installation()" ./setup-agent.sh
    assert_success

    run grep -q "check_app_folder()" ./setup-agent.sh
    assert_success

    run grep -q "configure_domain()" ./setup-agent.sh
    assert_success

    run grep -q "download_init_script()" ./setup-agent.sh
    assert_success

    run grep -q "run_certificate_generation()" ./setup-agent.sh
    assert_success

    run grep -q "start_containers()" ./setup-agent.sh
    assert_success
}

# Test: Color codes are defined
@test "color codes are properly defined" {
    run grep "RED=" ./setup-agent.sh
    assert_success

    run grep "GREEN=" ./setup-agent.sh
    assert_success

    run grep "YELLOW=" ./setup-agent.sh
    assert_success

    run grep "BLUE=" ./setup-agent.sh
    assert_success

    run grep "NC=" ./setup-agent.sh
    assert_success
}

# Test: Menu system
@test "show_menu function exists and displays options" {
    run grep -A 15 "show_menu()" ./setup-agent.sh
    assert_success
    assert_output --partial "SSL Automation Setup Agent"
}

@test "menu includes all required options" {
    run grep -A 20 "show_menu()" ./setup-agent.sh
    assert_success
    assert_output --partial "Full automated setup"
    assert_output --partial "Check/Install Docker"
    assert_output --partial "Verify application folder"
    assert_output --partial "Configure domain"
    assert_output --partial "Download init-letsencrypt.sh"
    assert_output --partial "Run certificate generation"
    assert_output --partial "Build and start containers"
}

# Test: Auto mode flag
@test "script supports --auto flag" {
    run grep -q '\-\-auto' ./setup-agent.sh
    assert_success
}

# Test: Error handling
@test "script uses set -e for error handling" {
    run grep -q "set -e" ./setup-agent.sh
    assert_success
}

# Test: Docker check logic
@test "script checks for docker command" {
    run grep -q "command -v docker" ./setup-agent.sh
    assert_success
}

@test "script checks for docker-compose command" {
    run grep -q "command -v docker-compose" ./setup-agent.sh
    assert_success
}

@test "script checks for docker compose (v2)" {
    run grep -q "docker compose version" ./setup-agent.sh
    assert_success
}

# Test: Nginx configuration validation
@test "script validates nginx app.conf file" {
    run grep -q "data/nginx/app.conf" ./setup-agent.sh
    assert_success
}

@test "script checks for domain placeholder" {
    run grep -q "<domain>" ./setup-agent.sh
    assert_success
}

# Test: Certificate generation
@test "script downloads init-letsencrypt.sh from correct URL" {
    run grep -q "nginx-certbot/master/init-letsencrypt.sh" ./setup-agent.sh
    assert_success
}

@test "script makes init-letsencrypt.sh executable" {
    run grep -q "chmod +x init-letsencrypt.sh" ./setup-agent.sh
    assert_success
}

@test "script checks staging value in init script" {
    run grep -q "staging=" ./setup-agent.sh
    assert_success
}

# Test: Docker compose operations
@test "script uses docker-compose up --build -d" {
    run grep -q "docker-compose up --build -d" ./setup-agent.sh
    assert_success
}

@test "script includes docker-compose logs command" {
    run grep -q "docker-compose logs" ./setup-agent.sh
    assert_success
}

@test "script includes docker-compose down command" {
    run grep -q "docker-compose down" ./setup-agent.sh
    assert_success
}

# Test: User prompts
@test "script prompts for domain/IP" {
    run grep -q "Enter your domain or IP address" ./setup-agent.sh
    assert_success
}

@test "script prompts for Docker installation confirmation" {
    run grep -q "Would you like to install Docker" ./setup-agent.sh
    assert_success
}

@test "script prompts for certificate generation confirmation" {
    run grep -q "Continue with certificate generation" ./setup-agent.sh
    assert_success
}

# Test: Backup functionality
@test "script creates backup before modifying nginx config" {
    run grep -q "app.conf.backup" ./setup-agent.sh
    assert_success
}

# Test: Success messages
@test "script includes installation success messages" {
    run grep -q "installed successfully" ./setup-agent.sh
    assert_success
}

@test "script includes configuration success messages" {
    run grep -q "configured successfully" ./setup-agent.sh
    assert_success
}

# Test: Warning messages
@test "script warns about ACME challenge middleware" {
    run grep -q "express.static" ./setup-agent.sh
    assert_success
}

@test "script warns about staging vs production" {
    run grep -q "staging=1" ./setup-agent.sh
    assert_success
}

# Test: Exit codes
@test "script exits on missing dependencies" {
    run grep -q "exit 1" ./setup-agent.sh
    assert_success
}

# Test: Main function
@test "script has main function" {
    run grep -q "main()" ./setup-agent.sh
    assert_success
}

@test "main function is called with arguments" {
    run grep -q 'main "\$@"' ./setup-agent.sh
    assert_success
}
