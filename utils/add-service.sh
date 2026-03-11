#!/bin/bash
set -e

SERVICE_NAME="munic-exporter"
SERVICE_USER="municservice"
INSTALL_DIR="/opt/$SERVICE_NAME"
EXECUTABLE="$INSTALL_DIR/$SERVICE_NAME"

# 1. Update package lists and install dependencies
echo "Updating package lists..."
# sudo apt update

# 2. Create a service user
if ! id -u "$SERVICE_USER" >/dev/null 2>&1; then
    echo "Creating service user $SERVICE_USER..."
    sudo useradd -r -s /bin/false "$SERVICE_USER"
fi

# 3. Create installation directory
echo "Creating installation directory $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR"

# 4. Download or copy your service binary
# Example: download from URL (customize URL)
sudo cp /home/tangg/munic_exporter/munic_exporter "$EXECUTABLE"
sudo chmod +x "$EXECUTABLE"
sudo chown "$SERVICE_USER":"$SERVICE_USER" "$EXECUTABLE"

# 5. Create a systemd service file
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
echo "Creating systemd service file at $SERVICE_FILE..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=$SERVICE_NAME service
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
ExecStart=$EXECUTABLE
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# 6. Reload systemd, enable and start the service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling $SERVICE_NAME to start on boot..."
sudo systemctl enable "$SERVICE_NAME"

echo "Starting $SERVICE_NAME..."
sudo systemctl start "$SERVICE_NAME"

echo "$SERVICE_NAME installation and setup completed!"

