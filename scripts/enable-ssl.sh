#!/bin/bash

# =============================================
# SSL Enabler for osTicket Projects
# =============================================
# Usage: ./scripts/enable-ssl.sh <project-name>
#
# This script configures an existing HTTP project to use HTTPS.
# =============================================

set -e

# --- Colors and Styles ---
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Pre-flight Checks ---
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script with sudo.${RESET}"
  echo -e "${YELLOW}Usage:${RESET} sudo ./scripts/enable-ssl.sh <project-name>"
  exit 1
fi

if [ -z "$1" ]; then
  echo -e "${RED}${BOLD}Error:${RESET} Project name is required."
  echo -e "${YELLOW}Usage:${RESET} sudo $0 <project-name>"
  exit 1
fi

PROJECT_NAME="$1"

# --- Relative Paths ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"
CERTS_DIR="${PROJECT_ROOT}/nginx/certs"
NGINX_CONF_PATH="${PROJECT_ROOT}/nginx/conf.d/${PROJECT_NAME}.conf"

echo -e "${CYAN}============================================="
echo -e "${BOLD}Enabling SSL for: ${PROJECT_NAME}${RESET}"
echo -e "=============================================${RESET}"

# 1. Generate Certificates
echo -e "${YELLOW}Generating SSL certificate and key...${RESET}"
mkdir -p "$CERTS_DIR"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "${CERTS_DIR}/${PROJECT_NAME}.key" \
  -out "${CERTS_DIR}/${PROJECT_NAME}.crt" \
  -subj "/CN=${PROJECT_NAME}"
echo -e "${GREEN}✔ Certificates generated.${RESET}"

# 2. Fix Permissions
echo -e "${YELLOW}Fixing certificate permissions...${RESET}"
chmod 644 "${CERTS_DIR}/${PROJECT_NAME}.key" "${CERTS_DIR}/${PROJECT_NAME}.crt"
echo -e "${GREEN}✔ Permissions fixed.${RESET}"

# 3. Create Nginx Configuration from Template
echo -e "${YELLOW}Creating Nginx configuration for HTTPS from template...${RESET}"
cp "${PROJECT_ROOT}/nginx/conf.d/osticket.conf.ssl.example" "$NGINX_CONF_PATH"
sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "$NGINX_CONF_PATH"
echo -e "${GREEN}✔ Nginx configuration created.${RESET}"

# 4. Restart Nginx
echo -e "${YELLOW}Restarting Nginx to apply all changes...${RESET}"
docker compose -f "${PROJECT_ROOT}/docker-compose.yml" up -d --force-recreate nginx
echo -e "${GREEN}✔ Nginx restarted.${RESET}"

echo -e "\n${CYAN}============================================="
echo -e "${BOLD}SSL for ${PROJECT_NAME} is enabled!${RESET}"
echo -e "=============================================${RESET}"
echo -e "${YELLOW}ACTION REQUIRED:${RESET} For the browser to trust the certificate, you must import it into your OS or browser."
echo -e "The certificate file is located at:"
echo -e "   ${GREEN}${CERTS_DIR}/${PROJECT_NAME}.crt${RESET}"
echo -e "\nAfter importing, access your site at: https://${PROJECT_NAME}:8443"
