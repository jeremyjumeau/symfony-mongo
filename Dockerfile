FROM php:fpm-alpine

ENV NODE_PATH /usr/lib/node_modules
ENV BEHAT_PARAMS='{"extensions" : {"Behat\\MinkExtension" : {"base_url" : "http://test"}}}'
ENV TERM="xterm"
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APCU_VERSION 5.1.8

MAINTAINER Jeremy Jumeau <jumeau.jeremy@gmail.com>

# Minimal packages
RUN apk add --no-cache --virtual .persistent-deps \
        acl \
	bash \
	git \
        icu-libs \
        nodejs \
        zlib \
    # fix www-data uid
    && sed -ri 's/^www-data:x:82:82:/www-data:x:1000:50:/' /etc/passwd

# PHP extensions
RUN set -xe \
	&& apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        imagemagick-dev \
        libmcrypt-dev \
        libtool \
        openldap-dev \
        openssl-dev \
        zlib-dev \
    && pecl install mongodb \
    && pecl install imagick-beta \
	&& docker-php-ext-install \
        intl \
        ldap \
        mbstring \
        mcrypt \
        opcache \
        sockets \
        zip \
	&& pecl install \
        apcu-${APCU_VERSION} \
    && docker-php-ext-enable \
        apcu \
        mongodb \
        opcache \
        imagick \
    && runDeps="$( \
		scanelf --needed --nobanner --recursive \
			/usr/local/lib/php/extensions \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --virtual .phpexts-rundeps $runDeps \
	&& apk del .build-deps

# Composer
COPY install-composer.sh /usr/local/bin/docker-app-install-composer
RUN set -xe \
    && chmod +x /usr/local/bin/docker-app-install-composer \
	&& apk add --no-cache --virtual .composer-deps \
        openssl \
	&& docker-app-install-composer \
	&& mv composer.phar /usr/local/bin/composer \
	&& apk del .composer-deps

# Wkhtmltopdf
RUN set -xe \
#   # This package version does not include qt-patch
# 	&& apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
#         wkhtmltopdf
    && curl -LO https://github.com/madnight/docker-alpine-wkhtmltopdf/raw/846f9133cc89d83e017119e74652d0e77ccfb54b/wkhtmltopdf \
    && mv wkhtmltopdf /usr/local/bin/wkhtmltopdf \
    && chmod +x /usr/local/bin/wkhtmltopdf \
    && apk add --no-cache \
        libgcc libstdc++ libx11 glib libxrender libxext libintl

# Yarn + Gulp & Zombie
RUN set -xe \
	&& apk add --no-cache \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
        yarn \
    && yarn global add gulp zombie

WORKDIR /var/www
