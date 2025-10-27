#!/usr/bin/env bats

# Tests for deploy-to-ec2.sh
# Requires: bats-core, bats-support, bats-assert

setup() {
    # Load bats libraries
    load '../node_modules/bats-support/load.bash' 2>/dev/null || load '/usr/lib/bats-support/load.bash' 2>/dev/null || true
    load '../node_modules/bats-assert/load.bash' 2>/dev/null || load '/usr/lib/bats-assert/load.bash' 2>/dev/null || true

    # Create temp directory for test files
    export TEST_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
}

teardown() {
    # Cleanup
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
    cd "$ORIGINAL_DIR" || true
}

# Test: Script exists and is executable
@test "deploy-to-ec2.sh script exists and is executable" {
    assert [ -f "./deploy-to-ec2.sh" ]
    assert [ -x "./deploy-to-ec2.sh" ]
}

@test "deploy-to-ec2.sh has correct shebang" {
    run head -n 1 ./deploy-to-ec2.sh
    assert_output "#!/bin/bash"
}

# Test: Color codes are defined
@test "deploy script defines color codes" {
    run grep "RED=" ./deploy-to-ec2.sh
    assert_success

    run grep "GREEN=" ./deploy-to-ec2.sh
    assert_success

    run grep "YELLOW=" ./deploy-to-ec2.sh
    assert_success

    run grep "BLUE=" ./deploy-to-ec2.sh
    assert_success
}

