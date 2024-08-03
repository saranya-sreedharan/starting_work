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

# Update package list
sudo apt update || error_exit "Failed to update package list"
success_message "Package list updated successfully."

# Install Docker
sudo apt install docker.io -y || error_exit "Failed to install Docker"
success_message "Docker installed successfully."

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || error_exit "Failed to install Docker Compose"
sudo chmod +x /usr/local/bin/docker-compose || error_exit "Failed to set execute permission for Docker Compose"
success_message "Docker Compose installed successfully."

# Write docker-compose.yml file
cat << EOF | sudo tee docker-compose.yml > /dev/null || error_exit "Failed to write docker-compose.yml"
version: '3'

services:
  mariadb:
    image: mariadb:latest
    container_name: mariadb_container
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: maindb
      MYSQL_USER: dockerroot
      MYSQL_PASSWORD: docker&root@123^
    ports:
      - "3306:3306"
    volumes:
      - mariadb_data:/var/lib/mysql

volumes:
  mariadb_data:
EOF
success_message "docker-compose.yml created successfully."

# Create Docker containers
sudo docker-compose up -d || error_exit "Failed to create Docker containers"
success_message "Docker containers created successfully."

sudo apt install jq -y

# Obtain IP address of the Docker container
container_ip=$(sudo docker inspect $(sudo docker ps -q) | jq -r '.[0].NetworkSettings.Networks."ubuntu_default".IPAddress')

if [ -z "$container_ip" ]; then
    error_exit "Failed to obtain IP address of the Docker container"
else
    echo "IP address of the Docker container: $container_ip"
fi

# Configure mysqld_exporter
cat << EOF | sudo tee /home/ubuntu/mysqld_exporter.yml > /dev/null || error_exit "Failed to write mysqld_exporter.yml"
[client]
  user: 'dockerroot'
  pass: 'docker&root@123^'
  endpoint: '$container_ip:3306'
EOF
success_message "mysqld_exporter configured successfully."

# Run mysqld_exporter Docker container
sudo docker run -d -p 9104:9104 -v /home/ubuntu/mysqld_exporter.yml:/etc/mysqld_exporter.yml prom/mysqld-exporter --config.my-cnf=/etc/mysqld_exporter.yml || error_exit "Failed to run mysqld_exporter Docker container"
success_message "mysqld_exporter Docker container started successfully."
echo "The Data will  be available in public_ip:9104/metrics"
echo -e "${YELLOW}To revert the Prometheus configuration changes, perform the following steps:${NC}"
echo -e "${YELLOW}1. Remove or comment out the 'mariadb' job configuration block in the Prometheus configuration file:${NC}"
echo -e "${YELLOW}   sudo nano /etc/prometheus/prometheus.yml${NC}"
echo -e "${YELLOW}   #scrape_configs:${NC}"
echo -e "${YELLOW}   #  - job_name: 'mariadb'${NC}"
echo -e "${YELLOW}   #    static_configs:${NC}"
echo -e "${YELLOW}   #      - targets: ['54.162.109.196:9104']${NC}"
echo -e "${YELLOW}2. Save the file and exit the text editor.${NC}"
echo -e "${YELLOW}3. Restart Prometheus:${NC}"
echo -e "${YELLOW}   sudo systemctl restart prometheus${NC}"
success_message "Setup completed successfully!"
