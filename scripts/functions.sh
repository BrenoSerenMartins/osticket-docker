#!/bin/bash

# =============================================
# Library of Functions for osTicket Scripts
# =============================================

# --- Colors and Styles ---
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BOLD='\033[1m'
RESET='\033[0m'

print_header() {
    echo -e "${CYAN}============================================="
    echo -e "${BOLD}osTicket Project Creator${RESET}"
    echo -e "=============================================${RESET}"
}

validate_input() {
    if [ -z "$1" ]; then
        echo -e "${RED}${BOLD}Error:${RESET} Project name is required."
        echo -e "${YELLOW}Usage:${RESET} $0 <project-name>"
        exit 1
    fi

    if ! [[ "$1" =~ ^[a-z0-9.-]+$ ]]; then
        echo -e "${RED}${BOLD}Error:${RESET} Invalid project name."
        echo -e "${YELLOW}Use only lowercase letters, numbers, hyphens, and dots (e.g., my-osticket.local).${RESET}"
        exit 1
    fi
}

check_project_exists() {
    if [ -d "$1" ] || [ -f "$2" ]; then
        echo -e "${RED}${BOLD}Error:${RESET} A project with the name '${PROJECT_NAME}' already exists."
        echo -e "Directory: $1"
        echo -e "Nginx Config: $2"
        exit 1
    fi
}

create_project_directory() {
    echo -e "${YELLOW}Creating project directory: $1...${RESET}"
    mkdir -p "$1"
    echo -e "${GREEN}✔ Project directory created!${RESET}"
}

create_database() {
    local db_database="osticket_$(echo "$1" | sed 's/[.-]/_/g')"
    local db_username="${MYSQL_USER:-osticket_user}"
    local db_password="${MYSQL_PASSWORD:-osticket_password}"

    echo -e "${YELLOW}Creating MySQL database: ${db_database}...${RESET}"
    
    # Ensure MySQL service is running
    docker compose ps -q mysql > /dev/null || { echo -e "${RED}Error: MySQL service is not running. Please start the docker environment first.${RESET}"; exit 1; }

    docker compose exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${db_database};"
    docker compose exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${db_username}'@'%' IDENTIFIED BY '${db_password}';"
    docker compose exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${db_database}.* TO '${db_username}'@'%';"
    docker compose exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

    echo -e "${GREEN}✔ Database ${db_database} ready!${RESET}"
    echo -e "${YELLOW}Database Name:${RESET} ${db_database}"
    echo -e "${YELLOW}Database User:${RESET} ${db_username}"
    echo -e "${YELLOW}Database Password:${RESET} ${db_password}"
}

generate_nginx_config() {
    echo -e "${YELLOW}Generating Nginx configuration at: $2...${RESET}"
    cp "${SCRIPT_DIR}/../nginx/conf.d/osticket.conf.example" "$2"
    sed -i "s/{{PROJECT_NAME}}/$1/g" "$2"
    echo -e "${GREEN}✔ Nginx configuration created!${RESET}"
}

print_hosts_entry_instruction() {
    echo -e "\n${YELLOW}============================================="
    echo -e "${BOLD}IMPORTANT: Add Host Entry${RESET}"
    echo -e "=============================================${RESET}"
    echo -e "Please add the following line to your /etc/hosts file (requires sudo):"
    echo -e "${GREEN}    127.0.0.1   $1${RESET}"
    echo -e "You can run: ${BOLD}echo '127.0.0.1   $1' | sudo tee -a /etc/hosts${RESET}"
}

restart_nginx() {
    echo -e "${YELLOW}Restarting the webserver (nginx)...${RESET}"
    docker compose restart nginx
    echo -e "${GREEN}✔ Webserver restarted!${RESET}"
}

download_osticket() {
    local project_path="$1"
    local osticket_version="1.18.3" # Latest stable version at the moment
    local download_url="https://github.com/osTicket/osTicket/releases/download/v${osticket_version}/osTicket-v${osticket_version}.zip"
    local temp_dir="/tmp/osticket_download"
    local zip_file="${temp_dir}/osTicket-v${osticket_version}.zip"
    local extracted_path="${temp_dir}/osTicket-v${osticket_version}"

    echo -e "\n${CYAN}============================================="
    echo -e "${BOLD}Automated osTicket Download${RESET}"
    echo -e "=============================================${RESET}"
    echo -e "${YELLOW}Downloading osTicket v${osticket_version} from GitHub...${RESET}"
    
    mkdir -p "${temp_dir}"
    curl -L "${download_url}" -o "${zip_file}"

    echo -e "${YELLOW}Extracting osTicket files...${RESET}"
    unzip -q "${zip_file}" -d "${extracted_path}"

    echo -e "${YELLOW}Copying osTicket files to ${project_path}...${RESET}"
    # osTicket places core files in an 'upload' subdirectory within the extracted zip
    rsync -a "${extracted_path}/upload/" "${project_path}/"
    
    echo -e "${YELLOW}Removing temporary files...${RESET}"
    rm -rf "${temp_dir}"
    echo -e "${GREEN}✔ osTicket download and setup complete!${RESET}"
}

set_permissions() {
    echo -e "${YELLOW}Setting file permissions for ${1}...${RESET}"
    
    # Ensure the php-fpm service is running before attempting to exec
    if ! docker compose ps php-fpm | grep -q 'Up'; then
        echo -e "${RED}Error: PHP-FPM service is not in a running state. Cannot set permissions.${RESET}"
        exit 1
    fi

    # Adjust paths for execution inside the container
    local container_project_path="/var/www/$1"

    # osTicket requires write permissions for certain directories by the web server
    # www-data is the typical user for nginx/php-fpm in debian based images
    docker compose exec -T php-fpm chown -R www-data:www-data "$container_project_path"
    docker compose exec -T php-fpm find "$container_project_path" -type d -exec chmod 755 {} \; # Directories 755
    docker compose exec -T php-fpm find "$container_project_path" -type f -exec chmod 644 {} \; # Files 644

    # osTicket specific permissions for /include directory
    # 'include' dir and 'ost-config.php' needs to be writable during setup
    # The config file is named ost-sampleconfig.php before setup.
    if docker compose exec -T php-fpm [ -f "$container_project_path/include/ost-sampleconfig.php" ]; then
        docker compose exec -T php-fpm chmod 666 "$container_project_path/include/ost-sampleconfig.php"
    fi
    
    echo -e "${GREEN}✔ File permissions set!${RESET}"
}

print_summary() {
    echo -e "\n${CYAN}============================================="
    echo -e "${BOLD}Installation Ready!${RESET}"
    echo -e "=============================================${RESET}"
    echo -e "${YELLOW}Access the site to begin the installation process:${RESET}"
    echo -e "   http://$1"
    echo -e "\n${GREEN}All set! Open the URL above in your browser to complete the installation.${RESET}"
}

