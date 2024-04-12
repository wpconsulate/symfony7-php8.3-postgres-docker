FROM php:8.3-apache

RUN apt-get update -y && apt-get install -y libpng-dev
RUN pecl install xdebug-3.3.1
RUN docker-php-ext-enable xdebug
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

RUN apt install libicu-dev -y
RUN docker-php-ext-install intl && docker-php-ext-enable intl


RUN a2enmod rewrite && a2enmod ssl && a2enmod socache_shmcb
# RUN sed -i '/SSLCertificateFile.*snakeoil\.pem/c\SSLCertificateFile \/etc\/ssl\/certs\/localhost.crt' /etc/apache2/sites-available/default-ssl.conf && sed -i '/SSLCertificateKeyFile.*snakeoil\.key/cSSLCertificateKeyFile /etc/ssl/private/localhost.key\' /etc/apache2/sites-available/default-ssl.conf
# RUN a2ensite default-ssl

RUN mkdir /tmp/staging
# Overwritting default 000-default.conf
#COPY --from=staging /opt/workspace/vhost-000-default.conf /etc/apache2/sites-enabled/000-default.conf
# COPY --from=staging /opt/workspace/php.ini /tmp/staging/php.ini

COPY ./docker/configs/php.ini /tmp/staging/php.ini

# --------------------------------------------
# replace Apache DOCUMENT_ROOT
# --------------------------------------------
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${x}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
COPY ./docker/configs/000-default.conf /etc/apache2/sites-enabled/000-default.conf

# --------------------------------------------
# install Symfony
# --------------------------------------------
WORKDIR /tmp
RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

COPY ./docker/configs/start-apache /usr/local/bin
RUN chmod 755 /usr/local/bin/start-apache

RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN cat /tmp/staging/php.ini >> "$PHP_INI_DIR/php.ini"
RUN rm -rf /tmp/staging

RUN ln -sf /dev/stderr /var/log/apache2/error.log && ln -sf /dev/stdout /var/log/apache2/access.log
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite
RUN a2enmod env

WORKDIR /var/www/html
EXPOSE 80


CMD ["start-apache"]