# Use PHP 8.2 FPM on Debian Bullseye as the base image
FROM php:8.2-fpm-bullseye

# Install system dependencies required for PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libicu-dev \
    libc-client-dev \
    libkrb5-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    libxslt-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure and install the IMAP extension
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl

# Install other required PHP extensions
RUN docker-php-ext-install \
    gd \
    mysqli \
    pdo_mysql \
    intl \
    mbstring \
    zip \
    curl \
    xsl \
    imap

# Install APCu extension for caching
RUN pecl install apcu && docker-php-ext-enable apcu

# Add custom php.ini for error reporting
COPY php.ini /usr/local/etc/php/conf.d/zz-docker-osticket.ini


# Enable opcache
RUN docker-php-ext-enable opcache

# Set the working directory
WORKDIR /var/www
