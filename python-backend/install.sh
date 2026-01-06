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
    useradd -r -s /bin/bash -d "$INSTALL_DIR" -c "ProjectileMod API Service" "$SERVICE_USER"
    echo "Created user: $SERVICE_USER"
else
    echo "User $SERVICE_USER already exists"
fi

echo "Installing system dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv ufw nginx

echo "Enabling ufw..."
ufw allow 'Nginx Full'
ufw allow ssh
ufw enable
ufw reload

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
sudo -u "$SERVICE_USER" "$VENV_DIR/bin/pip" install gunicorn flask requests werkzeug

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
ExecStart=$VENV_DIR/bin/gunicorn --bind 0.0.0.0:8000 --workers 4 --timeout 120 --worker-class sync app:app
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

echo ""
echo "Installation complete!"
echo "Installed to: $INSTALL_DIR"
echo "Running as user: $SERVICE_USER"
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
echo "Application directory: $INSTALL_DIR"
echo "Database location: $APP_DIR/database.db"

