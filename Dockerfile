
FROM composer:2 AS composer_stage
WORKDIR /app

COPY composer.json composer.lock symfony.lock* ./

RUN php -v && composer -V

RUN COMPOSER_MEMORY_LIMIT=-1 composer install \
    --no-dev --prefer-dist --optimize-autoloader --no-interaction --no-scripts -vvv

FROM php:8.3-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip libicu-dev libzip-dev libonig-dev libpng-dev \
 && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure intl \
 && docker-php-ext-install -j$(nproc) intl pdo_mysql zip opcache

RUN a2enmod rewrite \
 && sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
 && sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/apache2.conf

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    APP_ENV=prod

WORKDIR /var/www/html

COPY --from=composer_stage --chown=www-data:www-data /app/vendor ./vendor
COPY --chown=www-data:www-data composer.json composer.lock symfony.lock* ./

RUN php -v && php -m && composer -V

COPY --chown=www-data:www-data . .

RUN mkdir -p var public \
 && (chown -R www-data:www-data var public || true) \
 && (find var -type d -exec chmod 775 {} \; || true) \
 && (find var -type f -exec chmod 664 {} \; || true)

RUN composer dump-autoload --optimize --no-dev

RUN php bin/console cache:clear --env=prod --no-warmup \
 && php bin/console cache:warmup --env=prod -vvv || (echo "⚠️ cache:warmup a échoué; on continue pour inspecter en runtime" && true)

COPY ./docker/render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN chmod +x /usr/local/bin/render-entrypoint.sh

EXPOSE 80

CMD ["/usr/local/bin/render-entrypoint.sh"]