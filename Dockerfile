# ---------- STAGE 1 : Composer ----------
FROM composer:2 AS composer_stage
WORKDIR /app

# Copie uniquement les fichiers Composer pour profiter du cache Docker
COPY composer.json composer.lock symfony.lock* ./

# Debug : versions
RUN php -v && composer -V

# Install des vendors sans scripts
RUN COMPOSER_MEMORY_LIMIT=-1 composer install \
    --no-dev --prefer-dist --optimize-autoloader --no-interaction --no-scripts -vvv

# ---------- STAGE 2 : PHP + Apache ----------
FROM php:8.3-apache

# Paquets requis
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip libicu-dev libzip-dev libonig-dev libpng-dev \
 && rm -rf /var/lib/apt/lists/*

# Extensions PHP utiles pour Symfony
RUN docker-php-ext-configure intl \
 && docker-php-ext-install -j$(nproc) intl pdo_mysql zip opcache

# Apache : mod_rewrite et docroot -> /public
RUN a2enmod rewrite \
 && sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
 && sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/apache2.conf

# Composer (pour dump-autoload si besoin)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    APP_ENV=prod

WORKDIR /var/www/html

# 1) Copie des vendors générés au stage composer en réglant la propriété (plus fiable que chown en RUN)
#    COPY --chown est supporté par Docker & BuildKit. Si votre builder ne supporte pas --chown, enlevez l'option.
COPY --from=composer_stage --chown=www-data:www-data /app/vendor ./vendor
COPY --chown=www-data:www-data composer.json composer.lock symfony.lock* ./

# Debug: montrer extensions PHP
RUN php -v && php -m && composer -V

# 2) Copie du reste de l’app en donnant la propriété à www-data (évite chown récursif fragile)
#    Si votre builder ne supporte pas --chown, enlevez l'option COPY --chown et voir fallback ci-dessous.
COPY --chown=www-data:www-data . .

# Assurer l'existence des dossiers var et public et appliquer des permissions non bloquantes
RUN mkdir -p var public \
 && (chown -R www-data:www-data var public || true) \
 && (find var -type d -exec chmod 775 {} \; || true) \
 && (find var -type f -exec chmod 664 {} \; || true)

# (Option) dump autoload propre après copie complète
RUN composer dump-autoload --optimize --no-dev

# Warmup cache (si APP_ENV=prod set)
RUN php bin/console cache:clear --env=prod --no-warmup \
 && php bin/console cache:warmup --env=prod -vvv || (echo "⚠️ cache:warmup a échoué; on continue pour inspecter en runtime" && true)

EXPOSE 80
CMD ["apache2-foreground"]