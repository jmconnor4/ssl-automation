#!/bin/bash

# AWS EC2 Deployment Agent
# Automates deployment to AWS EC2 instances

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration file
CONFIG_FILE=".ec2-deploy-config"

# Save configuration
save_config() {
    cat > $CONFIG_FILE <<EOF
EC2_IP=$1
PEM_FILE=$2
EC2_USER=$3
PROJECT_PATH=$4
EOF
    chmod 600 $CONFIG_FILE
    log_success "Configuration saved to $CONFIG_FILE"
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source $CONFIG_FILE
        log_info "Loaded configuration from $CONFIG_FILE"
        return 0
    fi
    return 1
}

# Gather deployment information
gather_info() {
    log_info "EC2 Deployment Configuration"
    echo ""

    # Try to load existing config
    if load_config; then
        log_info "Previous configuration found:"
        log_info "  EC2 IP: $EC2_IP"
        log_info "  PEM File: $PEM_FILE"
        log_info "  EC2 User: $EC2_USER"
        log_info "  Project Path: $PROJECT_PATH"
        echo ""
        read -p "Use previous configuration? (y/n): " use_previous

        if [[ $use_previous == "y" ]]; then
            return 0
        fi
    fi

    # Get EC2 IP
    read -p "Enter EC2 Public IP address: " EC2_IP
    if [ -z "$EC2_IP" ]; then
        log_error "EC2 IP cannot be empty"
        exit 1
    fi

    # Get PEM file path
    while true; do
        read -p "Enter path to your .pem key file: " PEM_FILE
        PEM_FILE="${PEM_FILE/#\~/$HOME}"  # Expand tilde

        if [ -f "$PEM_FILE" ]; then
            # Check permissions
            perms=$(stat -c %a "$PEM_FILE" 2>/dev/null || stat -f %A "$PEM_FILE" 2>/dev/null)
            if [ "$perms" != "400" ] && [ "$perms" != "600" ]; then
                log_warning "PEM file permissions are $perms, should be 400 or 600"
                log_info "Fixing permissions..."
                chmod 400 "$PEM_FILE"
            fi
            break
        else
            log_error "PEM file not found: $PEM_FILE"
            read -p "Try again? (y/n): " retry
            if [[ $retry != "y" ]]; then
                exit 1
            fi
        fi
    done

    # Get EC2 user
    read -p "Enter EC2 username (default: ubuntu): " EC2_USER
    EC2_USER=${EC2_USER:-ubuntu}

    # Get project path
    read -p "Enter remote deployment path (default: ~/ssl-automation): " PROJECT_PATH
    PROJECT_PATH=${PROJECT_PATH:-~/ssl-automation}

    # Save configuration
    read -p "Save this configuration for future use? (y/n): " save_conf
    if [[ $save_conf == "y" ]]; then
        save_config "$EC2_IP" "$PEM_FILE" "$EC2_USER" "$PROJECT_PATH"
    fi
}

# Test SSH connection
test_ssh_connection() {
    log_info "Testing SSH connection to EC2 instance..."

    if ssh -i "$PEM_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "echo 'Connection successful'" &> /dev/null; then
        log_success "SSH connection successful!"
        return 0
    else
        log_error "Failed to connect to EC2 instance"
        log_error "Please check:"
        log_error "  1. EC2 instance is running"
        log_error "  2. Security group allows SSH (port 22)"
        log_error "  3. PEM file path is correct"
        log_error "  4. EC2 IP address is correct"
        return 1
    fi
}

# Check Docker on EC2
check_remote_docker() {
    log_info "Checking Docker installation on EC2..."

    ssh -i "$PEM_FILE" "$EC2_USER@$EC2_IP" bash <<'EOF'
        if ! command -v docker &> /dev/null; then
            echo "DOCKER_NOT_INSTALLED"
        else
            echo "DOCKER_INSTALLED"
        fi
EOF
}

# Install Docker on EC2
install_remote_docker() {
    log_info "Installing Docker and docker-compose on EC2..."

    ssh -i "$PEM_FILE" "$EC2_USER@$EC2_IP" bash <<'EOF'
        set -e

        # Install Docker
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh

        # Install docker-compose
        echo "Installing docker-compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        echo "Docker installation complete!"
        docker --version
        docker-compose --version
EOF

    if [ $? -eq 0 ]; then
        log_success "Docker and docker-compose installed successfully!"
        log_warning "You may need to reconnect SSH for group changes to take effect"
    else
        log_error "Failed to install Docker"
        exit 1
    fi
}

# Copy project files to EC2
copy_files_to_ec2() {
    log_info "Copying project files to EC2..."

    # Exclude unnecessary files
    log_info "Source: $(pwd)"
    log_info "Destination: $EC2_USER@$EC2_IP:$PROJECT_PATH"

    # Create exclude list
    EXCLUDE_LIST=(
        "node_modules"
        ".git"
        "*.log"
        ".env"
        ".ec2-deploy-config"
        "data/certbot/conf/*"
        "data/certbot/www/*"
    )

    EXCLUDE_ARGS=""
    for item in "${EXCLUDE_LIST[@]}"; do
        EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$item"
    done

    # Use rsync for efficient file transfer
    if command -v rsync &> /dev/null; then
        log_info "Using rsync for file transfer..."
        rsync -avz --progress -e "ssh -i $PEM_FILE" $EXCLUDE_ARGS \
            ./ "$EC2_USER@$EC2_IP:$PROJECT_PATH/"
    else
        log_info "Using scp for file transfer..."
        scp -r -i "$PEM_FILE" ./ "$EC2_USER@$EC2_IP:$PROJECT_PATH/"
    fi

    if [ $? -eq 0 ]; then
        log_success "Files copied successfully!"
    else
        log_error "Failed to copy files"
        exit 1
    fi
}

