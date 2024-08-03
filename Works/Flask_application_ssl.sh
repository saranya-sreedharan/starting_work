#!/bin/bash

# Define colors
RED='\033[0;31m'   # Red colored text
NC='\033[0m'       # Normal text
YELLOW='\033[33m'  # Yellow Color
GREEN='\033[32m'   # Green Color

# Update packages
echo -e "${YELLOW}Updating packages...${NC}"
if ! sudo apt update; then
    echo -e "${RED}Failed to update packages.${NC}"
    exit 1
fi

# Install Docker if not already installed
echo -e "${YELLOW}Installing Docker...${NC}"
if ! sudo apt install docker.io -y; then
    echo -e "${RED}Failed to install Docker.${NC}"
    exit 1
fi

# Change directory to NEW_CODES
read -p "Enter the project folder name: " project_folder
cd "$project_folder" || { echo -e "${RED}Failed to change directory.${NC}"; exit 1; }

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
if ! sudo docker build -t bill_import_image:1.0 .; then
    echo -e "${RED}Failed to build Docker image.${NC}"
    exit 1
fi

# Check if Docker image is created
echo -e "${YELLOW}Checking Docker image...${NC}"
if ! sudo docker images | grep -q "bill_import_image"; then
    echo -e "${RED}Docker image 'bill_import_image:1.0' not found.${NC}"
    exit 1
fi

# Run Docker container
echo -e "${YELLOW}Running Docker container...${NC}"
if ! sudo docker run -d -p 5000:5000 bill_import_image:1.0; then
    echo -e "${RED}Failed to run Docker container.${NC}"
    exit 1
fi

# Check open ports
echo -e "${YELLOW}Checking open ports...${NC}"
if ! sudo apt install net-tools -y; then
    echo -e "${RED}Failed to install net-tools.${NC}"
    exit 1
fi

if ! sudo ss -tuln | grep -q ":5000"; then
    echo -e "${RED}Port 5000 is not open.${NC}"
    exit 1
fi

# Check connection
echo -e "${YELLOW}Checking connection...${NC}"
ip_service="ifconfig.me/ip"  # or "ipecho.net/plain"
public_ip=$(curl -sS "$ip_service")

# Check if the public IP retrieval was successful
if [ -z "$public_ip" ]; then
    echo -e "${RED}Failed to retrieve public IP.${NC}"
    exit 1
fi

# Double quote the variable to handle special characters
if ! nc -zv "$public_ip" 5000; then
    echo -e "${RED}Connection to port 5000 failed.${NC}"
    exit 1
fi

# Additional curl commands
echo -e "${YELLOW}Additional curl commands...${NC}"
if ! curl -sS "http://$public_ip:5000/process-emails"; then
    echo -e "${RED}Failed to curl http://$public_ip:5000/process-emails.${NC}"
fi

if ! curl -sS "http://$public_ip:5000/check-both-connections"; then
    echo -e "${RED}Failed to curl http://$public_ip:5000/check-both-connections.${NC}"
fi

if ! curl -sS "http://$public_ip:5000/check-db-connection"; then
    echo -e "${RED}Failed to curl http://$public_ip:5000/check-db-connection.${NC}"
fi

if ! curl -sS "http://$public_ip:5000/check-url-connection"; then
    echo -e "${RED}Failed to curl http://$public_ip:5000/check-url-connection.${NC}"
fi

# Set up Nginx with SSL
echo -e "${YELLOW}Setting up Nginx with SSL...${NC}"

# Define function to display success message
success() {
  echo -e "${GREEN}$1${NC}"
}

# Function to display error message and exit script
error() {
  echo -e "${RED}$1${NC}"
  exit 1
}

# Install Nginx
sudo apt install -y nginx || error "Failed to install Nginx"

# Install Certbot and obtain SSL certificate
sudo apt-get install -y certbot python3-certbot-nginx || error "Failed to install Certbot"
sudo certbot certonly --nginx || error "Failed to obtain SSL certificate"

# Create Nginx configuration file
sudo tee /etc/nginx/sites-available/s123.mnsp.co.in > /dev/null <<EOF
server {
    listen 80;
    server_name s123.mnsp.co.in www.s123.mnsp.co.in;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name s123.mnsp.co.in www.s123.mnsp.co.in;

    ssl_certificate /etc/letsencrypt/live/s123.mnsp.co.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/s123.mnsp.co.in/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Create a symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/s123.mnsp.co.in /etc/nginx/sites-enabled/ || error "Failed to create symbolic link"

# Test Nginx configuration
sudo nginx -t || error "Nginx configuration test failed"

# Reload and restart Nginx
sudo systemctl reload nginx && sudo systemctl restart nginx || error "Failed to reload or restart Nginx"

# Success message
success "Nginx configuration successfully updated with SSL certificate and proxy settings"

echo -e "${GREEN}Script execution completed.${NC}"
