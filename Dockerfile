FROM php:8.3-fpm

ENV COMPOSER_ALLOW_SUPERUSER 1

RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) gd

RUN pecl install xdebug \
	&& docker-php-ext-enable xdebug
RUN { \
		echo "xdebug.mode=debug"; \
		echo "xdebug.client_host=10.1.5.75"; \
		echo "xdebug.client_port=10443"; \
	} > /usr/local/etc/php/conf.d/xdebug.ini

RUN apt-get install -y libonig-dev  && \
	docker-php-ext-install mysqli pdo pdo_mysql mbstring opcache
RUN { \
		echo 'opcache.memory_consumption=256'; \
		echo 'opcache.validate_timestamps=0'; \
		echo 'opcache.interned_strings_buffer=16'; \
		echo 'opcache.max_accelerated_files=55000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \ 
        echo 'realpath_cache_size = 4096k'; \
        echo 'realpath_cache_ttl = 7200'; \
        echo 'expose_php = Off'; \
    } > /usr/local/etc/php/conf.d/php.ini

RUN { \
	echo 'pm.status_path = /status'; \
	} > /usr/local/etc/php-fpm.d/status.ini

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
