# Dockerfile
FROM php:5.6-apache
LABEL author="dblencowe <me@dblencowe.com>" 

# Fix docker-php-ext-install script error
RUN sed -i 's/docker-php-\(ext-$ext.ini\)/\1/' /usr/local/bin/docker-php-ext-install

# Install other needed extensions
RUN apt-get update && apt-get install -y libicu52 zlib1g-dev build-essential libfreetype6 git-core mysql-client ghostscript imagemagick libjpeg62-turbo libmcrypt4 libpng12-0 sendmail --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN buildDeps=" \
        libfreetype6-dev \
        libjpeg-dev \
        libldap2-dev \
        libmcrypt-dev \
        libpng12-dev \
        libmagickwand-dev \
        libxml2-dev \
        libicu-dev \
    "; \
    set -x \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --enable-gd-native-ttf --with-jpeg-dir=/usr/lib/x86_64-linux-gnu --with-png-dir=/usr/lib/x86_64-linux-gnu --with-freetype-dir=/usr/lib/x86_64-linux-gnu \
    && docker-php-ext-install gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install ldap \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install mcrypt \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install opcache \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install zip \
    && docker-php-ext-install soap \
    && docker-php-ext-install intl \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && apt-get purge -y --auto-remove $buildDeps \
    && cd /usr/src \
    && tar xf php.tar.xz \
    && mv php-5.6.33 php \
    && cd /usr/src/php \
    && curl -L https://pecl.php.net/get/xdebug-2.3.3.tgz >> /usr/src/php/ext/xdebug.tgz \
    && tar -xf /usr/src/php/ext/xdebug.tgz -C /usr/src/php/ext/ \
    && rm /usr/src/php/ext/xdebug.tgz \
    && docker-php-ext-install xdebug-2.3.3 \
    && cd /root \
    && curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh \
    && bash /root/nodesource_setup.sh \
    && apt-get install nodejs

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.enable=0'; \
        echo 'opcache.enable_cli=0'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
        echo 'xdebug.remote_enable=1'; \
        echo 'xdebug.remote_handler=dbgp'; \
        echo 'xdebug.remote_connect_back=1'; \
    } >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# PECL extensions
RUN pecl install redis memcache \
    && docker-php-ext-enable redis memcache
# Install Composer for Laravel
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Setup timezone to Etc/UTC
RUN cat /usr/src/php/php.ini-development | sed 's/^;\(date.timezone.*\)/\1 \"Europe\/London\"/' > /usr/local/etc/php/php.ini

# Disable cgi.fix_pathinfo in php.ini
RUN sed -i 's/;\(cgi\.fix_pathinfo=\)1/\10/' /usr/local/etc/php/php.ini

# Copy over apache host file
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

RUN usermod -u 1000 www-data && a2enmod rewrite

RUN rm -f /var/run/apache2/apache2.pid
RUN /usr/sbin/apache2ctl stop

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

