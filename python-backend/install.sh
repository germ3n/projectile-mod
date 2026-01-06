#!/bin/bash

set -e

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/var/www/projectile_api"
SERVICE_NAME="projectile-backend"
SERVICE_USER="projectile-api"
PYTHON_BIN="/usr/bin/python3"
VENV_DIR="$INSTALL_DIR/venv"
APP_DIR="$INSTALL_DIR/src"
WORKING_DIR="$APP_DIR"

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "Creating dedicated system user..."
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd -r -s /bin/false -d "$INSTALL_DIR" -c "ProjectileMod API Service" "$SERVICE_USER"
    echo "Created user: $SERVICE_USER"
else
    echo "User $SERVICE_USER already exists"
fi

echo "Installing system dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv ufw nginx openssl redis-server

echo "Enabling ufw..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 'Nginx Full'
ufw allow ssh
ufw --force enable

echo "Starting Redis..."
systemctl enable redis-server
systemctl start redis-server

echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$APP_DIR"

echo "Copying application files..."
cp -r "$SOURCE_DIR/src/"* "$APP_DIR/"

echo "Setting ownership and permissions..."
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

echo "Creating virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    sudo -u "$SERVICE_USER" python3 -m venv "$VENV_DIR"
fi

echo "Installing Python dependencies..."
sudo -u "$SERVICE_USER" "$VENV_DIR/bin/pip" install --upgrade pip
sudo -u "$SERVICE_USER" "$VENV_DIR/bin/pip" install gunicorn flask requests werkzeug flask-limiter redis

echo ""
echo "Domain name is required for nginx and SSL setup."
echo -n "Enter your domain name (e.g., projectilemod.directory): "
read DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: Domain name is required"
    exit 1
fi

echo ""
echo -n "Enter your email for SSL certificate (Let's Encrypt notifications): "
read SSL_EMAIL

if [ -z "$SSL_EMAIL" ]; then
    echo "Error: Email is required for SSL certificate"
    exit 1
fi

echo "Generating secret key..."
SECRET_KEY=$(openssl rand -hex 32)

echo ""
echo "Steam API Key is required for automatic username sync."
echo "Get your key from: https://steamcommunity.com/dev/apikey"
echo -n "Enter your Steam Web API Key: "
read STEAM_API_KEY

if [ -z "$STEAM_API_KEY" ]; then
    echo "Warning: No Steam API key provided. Username sync will be disabled."
    STEAM_API_KEY=""
fi

calculate_workers() {
    local cpu_cores=$(nproc)
    local total_ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    
    local worker_formula=$((2 * cpu_cores + 1))
    
    local ram_based_workers=$((total_ram_mb / 200))
    
    local workers=$worker_formula
    if [ $ram_based_workers -lt $workers ]; then
        workers=$ram_based_workers
    fi
    
    if [ $workers -lt 1 ]; then
        workers=1
    elif [ $workers -gt 8 ]; then
        workers=8
    fi
    
    echo $workers
}

WORKERS=$(calculate_workers)
echo "Detected CPU cores: $(nproc), RAM: $(free -m | awk '/^Mem:/{print $2}')MB"
echo "Calculated optimal workers: $WORKERS"

echo "Creating systemd service..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=ProjectileMod Backend API
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$WORKING_DIR
Environment="PATH=$VENV_DIR/bin"
Environment="SECRET_KEY=$SECRET_KEY"
Environment="STEAM_API_KEY=$STEAM_API_KEY"
ExecStart=$VENV_DIR/bin/gunicorn --bind 0.0.0.0:8000 --workers $WORKERS --timeout 120 --worker-class sync app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling service to start on boot..."
systemctl enable "$SERVICE_NAME"

echo "Starting service..."
systemctl start "$SERVICE_NAME"

echo "Installing certbot..."
apt-get install -y certbot python3-certbot-nginx

echo "Obtaining SSL certificate..."
certbot certonly --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "$SSL_EMAIL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to obtain SSL certificate"
    exit 1
fi

echo "Configuring nginx with SSL..."
cat > "/etc/nginx/conf.d/default.conf" << NGINX_EOF
server {
    if (\$host = $DOMAIN_NAME) {
        return 301 https://\$host\$request_uri;
    }

  listen 80;
  listen [::]:80;
  server_name $DOMAIN_NAME;
    return 404;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name $DOMAIN_NAME;
  
  ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:50m;
  ssl_session_tickets off;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
  ssl_prefer_server_ciphers off;

  add_header Strict-Transport-Security "max-age=15768000" always;

  location / {
    proxy_pass http://127.0.0.1:8000;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_redirect off;

    proxy_connect_timeout 90;
    proxy_send_timeout 90;
    proxy_read_timeout 90;

    client_max_body_size 10M;
  }

  access_log /var/log/nginx/projectile_api_access.log;
  error_log /var/log/nginx/projectile_api_error.log;
}
NGINX_EOF

echo "Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "Reloading nginx..."
    systemctl reload nginx
else
    echo "Error: Nginx configuration test failed"
    exit 1
fi

echo ""
echo "Installation complete!"
echo "Installed to: $INSTALL_DIR"
echo "Running as user: $SERVICE_USER"
echo "Domain: https://$DOMAIN_NAME"
echo ""
echo "Service status:"
systemctl status "$SERVICE_NAME" --no-pager
echo ""
echo "Useful commands:"
echo "  Start:   sudo systemctl start $SERVICE_NAME"
echo "  Stop:    sudo systemctl stop $SERVICE_NAME"
echo "  Restart: sudo systemctl restart $SERVICE_NAME"
echo "  Status:  sudo systemctl status $SERVICE_NAME"
echo "  Logs:    sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "Configuration:"
echo "  Application directory: $INSTALL_DIR"
echo "  Database location: $APP_DIR/database.db"
echo "  Nginx config: /etc/nginx/conf.d/default.conf"
echo "  Redis: Running on localhost:6379"
if [ -n "$STEAM_API_KEY" ]; then
    echo "  Steam API: Configured (username sync enabled)"
else
    echo "  Steam API: Not configured (username sync disabled)"
fi
echo ""
echo "Your API is now available at: https://$DOMAIN_NAME"

