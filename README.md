# Dockerized osTicket Environment

This project provides a complete, Docker-based local development environment for hosting one or more [osTicket](https://osticket.com/) instances. It is inspired by a multi-project Magento 1 setup, using scripts to automate the creation and deletion of osTicket projects.

## Services

The `docker-compose.yml` file orchestrates the following services:

-   **Nginx:** Web server (`nginx:1.21-alpine`).
-   **PHP-FPM:** PHP processor (`php:8.2-fpm-bullseye`) with all required extensions for osTicket.
-   **MySQL:** Database server (`mysql:8.0`).
-   **phpMyAdmin:** Database management tool.

## Prerequisites

-   [Docker](https://docs.docker.com/get-docker/)
-   [Docker Compose](https://docs.docker.com/compose/install/) (V2 syntax: `docker compose`)

## Getting Started

This environment uses scripts to manage projects. Each project will have its own subdirectory in `www/` and a corresponding Nginx configuration in `nginx/conf.d/`.

### 1. Configure Environment Variables

First, create your local environment file by copying the example:

```bash
cp .env.example .env
```

You can edit the `.env` file to change the default MySQL root password if you wish.

### 2. Build the Docker Images

Before running the scripts, build the Docker images:

```bash
docker compose build
```

### 3. Creating a New osTicket Project

Use the `create-osticket-project.sh` script to set up a new osTicket site.

**Usage:**

```bash
./scripts/create-osticket-project.sh <project-name>
```

Replace `<project-name>` with a domain-like name for your project (e.g., `my-ticket-system.local`).

**Example:**

```bash
./scripts/create-osticket-project.sh my-osticket.local
```

The script will automatically:
1.  Create a directory: `www/my-osticket.local/`.
2.  Create a MySQL database (e.g., `osticket_my_osticket_local`).
3.  Generate an Nginx configuration file: `nginx/conf.d/my-osticket.local.conf`.
4.  Download the latest version of osTicket into the project directory.
5.  Set the correct file permissions.
6.  Restart the Nginx container to apply the new configuration.
7.  Provide you with the necessary line to add to your `/etc/hosts` file.

After running the script, add the provided entry to your `/etc/hosts` file and access the site (e.g., `http://my-osticket.local:8081`) to begin the osTicket web installation.

### 4. Enabling SSL (HTTPS)

After creating a project, you can enable SSL for it using the `enable-ssl.sh` script. This will allow you to access your project via `https://`.

**Usage:**

```bash
sudo ./scripts/enable-ssl.sh <project-name>
```

**Example:**

```bash
sudo ./scripts/enable-ssl.sh my-osticket.local
```

The script will:
1.  Generate a self-signed SSL certificate (`.crt`) and key (`.key`).
2.  Create a new Nginx configuration that handles HTTPS and redirects HTTP traffic.
3.  Restart the Nginx container.

After running the script, you will need to **import and trust the generated certificate** in your operating system or browser to avoid security warnings. The certificate will be located at `nginx/certs/<project-name>.crt`.

Once the certificate is trusted, you can access your site at `https://<project-name>:8443`.

### 5. Removing an osTicket Project

To remove a project, including its files, Nginx configuration, and database, use the `remove-osticket-project.sh` script.

**Usage:**

```bash
./scripts/remove-osticket-project.sh <project-name>
```

**Example:**

```bash
./scripts/remove-osticket-project.sh my-osticket.local
```

This will permanently delete the project's directory, its Nginx config, and its database.

## Platform Specific Notes

### WSL (Windows Subsystem for Linux) Users

If you are running this environment from within WSL, you will need to perform two extra steps on your **Windows host machine** for domains and SSL to work correctly in your browser.

1.  **Edit Windows `hosts` File:**
    You must add the project domain entry to the Windows `hosts` file, which is separate from the WSL `/etc/hosts` file.
    -   File location: `C:\Windows\System32\drivers\etc\hosts`
    -   You will need to edit this file as an Administrator.
    -   Add the same line you were instructed to add by the script (e.g., `127.0.0.1 my-osticket.local`).

2.  **Trust SSL Certificate on Windows:**
    When you enable SSL, the self-signed certificate must be trusted by the Windows OS.
    -   Find the `.crt` file inside the project's `nginx/certs/` directory.
    -   Double-click the `.crt` file on Windows.
    -   Click "Install Certificate...".
    -   Choose "Local Machine" and click Next.
    -   Select "Place all certificates in the following store".
    -   Click "Browse..." and choose "Trusted Root Certification Authorities".
    -   Click OK, Next, and Finish.
    -   Restart your browser.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
