#!/bin/bash

# SSL Automation Setup Agent
# Automates the steps from README.md for easy deployment

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

# Check if running with sudo when needed
check_sudo() {
    if [ "$EUID" -ne 0 ] && [ "$1" == "required" ]; then
        log_error "This script must be run with sudo"
        exit 1
    fi
}

# Step 1: Check Docker and docker-compose installation
check_docker_installation() {
    log_info "Step 1: Checking Docker and docker-compose installation..."

    if ! command -v docker &> /dev/null; then
        log_warning "Docker is not installed"
        read -p "Would you like to install Docker? (y/n): " install_docker
        if [[ $install_docker == "y" ]]; then
            log_info "Installing Docker..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
            log_success "Docker installed successfully"
        else
            log_error "Docker is required. Please install it manually."
            exit 1
        fi
    else
        log_success "Docker is already installed ($(docker --version))"
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_warning "docker-compose is not installed"
        read -p "Would you like to install docker-compose? (y/n): " install_compose
        if [[ $install_compose == "y" ]]; then
            log_info "Installing docker-compose..."
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            log_success "docker-compose installed successfully"
        else
            log_error "docker-compose is required. Please install it manually."
            exit 1
        fi
    else
        log_success "docker-compose is already installed"
    fi
}

# Step 2: Verify application folder
check_app_folder() {
    log_info "Step 2: Checking application folder..."

    if [ ! -d "app" ]; then
        log_error "app/ folder not found!"
        exit 1
    fi

    if [ ! -f "app/package.json" ]; then
        log_warning "app/package.json not found"
        exit 1
    fi

    if [ ! -f "app/Dockerfile" ]; then
        log_error "app/Dockerfile not found"
        exit 1
    fi

    # Check if npm start is configured
    if ! grep -q '"start"' app/package.json; then
        log_warning "No 'start' script found in package.json"
        log_warning "Make sure your package.json has a start script"
    fi

    log_success "Application folder structure looks good"
    log_warning "Remember: Your Express server must include: app.use(express.static('.well-known/acme-challenge/'))"
}

# Step 3: Configure domain in nginx
configure_domain() {
    log_info "Step 3: Configuring domain in nginx config..."

    if [ ! -f "data/nginx/app.conf" ]; then
        log_error "data/nginx/app.conf not found!"
        exit 1
    fi

    # Check if <domain> placeholder exists
    if grep -q "<domain>" data/nginx/app.conf; then
        read -p "Enter your domain or IP address: " domain

        # Validate input
        if [ -z "$domain" ]; then
            log_error "Domain cannot be empty"
            exit 1
        fi

        log_info "Replacing <domain> with $domain in nginx config..."

        # Backup original config
        cp data/nginx/app.conf data/nginx/app.conf.backup

        # Replace all instances of <domain>
        sed -i "s/<domain>/$domain/g" data/nginx/app.conf

        log_success "Domain configured successfully: $domain"
        log_info "Backup saved to: data/nginx/app.conf.backup"
    else
        log_success "Domain already configured in nginx config"
        grep "server_name" data/nginx/app.conf | head -1
    fi
}

# Step 4: Download Let's Encrypt initialization script
download_init_script() {
    log_info "Step 4: Downloading Let's Encrypt initialization script..."

    if [ -f "init-letsencrypt.sh" ]; then
        log_warning "init-letsencrypt.sh already exists"
        read -p "Do you want to re-download it? (y/n): " redownload
        if [[ $redownload != "y" ]]; then
            log_info "Skipping download"
            return
        fi
    fi

    log_info "Downloading from wmnnd/nginx-certbot repository..."
    curl -L https://raw.githubusercontent.com/wmnnd/nginx-certbot/master/init-letsencrypt.sh > init-letsencrypt.sh
    chmod +x init-letsencrypt.sh

    log_success "init-letsencrypt.sh downloaded and made executable"
    log_warning "IMPORTANT: Review init-letsencrypt.sh to ensure:"
    log_warning "  1. The domain matches your configuration"
    log_warning "  2. staging=1 for initial test (avoid rate limits)"
}

