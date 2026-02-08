#!/bin/bash

# =============================================
# osTicket Project Remover for Docker Workspace
# =============================================
# Usage: ./scripts/remove-osticket-project.sh <project-name>
# =============================================

set -e

# --- Base Paths and Imports ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"
source "${SCRIPT_DIR}/functions.sh" # For colors and validation

# Load environment variables from .env file
if [ -f "${PROJECT_ROOT}/.env" ]; then
  source "${PROJECT_ROOT}/.env"
fi

# 1. Validate Input
PROJECT_NAME="$1"
validate_input "$PROJECT_NAME"

# 2. Setup Paths
WWW_PATH="${PROJECT_ROOT}/www/${PROJECT_NAME}"
NGINX_CONF_PATH="${PROJECT_ROOT}/nginx/conf.d/${PROJECT_NAME}.conf"

# 3. Remove Project Directory
if [ -d "$WWW_PATH" ]; then
    echo -e "${YELLOW}Removing project directory: ${WWW_PATH}...${RESET}"
    rm -rf "$WWW_PATH"
    echo -e "${GREEN}✔ Project directory removed.${RESET}"
else
    echo -e "${CYAN}Project directory not found, skipping.${RESET}"
fi

# 4. Remove Nginx Config
if [ -f "$NGINX_CONF_PATH" ]; then
    echo -e "${YELLOW}Removing Nginx configuration: ${NGINX_CONF_PATH}...${RESET}"
    rm -f "$NGINX_CONF_PATH"
    echo -e "${GREEN}✔ Nginx configuration removed.${RESET}"
else
    echo -e "${CYAN}Nginx configuration not found, skipping.${RESET}"
fi

# 5. Drop Database
DB_NAME="osticket_$(echo "$PROJECT_NAME" | sed 's/[.-]/_/g')"
echo -e "${YELLOW}Dropping database: ${DB_NAME}...${RESET}"
if docker compose exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS ${DB_NAME};"; then
    echo -e "${GREEN}✔ Database dropped.${RESET}"
else
    echo -e "${RED}Failed to drop database. It might not exist or there was a DB connection issue.${RESET}"
fi

# 6. Restart Nginx
restart_nginx

# 7. Remind about /etc/hosts
echo -e "\n${YELLOW}============================================="
echo -e "${BOLD}Cleanup Complete!${RESET}"
echo -e "=============================================${RESET}"
echo -e "Project '${PROJECT_NAME}' has been removed."
echo -e "Please remember to manually remove the following line from your /etc/hosts file:"
echo -e "${GREEN}    127.0.0.1   ${PROJECT_NAME}${RESET}"
