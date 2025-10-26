# 🐳 Image de base avec PHP 8.3 + Apache
FROM php:8.3-apache

# Installe les extensions nécessaires à Symfony + Doctrine
RUN apt-get update && apt-get install -y \
    git unzip libpq-dev libzip-dev zip \
    && docker-php-ext-install pdo pdo_mysql

# Définit le dossier de travail
WORKDIR /var/www/html

# Copie tout le code dans le conteneur
COPY . .

# Installe Composer depuis l'image officielle
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Installe les dépendances Symfony (sans dev)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Active mod_rewrite (pour le routing Symfony)
RUN a2enmod rewrite

# Prépare le cache Symfony
RUN php bin/console cache:warmup --env=prod

# Configure Apache pour servir depuis /public
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!/var/www/html/public!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Expose le port utilisé par Render
EXPOSE 8080

# ✅ Commande exécutée automatiquement au démarrage
CMD ["apache2-foreground"]