# Test: Logging functions
@test "deploy script has log_info function" {
    run grep -q "log_info()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has log_success function" {
    run grep -q "log_success()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has log_warning function" {
    run grep -q "log_warning()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has log_error function" {
    run grep -q "log_error()" ./deploy-to-ec2.sh
    assert_success
}

# Test: Configuration management
@test "deploy script uses config file" {
    run grep -q "CONFIG_FILE=" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has save_config function" {
    run grep -q "save_config()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has load_config function" {
    run grep -q "load_config()" ./deploy-to-ec2.sh
    assert_success
}

@test "config file is set to .ec2-deploy-config" {
    run grep 'CONFIG_FILE=".ec2-deploy-config"' ./deploy-to-ec2.sh
    assert_success
}

# Test: Required functions exist
@test "deploy script has gather_info function" {
    run grep -q "gather_info()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has test_ssh_connection function" {
    run grep -q "test_ssh_connection()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has check_remote_docker function" {
    run grep -q "check_remote_docker()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has install_remote_docker function" {
    run grep -q "install_remote_docker()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has copy_files_to_ec2 function" {
    run grep -q "copy_files_to_ec2()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has run_remote_setup function" {
    run grep -q "run_remote_setup()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has open_ssh_session function" {
    run grep -q "open_ssh_session()" ./deploy-to-ec2.sh
    assert_success
}

# Test: SSH connection testing
@test "deploy script tests SSH with timeout" {
    run grep -q "ConnectTimeout" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script disables strict host key checking for initial connection" {
    run grep -q "StrictHostKeyChecking=no" ./deploy-to-ec2.sh
    assert_success
}

# Test: Docker installation on EC2
@test "deploy script checks for docker on remote" {
    run grep -q "command -v docker" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script uses get.docker.com for installation" {
    run grep -q "get.docker.com" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script installs docker-compose on remote" {
    run grep -q "docker-compose" ./deploy-to-ec2.sh
    assert_success
}

# Test: File transfer
@test "deploy script uses rsync for efficient transfer" {
    run grep -q "rsync" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script falls back to scp if rsync unavailable" {
    run grep -q "scp -r" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script excludes node_modules" {
    run grep -q "node_modules" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script excludes .git directory" {
    run grep -q "\.git" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script excludes .env files" {
    run grep -q "\.env" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script excludes config file" {
    run grep -q ".ec2-deploy-config" ./deploy-to-ec2.sh
    assert_success
}

# Test: Remote setup execution
@test "deploy script runs setup-agent.sh on remote" {
    run grep -q "setup-agent.sh" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script makes setup-agent.sh executable on remote" {
    run grep -q "chmod +x setup-agent.sh" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script can run setup in auto mode" {
    run grep -q "\-\-auto" ./deploy-to-ec2.sh
    assert_success
}

# Test: Menu system
@test "deploy script has show_menu function" {
    run grep -q "show_menu()" ./deploy-to-ec2.sh
    assert_success
}

@test "menu includes full deployment option" {
    run grep -A 20 "show_menu()" ./deploy-to-ec2.sh
    assert_output --partial "Full deployment"
}

@test "menu includes configure deployment settings" {
    run grep -A 20 "show_menu()" ./deploy-to-ec2.sh
    assert_output --partial "Configure deployment settings"
}

@test "menu includes test SSH connection" {
    run grep -A 20 "show_menu()" ./deploy-to-ec2.sh
    assert_output --partial "Test SSH connection"
}

@test "menu includes install Docker on EC2" {
    run grep -A 20 "show_menu()" ./deploy-to-ec2.sh
    assert_output --partial "Install Docker on EC2"
}

@test "menu includes copy files option" {
    run grep -A 20 "show_menu()" ./deploy-to-ec2.sh
    assert_output --partial "Copy files to EC2"
}

@test "menu includes open SSH session" {
    run grep -A 20 "show_menu()" ./deploy-to-ec2.sh
    assert_output --partial "Open SSH session"
}

# Test: User prompts
@test "deploy script prompts for EC2 IP" {
    run grep -q "Enter EC2 Public IP" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script prompts for PEM file" {
    run grep -q "path to your .pem key file" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script prompts for EC2 username" {
    run grep -q "Enter EC2 username" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script has default EC2 username" {
    run grep -q "ubuntu" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script prompts for remote deployment path" {
    run grep -q "remote deployment path" ./deploy-to-ec2.sh
    assert_success
}

# Test: PEM file validation
@test "deploy script checks if PEM file exists" {
    run grep -q '\[ -f "\$PEM_FILE" \]' ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script checks PEM file permissions" {
    run grep -q "stat.*\$PEM_FILE" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script fixes PEM file permissions" {
    run grep -q "chmod 400" ./deploy-to-ec2.sh
    assert_success
}

# Test: Configuration saving
@test "deploy script saves EC2_IP to config" {
    run grep -q "EC2_IP=" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script saves PEM_FILE to config" {
    run grep -q "PEM_FILE=" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script saves EC2_USER to config" {
    run grep -q "EC2_USER=" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script saves PROJECT_PATH to config" {
    run grep -q "PROJECT_PATH=" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script sets config file permissions to 600" {
    run grep -q "chmod 600.*CONFIG_FILE" ./deploy-to-ec2.sh
    assert_success
}

# Test: Update functionality
@test "deploy script has update_files function" {
    run grep -q "update_files()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script can restart containers after update" {
    run grep -q "docker-compose up --build -d" ./deploy-to-ec2.sh
    assert_success
}

# Test: Status checking
@test "deploy script has show_status function" {
    run grep -q "show_status()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script checks remote container status" {
    run grep -q "docker-compose ps" ./deploy-to-ec2.sh
    assert_success
}

# Test: Full deployment
@test "deploy script has full_deployment function" {
    run grep -q "full_deployment()" ./deploy-to-ec2.sh
    assert_success
}

# Test: Error handling
@test "deploy script uses set -e" {
    run grep -q "set -e" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script validates EC2 IP not empty" {
    run grep -q 'if \[ -z "\$EC2_IP" \]' ./deploy-to-ec2.sh
    assert_success
}

# Test: Security group reminders
@test "deploy script reminds about security group ports" {
    run grep -q "80 and 443" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script reminds about SSH port" {
    run grep -q "port 22" ./deploy-to-ec2.sh
    assert_success
}

# Test: Main function
@test "deploy script has main function" {
    run grep -q "main()" ./deploy-to-ec2.sh
    assert_success
}

@test "deploy script calls main with arguments" {
    run grep -q 'main "\$@"' ./deploy-to-ec2.sh
    assert_success
}

# Test: Auto mode
@test "deploy script supports auto mode flag" {
    run grep -q 'if \[ "\$1" == "--auto" \]' ./deploy-to-ec2.sh
    assert_success
}

# Test: Tilde expansion for paths
@test "deploy script expands tilde in PEM file path" {
    run grep -q "HOME" ./deploy-to-ec2.sh
    assert_success
}