# Step 5: Run certificate generation
run_certificate_generation() {
    log_info "Step 5: Running certificate generation..."

    if [ ! -f "init-letsencrypt.sh" ]; then
        log_error "init-letsencrypt.sh not found! Run step 4 first."
        exit 1
    fi

    # Check staging status
    staging_value=$(grep "staging=" init-letsencrypt.sh | head -1 | cut -d'=' -f2)

    if [[ $staging_value == "1" ]]; then
        log_info "Running in STAGING mode (testing)..."
        log_warning "This will create a test certificate to avoid rate limits"
    else
        log_warning "Running in PRODUCTION mode!"
        log_warning "Make sure staging test was successful first"
    fi

    read -p "Continue with certificate generation? (y/n): " continue_cert
    if [[ $continue_cert != "y" ]]; then
        log_info "Skipping certificate generation"
        return
    fi

    log_info "Running init-letsencrypt.sh..."
    sudo ./init-letsencrypt.sh

    if [ $? -eq 0 ]; then
        log_success "Certificate generation completed!"

        if [[ $staging_value == "1" ]]; then
            log_warning "You ran in staging mode. Next steps:"
            log_warning "  1. Change staging=1 to staging=0 in init-letsencrypt.sh"
            log_warning "  2. Run this agent again or manually: sudo ./init-letsencrypt.sh"

            read -p "Would you like to switch to production mode now? (y/n): " switch_prod
            if [[ $switch_prod == "y" ]]; then
                sed -i 's/staging=1/staging=0/' init-letsencrypt.sh
                log_info "Switched to production mode, running again..."
                sudo ./init-letsencrypt.sh
                log_success "Production certificate generated!"
            fi
        fi
    else
        log_error "Certificate generation failed!"
        exit 1
    fi
}

# Step 6: Build and start containers
start_containers() {
    log_info "Step 6: Building and starting Docker containers..."

    read -p "Start containers with docker-compose? (y/n): " start_docker
    if [[ $start_docker != "y" ]]; then
        log_info "Skipping container startup"
        return
    fi

    log_info "Running: docker-compose up --build -d"
    docker-compose up --build -d

    if [ $? -eq 0 ]; then
        log_success "Containers are up and running!"
        log_info "Checking container status..."
        docker-compose ps

        log_success "Setup complete! Your application should be accessible now."
        log_info "Useful commands:"
        log_info "  - View logs: docker-compose logs -f"
        log_info "  - Stop containers: docker-compose down"
        log_info "  - Restart: docker-compose restart"
    else
        log_error "Failed to start containers"
        exit 1
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   SSL Automation Setup Agent          ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "1) Full automated setup (all steps)"
    echo "2) Step 1: Check/Install Docker & docker-compose"
    echo "3) Step 2: Verify application folder"
    echo "4) Step 3: Configure domain in nginx"
    echo "5) Step 4: Download init-letsencrypt.sh"
    echo "6) Step 5: Run certificate generation"
    echo "7) Step 6: Build and start containers"
    echo "8) View container logs"
    echo "9) Stop containers"
    echo "0) Exit"
    echo ""
}

# View logs
view_logs() {
    log_info "Viewing container logs (Ctrl+C to exit)..."
    docker-compose logs -f
}

# Stop containers
stop_containers() {
    log_info "Stopping containers..."
    docker-compose down
    log_success "Containers stopped"
}

# Main execution
main() {
    clear

    if [ "$1" == "--auto" ]; then
        log_info "Running full automated setup..."
        check_docker_installation
        check_app_folder
        configure_domain
        download_init_script
        run_certificate_generation
        start_containers
        exit 0
    fi

    while true; do
        show_menu
        read -p "Select an option: " choice

        case $choice in
            1)
                check_docker_installation
                check_app_folder
                configure_domain
                download_init_script
                run_certificate_generation
                start_containers
                ;;
            2)
                check_docker_installation
                ;;
            3)
                check_app_folder
                ;;
            4)
                configure_domain
                ;;
            5)
                download_init_script
                ;;
            6)
                run_certificate_generation
                ;;
            7)
                start_containers
                ;;
            8)
                view_logs
                ;;
            9)
                stop_containers
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
