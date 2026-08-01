# Use the official PHP 8.4 FPM image as the base
FROM php:8.4-fpm

# Set environment variable to allow Composer to run as superuser
ENV COMPOSER_ALLOW_SUPERUSER 1

# Install necessary development libraries for extensions
# libfreetype6-dev, libjpeg62-turbo-dev, libpng-dev are for GD
# libonig-dev is for mbstring
# libssl-dev is required for the php-redis extension
# libsqlite3-dev and libcurl4-openssl-dev are for sqlite3 and curl extensions
# libgmp-dev and libsodium-dev are for gmp and sodium crypto extensions
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libonig-dev \
        libssl-dev \
        libsqlite3-dev \
        libcurl4-openssl-dev \
        libgmp-dev \
        libsodium-dev && \
    # Configure and install GD extension
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd

# Install Xdebug PHP extension
RUN pecl install xdebug && \
    docker-php-ext-enable xdebug

# Configure Xdebug settings
RUN { \
        echo "xdebug.mode=debug"; \
        echo "xdebug.discover_client_host=true"; \
        echo "xdebug.client_host=10.1.5.114"; \
        echo "xdebug.client_port=10443"; \
    } > /usr/local/etc/php/conf.d/xdebug.ini

# Install common PHP extensions: mysqli, pdo, pdo_mysql, mbstring, opcache, gmp, sodium
RUN docker-php-ext-install mysqli pdo pdo_mysql mbstring opcache gmp sodium

# --- START: Add Redis, SQLite, Curl Extensions ---
# Install Redis PHP extension using pecl
RUN pecl install redis && \
    docker-php-ext-enable redis

# Install SQLite3 and Curl PHP extensions (Note: json is built-in natively since PHP 8.0)
RUN docker-php-ext-install -j$(nproc) sqlite3 curl
# --- END: Add Redis, SQLite, Curl Extensions ---

# Configure OPcache settings
RUN { \
        echo 'opcache.memory_consumption=256'; \
        echo 'opcache.validate_timestamps=0'; \
        echo 'opcache.interned_strings_buffer=16'; \
        echo 'opcache.max_accelerated_files=55000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Configure general PHP settings
RUN { \
        echo 'realpath_cache_size = 4096k'; \
        echo 'realpath_cache_ttl = 7200'; \
        echo 'expose_php = Off'; \
    } > /usr/local/etc/php/conf.d/php.ini

# Configure PHP-FPM status path
RUN { \
    echo 'pm.status_path = /status'; \
    } > /usr/local/etc/php-fpm.d/status.ini

# Configure PHP-FPM pool settings
RUN { \
        echo '[www]'; \
        echo 'user = www-data'; \
        echo 'group = www-data'; \
        echo 'listen = 127.0.0.1:9000'; \
        echo 'pm = dynamic'; \
        echo 'pm.max_children = 86'; \
        echo 'pm.start_servers = 21'; \
        echo 'pm.min_spare_servers = 21'; \
        echo 'pm.max_spare_servers = 64'; \
    } > /usr/local/etc/php-fpm.d/www.conf