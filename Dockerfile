FROM php:7.1-apache

LABEL maintainer="S-Kazuki<contact@revoneo.com>"

ENV APACHE_DOCUMENT_ROOT /var/www/html/html

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
  git curl wget sudo libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libmcrypt-dev libxml2-dev libpq-dev libpq5 mysql-client ssl-cert libicu-dev unzip \
  \
  && pecl channel-update pecl.php.net \
  && pecl install apcu \
  && echo "extension=apcu.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"` \
  \
  && docker-php-ext-configure \
  gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  \
  && docker-php-ext-install -j$(nproc) \
  mbstring zip gd xml pdo pdo_mysql soap mcrypt intl \
  \
  && rm -r /var/lib/apt/lists/* \
  \
  && a2enmod rewrite \
  \
  && curl -sS https://getcomposer.org/installer | php -- \
  --filename=composer \
  --install-dir=/usr/local/bin \
  \
  && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
  && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
  \
  && chown -R www-data: /var/www

USER www-data
RUN composer global require --optimize-autoloader \
  "hirak/prestissimo"
USER root

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
