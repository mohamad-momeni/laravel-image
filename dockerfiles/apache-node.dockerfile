FROM node:22 AS node
FROM composer:2 AS composer
FROM php:8.3-apache

LABEL maintainer="Mohamad Momeni"
ENV TZ=Asia/Tehran
WORKDIR /var/www

RUN apt-get update && apt-get install -y \ 
   # Required for GD extension
   zlib1g-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
   # Required for IMAP extension
   libc-client-dev libkrb5-dev \
   # Required for LDAP extension
   libldap2-dev \
   # Required for Zip extension
   libzip-dev \
   # Required for Swoole extension
   libbrotli-dev libssl-dev \
   # Utilities
   cron \
   nano \
   supervisor \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
   && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
   && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
   && docker-php-ext-install -j$(nproc) exif pdo pdo_mysql imap ldap pcntl zip \
   && pecl install redis swoole && docker-php-ext-enable redis swoole

COPY resources/ixed.8.3.lin /tmp/sourceguardian.so
RUN mv /tmp/sourceguardian.so $(php-config --extension-dir) && echo 'extension=sourceguardian.so' > /usr/local/etc/php/conf.d/docker-php-ext-sourceguardian.ini

COPY resources/mysupervisor /etc/mysupervisor
COPY resources/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY resources/crontab /etc/cron.d/laravel-cron

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY resources/apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite headers

COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/include/node /usr/local/include/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
RUN ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx