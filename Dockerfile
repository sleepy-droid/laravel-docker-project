# Use official PHP Apache image as base (includes PHP 8.2+ and Apache)
FROM php:8.2-apache

# Install system dependencies and PHP extensions for Laravel
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite for Laravel routes
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Install Laravel
RUN composer create-project laravel/laravel . --prefer-dist

# Generate Laravel app key (required for security)
RUN php artisan key:generate --no-interaction --force

# Set permissions for Laravel storage/cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Configure Apache to serve from /public (Laravel's entry point)
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf && \
    echo "ServerName localhost" >> /etc/apache2/sites-available/000-default.conf

# Ensure .htaccess is copied (Laravel's default for routing)
RUN cp /var/www/html/public/.htaccess /var/www/html/.htaccess

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]