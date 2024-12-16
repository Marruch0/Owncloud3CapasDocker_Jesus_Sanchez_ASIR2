# Usar Ubuntu 20.04 como imagen base
FROM ubuntu:20.04

# Establecer la variable de entorno para evitar la interacción durante la instalación de paquetes
ENV DEBIAN_FRONTEND=noninteractive

# Actualiza el sistema e instala las dependencias necesarias
RUN apt-get update && apt-get install -y \
    supervisor \
    nginx-full \
    curl \
    unzip \
    mariadb-client \
    netcat && \   
    apt-get clean \
    open-ssl

# Copiar la configuración personalizada de Nginx para OwnCloud
COPY nginx-owncloud.conf /etc/nginx/sites-available/default

# Copiar la configuración de Supervisor para gestionar los procesos
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Exponer el puerto 80 para que Nginx pueda aceptar conexiones HTTP
EXPOSE 80

# Iniciar Supervisor que gestionará Nginx y otros procesos
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
