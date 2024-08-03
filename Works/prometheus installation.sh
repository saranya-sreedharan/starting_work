#!/bin/bash

# Color variables
RED='\033[0;31m'   # Red colored text
NC='\033[0m'       # Normal text
YELLOW='\033[33m'  # Yellow Color
GREEN='\033[32m'   # Green Color

# Function for error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function for success message
success_message() {
    echo -e "${GREEN}$1${NC}"
}

# Function for warning message
warning_message() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root"
fi

# Create Prometheus user
warning_message "Creating Prometheus user..."
if ! sudo useradd --no-create-home --shell /bin/false prometheus; then
    error_exit "Failed to create Prometheus user"
fi
success_message "Prometheus user created successfully"

# Create Prometheus directories
warning_message "Creating Prometheus directories..."
if ! sudo mkdir -p /etc/prometheus /var/lib/prometheus; then
    error_exit "Failed to create Prometheus directories"
fi
success_message "Prometheus directories created successfully"

# Set ownership of Prometheus directories
warning_message "Setting ownership of Prometheus directories..."
if ! sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus; then
    error_exit "Failed to set ownership of Prometheus directories"
fi
success_message "Ownership of Prometheus directories set successfully"

# Download Prometheus release
warning_message "Downloading Prometheus release..."
if ! wget https://github.com/prometheus/prometheus/releases/download/v2.27.1/prometheus-2.27.1.linux-amd64.tar.gz; then
    error_exit "Failed to download Prometheus release"
fi
success_message "Prometheus release downloaded successfully"

# Extract Prometheus archive
warning_message "Extracting Prometheus archive..."
if ! tar -xvf prometheus-2.27.1.linux-amd64.tar.gz; then
    error_exit "Failed to extract Prometheus archive"
fi
success_message "Prometheus archive extracted successfully"
#go inside the prometheus folder
cd prometheus-2.27.1.linux-amd64 || exit

# Move Prometheus binaries to /usr/local/bin/
warning_message "Moving Prometheus binaries..."
if ! sudo mv prometheus promtool /usr/local/bin/; then
    error_exit "Failed to move Prometheus binaries"
fi
success_message "Prometheus binaries moved successfully"

# Move Prometheus web consoles and libraries to /etc/prometheus/
warning_message "Moving Prometheus web consoles and libraries..."
if ! sudo mv consoles/ console_libraries/ /etc/prometheus/; then
    error_exit "Failed to move Prometheus web consoles and libraries"
fi
success_message "Prometheus web consoles and libraries moved successfully"

# Move Prometheus configuration file to /etc/prometheus/
warning_message "Moving Prometheus configuration file..."
if ! sudo mv prometheus.yml /etc/prometheus/; then
    error_exit "Failed to move Prometheus configuration file"
fi
success_message "Prometheus configuration file moved successfully"

# Set ownership of Prometheus configuration files
warning_message "Setting ownership of Prometheus configuration files..."
if ! sudo chown -R prometheus:prometheus /etc/prometheus/consoles /etc/prometheus/console_libraries /etc/prometheus/prometheus.yml; then
    error_exit "Failed to set ownership of Prometheus configuration files"
fi
success_message "Ownership of Prometheus configuration files set successfully"

# Display Prometheus versions
warning_message "Displaying Prometheus version..."
if prometheus --version; then
    success_message "Prometheus version displayed successfully"
else
    error_exit "Failed to display Prometheus version"
fi

warning_message "Displaying promtool version..."
if promtool --version; then
    success_message "Promtool version displayed successfully"
else
    error_exit "Failed to display promtool version"
fi


# Display Prometheus configuration
warning_message "Displaying Prometheus configuration..."
if  cat /etc/prometheus/prometheus.yml; then
    success_message "Prometheus configuration displayed successfully"
else
    error_exit "Failed to display Prometheus configuration"
fi

# Wait for 10 seconds
sleep 10

# Create Prometheus systemd service file
warning_message "Creating Prometheus systemd service file..."
if ! sudo tee /etc/systemd/system/prometheus.service >/dev/null <<EOT
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOT
then
    error_exit "Failed to create Prometheus systemd service file"
fi
success_message "Prometheus systemd service file created successfully"

# Reload systemd daemon and start Prometheus service
warning_message "Reloading systemd daemon..."
if sudo systemctl daemon-reload && sudo systemctl start prometheus && sudo systemctl status prometheus; then
    success_message "Prometheus installed and started successfully!"
else
    error_exit "Failed to start Prometheus service"
fi

success_message "Prometheus is available in 'your_public_ip:9090'"