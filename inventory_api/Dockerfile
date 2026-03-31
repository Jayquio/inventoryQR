FROM php:8.2-apache

# Install dependencies and mysqli for database connection
RUN apt-get update && apt-get install -y \
    curl \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && docker-php-ext-enable mysqli

# Enable Apache mod_rewrite if needed
RUN a2enmod rewrite

# Add a simple ServerName directive to suppress the warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Copy API files to Apache root
COPY . /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html/