# Run setup on EC2
run_remote_setup() {
    log_info "Running setup on EC2 instance..."

    read -p "Run the setup agent on EC2? (y/n): " run_setup
    if [[ $run_setup != "y" ]]; then
        log_info "Skipping remote setup"
        return
    fi

    ssh -i "$PEM_FILE" "$EC2_USER@$EC2_IP" bash <<EOF
        cd $PROJECT_PATH
        chmod +x setup-agent.sh
        ./setup-agent.sh --auto
EOF

    if [ $? -eq 0 ]; then
        log_success "Setup completed on EC2!"
    else
        log_warning "Setup encountered issues. You may need to run it manually."
    fi
}

# Open SSH session
open_ssh_session() {
    log_info "Opening SSH session to EC2..."
    log_info "Project location: $PROJECT_PATH"
    log_warning "Remember to configure your domain and run the setup if needed"
    echo ""

    ssh -i "$PEM_FILE" "$EC2_USER@$EC2_IP"
}

# Show status
show_status() {
    log_info "EC2 Deployment Status"
    echo ""

    if load_config; then
        echo "Configuration:"
        echo "  EC2 IP: $EC2_IP"
        echo "  PEM File: $PEM_FILE"
        echo "  EC2 User: $EC2_USER"
        echo "  Project Path: $PROJECT_PATH"
        echo ""

        log_info "Testing connection..."
        if test_ssh_connection; then
            log_info "Checking remote containers..."
            ssh -i "$PEM_FILE" "$EC2_USER@$EC2_IP" "cd $PROJECT_PATH && docker-compose ps" || log_warning "No containers running or docker-compose not found"
        fi
    else
        log_warning "No saved configuration found"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   AWS EC2 Deployment Agent             ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "1) Full deployment (all steps)"
    echo "2) Configure deployment settings"
    echo "3) Test SSH connection"
    echo "4) Install Docker on EC2"
    echo "5) Copy files to EC2"
    echo "6) Run setup on EC2"
    echo "7) Open SSH session to EC2"
    echo "8) Show deployment status"
    echo "9) Update files only (rsync)"
    echo "0) Exit"
    echo ""
}

# Update files only
update_files() {
    if ! load_config; then
        log_error "No configuration found. Run option 2 first."
        return
    fi

    if ! test_ssh_connection; then
        return
    fi

    copy_files_to_ec2

    read -p "Restart containers on EC2? (y/n): " restart
    if [[ $restart == "y" ]]; then
        ssh -i "$PEM_FILE" "$EC2_USER@$EC2_IP" "cd $PROJECT_PATH && docker-compose up --build -d"
        log_success "Containers restarted!"
    fi
}

# Full deployment
full_deployment() {
    gather_info

    if ! test_ssh_connection; then
        exit 1
    fi

    # Check Docker
    docker_status=$(check_remote_docker)
    if [[ $docker_status == "DOCKER_NOT_INSTALLED" ]]; then
        log_warning "Docker not installed on EC2"
        read -p "Install Docker now? (y/n): " install
        if [[ $install == "y" ]]; then
            install_remote_docker
        else
            log_error "Docker is required for deployment"
            exit 1
        fi
    else
        log_success "Docker is already installed on EC2"
    fi

    copy_files_to_ec2
    run_remote_setup

    log_success "Deployment complete!"
    log_info "Next steps:"
    log_info "  1. SSH into your EC2 instance"
    log_info "  2. Configure your domain (if not done automatically)"
    log_info "  3. Update security group to allow ports 80 and 443"
}

# Main execution
main() {
    clear

    if [ "$1" == "--auto" ]; then
        full_deployment
        exit 0
    fi

    while true; do
        show_menu
        read -p "Select an option: " choice

        case $choice in
            1)
                full_deployment
                ;;
            2)
                gather_info
                ;;
            3)
                if load_config; then
                    test_ssh_connection
                else
                    log_error "No configuration found. Run option 2 first."
                fi
                ;;
            4)
                if load_config; then
                    install_remote_docker
                else
                    log_error "No configuration found. Run option 2 first."
                fi
                ;;
            5)
                if load_config; then
                    copy_files_to_ec2
                else
                    log_error "No configuration found. Run option 2 first."
                fi
                ;;
            6)
                if load_config; then
                    run_remote_setup
                else
                    log_error "No configuration found. Run option 2 first."
                fi
                ;;
            7)
                if load_config; then
                    open_ssh_session
                else
                    log_error "No configuration found. Run option 2 first."
                fi
                ;;
            8)
                show_status
                ;;
            9)
                update_files
                ;;
            0)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
