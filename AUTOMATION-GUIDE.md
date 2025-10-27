# Automation Agent Guide

This repository now includes two intelligent automation agents that simplify the deployment process described in the README.md.

## 🤖 Available Agents

### 1. `setup-agent.sh` - Local/Server Setup Agent
Automates the SSL setup process on your local machine or server.

### 2. `deploy-to-ec2.sh` - AWS EC2 Deployment Agent
Automates deployment to AWS EC2 instances.

---

## 📋 Quick Start

### Local/Server Setup (Automated)

Run the full automated setup:
```bash
./setup-agent.sh --auto
```

Or use the interactive menu:
```bash
./setup-agent.sh
```

**What it does:**
- ✅ Checks/installs Docker and docker-compose
- ✅ Verifies your application structure
- ✅ Prompts for your domain/IP and configures nginx
- ✅ Downloads the Let's Encrypt initialization script
- ✅ Runs certificate generation (staging first, then production)
- ✅ Builds and starts all Docker containers

### AWS EC2 Deployment (Automated)

Run the full deployment:
```bash
./deploy-to-ec2.sh --auto
```

Or use the interactive menu:
```bash
./deploy-to-ec2.sh
```

**What it does:**
- ✅ Configures EC2 connection (IP, PEM file, user)
- ✅ Tests SSH connectivity
- ✅ Installs Docker/docker-compose on EC2
- ✅ Copies project files to EC2 (using rsync)
- ✅ Runs the setup agent on EC2
- ✅ Saves configuration for future deployments

---

## 🎯 Usage Examples

### Example 1: First-time Local Setup

```bash
# Make sure you're in the project directory
cd ssl-automation

# Run the setup agent
./setup-agent.sh

# Select option 1 for full automated setup
# When prompted, enter your domain (e.g., example.com or 192.168.1.100)
# The agent will handle everything automatically
```

### Example 2: AWS EC2 Deployment

```bash
# Run the deployment agent
./deploy-to-ec2.sh

# Select option 1 for full deployment
# Enter when prompted:
#   - EC2 Public IP: 54.123.45.67
#   - PEM file path: ~/aws-keys/mykey.pem
#   - EC2 username: ubuntu (or ec2-user)
#   - Remote path: ~/ssl-automation

# The agent will:
#   1. Test SSH connection
#   2. Install Docker if needed
#   3. Copy all files
#   4. Run setup automatically
```

### Example 3: Update Code on Running EC2

```bash
# After making changes to your code
./deploy-to-ec2.sh

# Select option 9: Update files only (rsync)
# This will sync only changed files and restart containers
```

### Example 4: Manual Step-by-Step

```bash
./setup-agent.sh

# Then select individual steps:
# 2 - Check Docker installation
# 3 - Verify app folder
# 4 - Configure domain
# 5 - Download init script
# 6 - Generate certificates
# 7 - Start containers
```

---

## 🔧 Interactive Menus

### Setup Agent Menu
```
1) Full automated setup (all steps)
2) Step 1: Check/Install Docker & docker-compose
3) Step 2: Verify application folder
4) Step 3: Configure domain in nginx
5) Step 4: Download init-letsencrypt.sh
6) Step 5: Run certificate generation
7) Step 6: Build and start containers
8) View container logs
9) Stop containers
0) Exit
```

### Deployment Agent Menu
```
1) Full deployment (all steps)
2) Configure deployment settings
3) Test SSH connection
4) Install Docker on EC2
5) Copy files to EC2
6) Run setup on EC2
7) Open SSH session to EC2
8) Show deployment status
9) Update files only (rsync)
0) Exit
```

---

## 📝 Configuration Files

### `.ec2-deploy-config`
The deployment agent saves your EC2 configuration for reuse:
```bash
EC2_IP=54.123.45.67
PEM_FILE=/home/user/aws-keys/mykey.pem
EC2_USER=ubuntu
PROJECT_PATH=~/ssl-automation
```

This file is automatically excluded from git and file transfers.

---

## 🛡️ Security Notes

1. **PEM File Permissions**: The agent automatically fixes PEM file permissions to 400
2. **Configuration Files**: `.ec2-deploy-config` is excluded from git and transfers
3. **Excluded Files**: The following are never copied to EC2:
   - `node_modules/`
   - `.git/`
   - `*.log`
   - `.env`
   - Existing certificates

---

## 🔍 Monitoring & Management

### View Logs
```bash
# Local/Server
./setup-agent.sh
# Select option 8

# Or directly:
docker-compose logs -f
```

### Check Deployment Status
```bash
./deploy-to-ec2.sh
# Select option 8
```

### SSH into EC2
```bash
./deploy-to-ec2.sh
# Select option 7
```

---

## ⚠️ Important Reminders

### Before Running Setup
1. ✅ Your Express app must include: `app.use(express.static(".well-known/acme-challenge/"))`
2. ✅ Your `package.json` must have a `start` script
3. ✅ Your app must run on port 3000

### Before EC2 Deployment
1. ✅ EC2 instance is running (Ubuntu recommended)
2. ✅ Security group allows SSH (port 22)
3. ✅ Security group allows HTTP (port 80) and HTTPS (port 443)
4. ✅ You have the `.pem` key file downloaded

### Certificate Generation
1. ✅ Always test with staging=1 first (avoid rate limits)
2. ✅ Only switch to production (staging=0) after successful staging test
3. ✅ Let's Encrypt has rate limits: 5 failures per hour, 50 certs per domain per week

---

## 🐛 Troubleshooting

### "Permission denied" when running scripts
```bash
chmod +x setup-agent.sh deploy-to-ec2.sh
```

### "Docker not found" on EC2
The agent will offer to install it automatically, or run:
```bash
./deploy-to-ec2.sh
# Select option 4: Install Docker on EC2
```

### "Cannot connect to EC2"
Check:
1. EC2 instance is running
2. Security group allows port 22
3. PEM file path is correct
4. EC2 IP is correct

### "Certificate generation failed"
1. Ensure domain/IP is correctly configured in `data/nginx/app.conf`
2. Ensure your Express app has the ACME challenge middleware
3. Check that you're using staging=1 for initial tests
4. Verify DNS is pointing to your server (if using a domain)

---

## 🚀 Manual Commands (If Needed)

If you prefer to run commands manually, here are the equivalents:

```bash
# Full local setup
docker-compose up --build -d

# Copy to EC2 manually
scp -r -i mykey.pem ./ ubuntu@54.123.45.67:~/ssl-automation/

# SSH to EC2
ssh -i mykey.pem ubuntu@54.123.45.67

# View logs
docker-compose logs -f [service-name]

# Stop containers
docker-compose down

# Rebuild specific service
docker-compose up --build -d nodeserver
```

---

## 📚 Related Files

- `README.md` - Original setup instructions
- `CLAUDE.md` - Project architecture documentation
- `docker-compose.yml` - Container orchestration
- `data/nginx/app.conf` - Nginx configuration
- `init-letsencrypt.sh` - Certificate generation (downloaded by agent)

---

## 🎉 Success Checklist

After running the agents, verify:
- [ ] Containers are running: `docker-compose ps`
- [ ] Nginx is accessible on port 80
- [ ] SSL certificate is valid (check browser)
- [ ] Your app responds on HTTPS
- [ ] Certificate auto-renewal is configured

---

## Need Help?

The agents provide colored output for easy reading:
- 🔵 **BLUE** = Informational messages
- 🟢 **GREEN** = Success messages
- 🟡 **YELLOW** = Warnings
- 🔴 **RED** = Errors

Each step is clearly labeled, and the agents will prompt you before taking any destructive actions.
