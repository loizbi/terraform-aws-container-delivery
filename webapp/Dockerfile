
FROM php:8.5-apache-trixie

# Check installed PHP modules
#docker run --rm php:8.5-apache php -m

ENV DEBIAN_FRONTEND=noninteractive

# Install OS/PHP dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq-dev zlib1g \
    && docker-php-ext-install pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

COPY apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Configure Apache
RUN a2enmod rewrite headers \
    && rm -f /etc/apache2/sites-enabled/000-default.conf \
    && sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf \
    && a2ensite 000-default.conf

WORKDIR /var/www/html

COPY src/ /var/www/html/

# Prepare directories for non-root Apache
RUN mkdir -p \
        /var/run/apache2 \
        /var/lock/apache2 \
        /var/log/apache2 \
        /var/lib/app \
    && chown -R www-data:www-data \
        /var/run/apache2 \
        /var/lock/apache2 \
        /var/log/apache2 \
        /var/lib/app \
    && chmod 750 /var/lib/app

# Run the entire container as this user
USER www-data

# Container health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD php -r '$s=@fsockopen("127.0.0.1",8080); exit($s ? 0 : 1);'