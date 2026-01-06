# ProjectileMod Backend API

Flask-based backend API for ProjectileMod configuration sharing and Steam authentication.

## System Requirements

Designed for **Debian 12/13**. Should work on Ubuntu as well.

### Hardware Requirements

- **Personal/Single User**: 512MB RAM + 1 CPU
- **Small Group**: 1-2GB RAM + 1-2 CPUs
- **Public Server**: 2GB+ RAM + 2+ CPUs

> The script automatically calculates optimal worker count based on available resources.
> Redis is included for rate limiting (~30-50MB RAM overhead).

## Getting Started

### Prerequisites

- A server running Debian 12/13
- A domain name
- SSH access to your server
- A Steam Web API Key (get one at https://steamcommunity.com/dev/apikey)

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
   
   The installer will ask for:
   - Your domain name
   - Email address for SSL certificate
   - Steam Web API Key
   
   The script will automatically configure nginx, SSL certificates, and all backend services.

6. **Done!**
   
   Your API will be reachable at https://your-server.com/

## Features

- Steam OpenID authentication
- Automatic username sync from Steam profiles
- Config upload/download/management
- Redis-backed rate limiting (works across all workers)
- User banning system
- Automatic worker calculation
- Systemd service integration
- Automatic nginx and SSL/TLS configuration

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

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Renew SSL certificate (auto-renewed, but manual check)
sudo certbot renew --dry-run

# Check Redis status
sudo systemctl status redis-server

# Restart Redis
sudo systemctl restart redis-server

# Monitor Redis (check rate limit counters)
redis-cli monitor
```

## File Locations

- **Installation directory**: `/var/www/projectile_api/`
- **Database**: `/var/www/projectile_api/src/database.db`
- **Service file**: `/etc/systemd/system/projectile-backend.service`
- **Nginx config**: `/etc/nginx/conf.d/default.conf`
- **SSL certificates**: `/etc/letsencrypt/live/your-domain/`

## Security

- Runs as dedicated `projectile-api` system user
- No shell access for service user
- Redis-backed rate limiting (shared across all workers)
- UFW firewall configured (HTTP/HTTPS + SSH, Redis bound to localhost only)
- TLS 1.2+ with modern cipher suites
- HSTS enabled (6 months)
- Environment-based secrets

