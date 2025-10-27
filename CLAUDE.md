# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an SSL automation repository for deploying and securing single-server Node.js applications/websites using Docker, Nginx, and Let's Encrypt certificates. The setup uses a three-container architecture (Nginx reverse proxy, Certbot for SSL, and a Node.js application server).

## Architecture

The system consists of three Docker containers orchestrated via docker-compose:

1. **nginx** (nginx:1.15-alpine): Reverse proxy handling HTTP/HTTPS traffic
   - Listens on ports 80 (HTTP) and 443 (HTTPS)
   - Routes traffic to the Node.js application container
   - Serves ACME challenge files for Let's Encrypt verification
   - Auto-reloads every 6 hours to pick up certificate renewals

2. **certbot** (certbot/certbot): Manages SSL certificate generation and renewal
   - Automatically renews certificates every 12 hours
   - Shares volumes with Nginx for certificate storage and ACME challenges

3. **nodeserver**: User's Node.js application
   - Built from `app/Dockerfile`
   - Runs on internal port 3000
   - Must include `express.static(".well-known/acme-challenge/")` middleware for ACME challenges

## Key Configuration Files

- `docker-compose.yml`: Container orchestration configuration
- `data/nginx/app.conf`: Nginx reverse proxy configuration with SSL settings
- `app/Dockerfile`: Node.js application container build instructions
- User must download `init-letsencrypt.sh` from wmnnd/nginx-certbot repository for initial certificate setup

## Domain Configuration

All instances of `<domain>` in `data/nginx/app.conf` must be replaced with the actual domain/IP:
- Line 3: `server_name` for HTTP
- Line 16: `server_name` for HTTPS
- Line 21: SSL certificate path
- Line 22: SSL certificate key path

## Development Commands

Build and start all services:
```bash
docker-compose up --build -d
```

Stop all services:
```bash
docker-compose down
```

View logs:
```bash
docker-compose logs -f
docker-compose logs -f nginx
docker-compose logs -f certbot
docker-compose logs -f nodeserver
```

Rebuild specific service:
```bash
docker-compose up --build -d nodeserver
```

## SSL Certificate Setup Process

1. Download the initialization script:
```bash
curl -L https://raw.githubusercontent.com/wmnnd/nginx-certbot/master/init-letsencrypt.sh > init-letsencrypt.sh
chmod +x init-letsencrypt.sh
```

2. Edit `init-letsencrypt.sh` to set staging=1 and verify domain matches
3. Run staging certificate generation: `sudo ./init-letsencrypt.sh`
4. After successful staging, set staging=0 in script and run again for production certificate

## Application Requirements

The Node.js application placed in the `app/` folder must:
- Start with `npm start` command
- Run on port 3000
- Include Express middleware: `app.use(express.static(".well-known/acme-challenge/"))`
- Have a valid `package.json` with dependencies

## Deployment to AWS EC2

The typical deployment workflow involves:
1. Create Ubuntu EC2 instance
2. Install Docker and docker-compose on the instance
3. Transfer project files using scp:
```bash
scp -r -i yourkeyname.pem ~/path/to/project ec2-user@<ec2-IPv4-publicIp>:~/
```
4. SSH into instance and follow the standard setup process

## Volume Mounts

- `./data/nginx`: Nginx configuration files
- `./data/certbot/conf`: Let's Encrypt certificates and configuration
- `./data/certbot/www`: ACME challenge files for domain verification
- `./app`: User's Node.js application code (mounted during build)
