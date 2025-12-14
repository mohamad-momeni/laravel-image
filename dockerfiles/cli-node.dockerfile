FROM node:24 AS node
FROM composer:2 AS composer
FROM php:8.4-cli

LABEL maintainer="Mohamad Momeni"
ENV TZ=Asia/Tehran
WORKDIR /var/www

RUN apt-get update && apt-get install -y --no-install-recommends \
   # Required for Postgres
   libpq-dev \
   # Required for LDAP extension
   libldap2-dev \
   # Required for Zip extension
   libzip-dev \
   # Required for Yaml extension
   libyaml-dev \
   # Required for Swoole extension
   libssl-dev \
   # Utilities
   nano \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
   && docker-php-ext-install -j$(nproc) exif pdo_mysql pdo_pgsql pgsql ldap pcntl zip \
   && pecl install imap yaml redis swoole && docker-php-ext-enable imap yaml redis swoole

COPY resources/sourceguardian.so /tmp/sourceguardian.so
RUN mv /tmp/sourceguardian.so $(php-config --extension-dir) && echo 'extension=sourceguardian.so' > /usr/local/etc/php/conf.d/docker-php-ext-sourceguardian.ini
COPY resources/php.ini /usr/local/etc/php/conf.d/custom.ini

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/include/node /usr/local/include/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
RUN ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx