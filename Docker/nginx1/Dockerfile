# Usar Ubuntu 20.04 como imagen base
FROM ubuntu:20.04

# Establecer la variable de entorno para evitar la interacción durante la instalación de paquetes
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar el sistema e instalar los paquetes necesarios
RUN apt-get update && apt-get install -y \
    sed \
    supervisor \
    nginx-full \
    curl \
    unzip \
    mariadb-client \
    netcat && \
    apt-get clean \
    open-ssl

# Descargar e instalar OwnCloud
RUN curl -L -o /var/www/owncloud.zip https://download.owncloud.com/server/stable/owncloud-complete-20240724.zip && \
    unzip -o /var/www/owncloud.zip -d /var/www/ && \
    rm /var/www/owncloud.zip && \
    chown -R www-data:www-data /var/www/owncloud && \
    chown -R www-data:www-data /var/www/owncloud

# Copiar la configuración personalizada de Nginx para OwnCloud
COPY nginx-owncloud.conf /etc/nginx/sites-available/default

# Copiar la configuración de Supervisor para gestionar los procesos
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Exponer el puerto 80 para que Nginx pueda aceptar conexiones HTTP
EXPOSE 80

# Iniciar el Supervisor que gestionará Nginx y otros procesos en primer plano
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
