# Usar la imagen base de PHP 7.4 con FPM
FROM php:7.4-fpm

# Instalar dependencias necesarias y extensiones de PHP
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libzip-dev \
    libsqlite3-dev \
    libonig-dev \
    libldap2-dev \
    libbz2-dev \
    libxslt-dev \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    zip intl gd xml curl pdo pdo_mysql mysqli bz2 opcache mbstring ldap xsl pcntl \
    && apt-get clean && rm -rf /var/lib/apt/lists/

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configuración de Opcache para mejorar el rendimiento de PHP
RUN echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=4000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini

# Exponer el puerto 9000 para PHP-FPM
EXPOSE 9000

# Copiar el script de entrada al contenedor
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# Asegurar permisos de ejecución para el script de entrada
RUN chmod +x /usr/local/bin/entrypoint.sh

# Establecer el script de entrada como el punto de inicio del contenedor
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
