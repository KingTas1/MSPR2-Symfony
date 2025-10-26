# ---------- STAGE 1 : Composer ----------
FROM composer:2 AS composer_stage
WORKDIR /app

# Copie uniquement les fichiers Composer pour profiter du cache Docker
COPY composer.json composer.lock symfony.lock* ./

# Debug : versions
RUN php -v && composer -V

# Install des vendors sans scripts (évite les plantages de recettes post-install)
# -vvv : logs détaillés si ça casse
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

# Vars d'env “build”
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    APP_ENV=prod

WORKDIR /var/www/html

# 1) Copie des vendors générés au stage composer
COPY --from=composer_stage /app/vendor ./vendor
COPY composer.json composer.lock symfony.lock* ./

# Debug: montrer extensions PHP
RUN php -v && php -m && composer -V

# 2) Copie du reste de l’app (code, config, public/, public/app si tu serres ton build React ici)
COPY . .

# Permissions cache/logs
RUN chown -R www-data:www-data var public \
 && find var -type d -exec chmod 775 {} \; \
 && find var -type f -exec chmod 664 {} \;

# (Option) dump autoload propre après copie complète
RUN composer dump-autoload --optimize --no-dev

# Warmup cache (si APP_ENV=prod set & pas de scripts manquants)
# Si ça casse ici, c’est souvent un problème de DATABASE_URL manquant côté Render (à mettre dans les envs Render).
RUN php bin/console cache:clear --env=prod --no-warmup \
 && php bin/console cache:warmup --env=prod -vvv || (echo "⚠️ cache:warmup a échoué; on continue pour inspecter en runtime" && true)

EXPOSE 80
CMD ["apache2-foreground"]
