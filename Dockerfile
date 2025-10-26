# --- Base Apache + PHP 8.3 ---
FROM php:8.3-apache

# 1) Paquets nécessaires (git, unzip, ICU pour intl, zip, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip libicu-dev libzip-dev libonig-dev libpng-dev \
    && rm -rf /var/lib/apt/lists/*

# 2) Extensions PHP (pdo_mysql, intl, opcache)
RUN docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl pdo_mysql opcache

# 3) Apache: activer mod_rewrite et pointer sur /public
RUN a2enmod rewrite \
 && sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
 && sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/apache2.conf

# 4) Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 5) Variables utiles pour composer
ENV COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_ALLOW_SUPERUSER=1 \
    APP_ENV=prod

WORKDIR /var/www/html

# 6) Install vendor en 2 temps pour le cache Docker
COPY composer.json composer.lock symfony.lock* ./
# Ajoute -vvv pour des logs en cas d’échec
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist -vvv

# 7) Copier le reste de l’app (entités, contrôleurs, templates, public/app, etc.)
COPY . .

# 8) Donner les droits d’écriture (cache/logs)
RUN chown -R www-data:www-data var public \
 && find var -type d -exec chmod 775 {} \; \
 && find var -type f -exec chmod 664 {} \;

# 9) Warmup du cache prod (facultatif mais recommandé)
RUN php bin/console cache:clear --env=prod --no-warmup \
 && php bin/console cache:warmup --env=prod

# Render mappe le port via un proxy; Apache écoute 80
EXPOSE 80

CMD ["apache2-foreground"]
