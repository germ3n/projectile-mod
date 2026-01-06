# ProjectileMod Backend API

Flask-based backend API for ProjectileMod configuration sharing and Steam authentication.

## System Requirements

Designed for **Debian 12/13**. Should work on Ubuntu as well.

### Hardware Requirements

- **Personal/Single User**: 512MB RAM + 1 CPU
- **Small Group**: 1-2GB RAM + 1-2 CPUs
- **Public Server**: 2GB+ RAM + 2+ CPUs

> The script automatically calculates optimal worker count based on available resources.

## Getting Started

### Prerequisites

- A server running Debian 12/13
- A domain name
- SSH access to your server

### Installation

1. **Set up DNS**
   
   Create an A record pointing to your server's IP, or configure Cloudflare/similar service

2. **Log into your server**
   ```bash
   ssh user@your-server.com
   ```

3. **Install Git**
   ```bash
   sudo apt update && sudo apt install git -y
   ```

4. **Clone and run installer**
   ```bash
   git clone https://github.com/germ3n/projectile-mod && \
   cd projectile-mod/python-backend && \
   chmod +x *.sh && \
   sudo ./install.sh
   ```

5. **Follow prompts**
   
   Monitor the installation progress and enter input when asked

6. **Done!**
   
   Your API will be reachable at https://your-server.com/

## Features

- Steam OpenID authentication
- Config upload/download/management
- Rate limiting
- User banning system
- Automatic worker calculation
- Systemd service integration

## Service Management

```bash
# Start the service
sudo systemctl start projectile-backend

# Stop the service
sudo systemctl stop projectile-backend

# Restart the service
sudo systemctl restart projectile-backend

# Check status
sudo systemctl status projectile-backend

# View logs
sudo journalctl -u projectile-backend -f
```

## File Locations

- **Installation directory**: `/var/www/projectile_api/`
- **Database**: `/var/www/projectile_api/src/database.db`
- **Service file**: `/etc/systemd/system/projectile-backend.service`

## Security

- Runs as dedicated `projectile-api` system user
- No shell access for service user
- Rate limiting enabled
- UFW firewall configured
- Environment-based secrets

