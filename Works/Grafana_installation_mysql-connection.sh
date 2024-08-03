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

# Update packages
echo -e "${YELLOW}...Updating packages${NC}"
if ! sudo apt-get update -y; then
    error_exit "Failed to update packages."
fi

# Install required packages
echo -e "${YELLOW}...Installing required packages${NC}"
if ! sudo apt-get install -y software-properties-common; then
    error_exit "Failed to install required packages."
fi

# Add Grafana repository
echo -e "${YELLOW}...Adding Grafana repository${NC}"
if ! wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -; then
    error_exit "Failed to add Grafana repository key."
fi

if ! sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"; then
    error_exit "Failed to add Grafana repository."
fi

# Update package lists
echo -e "${YELLOW}...Updating package lists${NC}"
if ! sudo apt-get update; then
    error_exit "Failed to update package lists after adding Grafana repository."
fi

# Install Grafana
echo -e "${YELLOW}...Installing Grafana${NC}"
if ! sudo apt-get install -y grafana; then
    error_exit "Failed to install Grafana."
fi

# Start and enable Grafana service
echo -e "${YELLOW}...Starting and enabling Grafana service${NC}"
if ! sudo systemctl start grafana-server && sudo systemctl enable grafana-server; then
    error_exit "Failed to start and enable Grafana service."
fi

# Display access information
echo -e "${GREEN}Grafana will be accessible via a web browser at:${NC} http://your_server_ip:3000"
echo -e "${GREEN}Login with default credentials:${NC}"
echo -e "${GREEN}Username:${NC} admin"
echo -e "${GREEN}Password:${NC} admin"
echo -e "${GREEN}Then set a new password.${NC}"

# Display MySQL connection details
echo -e "${YELLOW}MySQL connection details:${NC}"
echo -e "${GREEN}Username:${NC} usr_local_invoiceflow"
echo -e "${GREEN}Password:${NC} b5^^9o-gS6*n"
echo -e "${GREEN}Hostname:${NC} mnserviceproviders.com:3307"
echo -e "${GREEN}Database:${NC} local_db_developer_mm_invoiceflow"
