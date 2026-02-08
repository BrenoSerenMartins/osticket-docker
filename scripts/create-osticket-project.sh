#!/bin/bash

# =============================================
# osTicket Project Creator for Docker Workspace
# =============================================
# This script orchestrates the creation of a new osTicket project
# by calling functions from the functions.sh library.
#
# Usage: ./scripts/create-osticket-project.sh <project-name>
# Example: ./scripts/create-osticket-project.sh my-osticket.local
# =============================================

set -e

# --- Base Paths and Imports ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"
source "${SCRIPT_DIR}/functions.sh"

# Load environment variables from .env file
if [ -f "${PROJECT_ROOT}/.env" ]; then
  source "${PROJECT_ROOT}/.env"
fi

# --- Main Execution ---

# 1. Print Header
print_header

# 2. Validate Input
PROJECT_NAME="$1"
validate_input "$PROJECT_NAME"

# 3. Setup Paths
WWW_PATH="${PROJECT_ROOT}/www/${PROJECT_NAME}"
NGINX_CONF_PATH="${PROJECT_ROOT}/nginx/conf.d/${PROJECT_NAME}.conf"

# 4. Pre-flight Checks
check_project_exists "$WWW_PATH" "$NGINX_CONF_PATH"

# 5. Create Project Structure
create_project_directory "$WWW_PATH"
create_database "$PROJECT_NAME"
generate_nginx_config "$PROJECT_NAME" "$NGINX_CONF_PATH"

# 6. System and Service Configuration
print_hosts_entry_instruction "$PROJECT_NAME"
restart_nginx

# 7. Download and Configure osTicket
download_osticket "$WWW_PATH"

# 8. Set Final Permissions
set_permissions "$PROJECT_NAME"

# 9. Print Summary
print_summary "$PROJECT_NAME"
