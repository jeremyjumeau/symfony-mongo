FROM php:fpm


ENV NODE_PATH /usr/lib/node_modules
ENV BEHAT_PARAMS='{"extensions" : {"Behat\\MinkExtension" : {"base_url" : "http://test"}}}'

MAINTAINER Jeremy Jumeau <jumeau.jeremy@gmail.com>

# PHP extensions
RUN apt-get update && apt-get install -y \
        apt-utils \
        git \
        libicu-dev \
        libldap2-dev \
        libmagickwand-dev \
        libmcrypt-dev \
        libssl-dev \
        zlib1g-dev \
    && pecl install mongodb \
    && pecl install imagick-beta \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install \
        intl \
        ldap \
        mbstring \
        mcrypt \
        opcache \
        sockets \
        zip \
    && docker-php-ext-enable \
        mongodb \
        imagick

# Wkhtmltopdf
RUN apt-get install -y \
        libxrender-dev \
        wget \
        xz-utils \
    && wget http://download.gna.org/wkhtmltopdf/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
    && tar xf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
    && cp wkhtmltox/bin/wkhtmltopdf /usr/local/bin/ \
    && cp wkhtmltox/bin/wkhtmltoimage /usr/local/bin/

# Composer
RUN php -r "readfile('https://getcomposer.org/installer');" > composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');" \
    && mkdir -p /var/.composer \
    && composer global --no-interaction --working-dir=/var/.composer require symfony/var-dumper

# Node / NPM / Bower / Gulp / Zombie.js
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && npm install -g bower \
    && npm install -g gulp \
    && npm install -g zombie --save-dev
