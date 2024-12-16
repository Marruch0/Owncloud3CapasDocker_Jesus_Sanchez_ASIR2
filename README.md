# Owncloud 3 capas en Docker

![5cbba74b40ec0c0ce77b3db3ec1a5e05](https://github.com/user-attachments/assets/81e580a0-206d-4e2f-984a-ff5ce2e9dc8f)

# Índice

- [Importante](#importante)
- [Introducción](#introducción)
  - [Objetivo del proyecto](#objetivo-del-proyecto)
  - [¿Por qué utilizar Docker y no Vagrant?](#por-qué-utilizar-docker-y-no-vagrant)
  - [Herramientas utilizadas](#herramientas-utilizadas)
- [Descripción de la infraestructura](#descripción-de-la-infraestructura)
  - [Docker Compose](#docker-compose)
  - [Código-Compose](#código-compose)
  - [Balanceador de carga-Capa1](#balanceador-de-carga-capa1)
    - [Código-Dockerfile](#código-dockerfile)
    - [Código-nginx.conf](#código-nginxconf)
  - [Servidores Nginx-Capa2](#servidores-nginx-capa2)
    - [Código-Dockerfile](#código-dockerfile-1)
    - [Código-nginx-owncloud.conf](#código-nginx-owncloudconf)
    - [Código-supervisord.conf](#código-supervisordconf)
  - [Php-Fpm-Capa2](#php-fpm-capa2)
    - [Código-Dockerfile](#código-dockerfile-2)
    - [Código-Entrypoint.sh](#código-entrypointsh)
  - [Mariadb-Capa3](#mariadb-capa3)
    - [Código-basededatos](#código-basededatos)
    - [Redes en Docker](#redes-en-docker)
- [Desplegar infraestructura](#desplegar-infraestructura)
- [Entrega Opcional-MariaDBGalera](#entrega-opcional-mariadbgalera)
  - [Configuración del Clúster MariaDB](#configuración-del-clúster-mariadb)
  - [Problema encontrado](#problema-encontrado)
  - [Balanceo de la Base de Datos](#balanceo-de-la-base-de-datos)
  - [Código-Compose](#código-compose-1)
- [Conclusión](#conclusión)

# Importante

Para acceder a **OwnCloud** con el dominio **`jesusnube.com`**, es necesario configurar el archivo **`/etc/hosts`** en tú máquina anfitriona añadiendo la siguiente línea:

```bash
127.0.0.1    jesusnube.com
```

Esto asegura que las solicitudes al dominio **`jesusnube.com`** se redirijan a la máquina local.

Además, después de ejecutar el comando **`docker-compose up`** para levantar los contenedores, es importante esperar entre **10 y 20 segundos** para que todos los servicios, como la base de datos y **OwnCloud**, se configuren correctamente. Es recomendable no acceder a la aplicación inmediatamente después de levantar los contenedores, ya que los servicios aún pueden estar inicializándose.

Para evitar que la terminal se quede ocupada, recomiendo usar la opción **`-d`**, lo cual levanta los contenedores en segundo plano y permite seguir usando la terminal mientras se configuran los servicios.

Recuerdo también que las credenciales para acceder a OwnCloud son admin como usuario y admin como contraseña.

# Introducción

## Objetivo del proyecto

En este proyecto se va a realizar el despliegue de una infraestructura en alta disponibilidad utilizando contenedores Docker , con el objetivo de instalar y configurar **OwnCloud** como CMS sobre una pila LEMP (Linux, Nginx, MySQL/MariaDB, PHP). La estructura de la infraestructura estará dividida en tres capas:

1. **Capa 1: Balanceador de carga Nginx** – Esta máquina actuará como el balanceador de carga y estará expuesta a la red pública. Su función será distribuir el tráfico entre los servidores web de la capa 2, asegurando que las peticiones se equilibren de manera adecuada entre los servidores.
2. **Capa 2: Servidores Web y Backend** – En esta capa estarán dos contenedores de servidores web Nginx que manejarán las solicitudes de los usuarios. En lugar de utilizar un servidor NFS, como en la versión original, se han empleado volúmenes en Docker para compartir los archivos necesarios entre los servidores web y asegurar su correcta sincronización. Además, cada servidor web tendrá el motor PHP-FPM necesario para ejecutar el CMS.
3. **Capa 3: Base de datos MariaDB** – Esta capa contará con un contenedor dedicado a MariaDB, donde se almacenarán todos los datos del CMS.

El proyecto se implementará utilizando Docker y Docker Compose, lo que permitirá gestionar de manera eficiente los contenedores y sus redes internas. Los volúmenes Docker sustituyen al servidor NFS para compartir los datos entre los contenedores, lo que simplifica la configuración y mejora la gestión de los recursos. Con esta infraestructura, se emula un entorno de producción de alta disponibilidad, donde cada capa cumple un rol específico para garantizar el correcto funcionamiento del sistema.

Este enfoque con Docker facilita la escalabilidad y la gestión de recursos, adaptándose a las necesidades de un entorno moderno y eficiente.

## **¿Por qué utilizar Docker y no Vagrant?**

He decidido usar Docker en lugar de Vagrant por varias razones:

1. **Rendimiento**: Docker es más ligero y rápido porque usa contenedores que comparten el mismo sistema operativo. En cambio, Vagrant usa máquinas virtuales, que consumen más recursos.
2. **Rapidez**: Los contenedores de Docker se inician mucho más rápido que las máquinas virtuales de Vagrant, lo que hace más ágil la creación de entornos.
3. **Facilidad de gestión**: Docker simplifica la gestión de los servicios usando Dockerfiles y Docker Compose, mientras que Vagrant requiere más trabajo con scripts y configuración de máquinas virtuales.
4. **Escalabilidad**: Docker permite escalar la infraestructura de manera más fácil y rápida, creando o eliminando contenedores. Vagrant es más complicado en este aspecto.

Por todo esto, Docker es la opción más eficiente y rápida para este proyecto.

## Herramientas utilizadas

Para este proyecto he utilizado **Docker** y **Docker Compose**.

- **Docker**: Me permite crear y gestionar contenedores para ejecutar los servicios del proyecto, como el balanceador de carga Nginx, los servidores web y la base de datos MariaDB, todo en entornos aislados y portátiles.
- **Docker Compose**: Facilita la gestión de aplicaciones con varios contenedores, permitiendo definir todos los servicios y configuraciones en un solo archivo (`docker-compose.yml`), lo que simplifica el despliegue y la administración de la infraestructura.

# Descripción de la infraestructura

## Docker Compose

El archivo `docker-compose.yml` define los servicios que forman parte de la infraestructura del proyecto. A continuación, explico cada uno de los servicios y su configuración:

- **balanceadorasir**:
    
    Este servicio configura el balanceador de carga Nginx. Se construye desde el directorio `balanceador/` y el archivo `Dockerfile` correspondiente. Está conectado a dos redes: `red-capa-1` (para la red pública) y `red-capa-2` (para la red interna). Las IPs asignadas son `192.168.22.2` en la red pública y `192.168.23.2` en la red interna. Los puertos 80 y 443 están expuestos para recibir tráfico HTTP y HTTPS. La política de reinicio es `unless-stopped`, lo que garantiza que se reinicie automáticamente si se detiene.
    
- **nginx1asir** y **nginx2asir**:
    
    Estos son los dos servidores web Nginx que recibirán el tráfico distribuido por el balanceador de carga. Se construyen desde los directorios `nginx1/` y `nginx2/` respectivamente. Ambos están conectados a la red interna `red-capa-2` y tienen las IPs `192.168.23.3` y `192.168.23.4`. El volumen `asirown` se monta en `/var/www/owncloud` para compartir los archivos del CMS. Los puertos 81 y 82 están expuestos para acceder a los servidores web. Ambos servicios dependen del servicio `balanceadorasir`, por lo que solo se inician después de que el balanceador esté listo.
    
- **phpasir**:
    
    Este servicio configura el contenedor PHP-FPM para ejecutar el CMS. Se construye desde el directorio `php/` y monta el volumen `asirown` en `/var/www/owncloud`. Está conectado a la red interna `red-capa-2` con la IP `192.168.23.7`.
    
- **mariadbasir**:
    
    Este servicio configura el contenedor MariaDB, usando la imagen oficial de MariaDB y un script de base de datos (`basedatos.sh`). Está conectado a dos redes: `red-capa-2` (para la comunicación con los servidores web) y `red-capa-3` (para la comunicación con la base de datos). Las IPs asignadas son `192.168.23.5` en la red interna y `192.168.24.2` en la red de base de datos. La contraseña de root de MariaDB se define en la variable de entorno `MARIADB_ROOT_PASSWORD`. La política de reinicio es `unless-stopped`.
    
- **Volúmenes**:
    
    Se ha creado un volumen llamado `asirown`, utilizado por todos los servicios (balanceador, servidores Nginx, PHP-FPM y MariaDB) para compartir los archivos del CMS OwnCloud. El volumen utiliza el driver `local` para mantener los datos persistentes y compartirlos entre los contenedores.
    
- **Redes**:
    
    El archivo define tres redes:
    
    - **red-capa-1**: Red pública para el balanceador de carga (subnet: `192.168.22.0/24`).
    - **red-capa-2**: Red interna para la comunicación entre servidores web, PHP-FPM y MariaDB (subnet: `192.168.23.0/24`).
    - **red-capa-3**: Red interna exclusiva para la base de datos MariaDB (subnet: `192.168.24.0/24`).

### Código-Compose

```docker
services:
  # Balanceador de carga
  balanceadorasir:
    build: 
      context: balanceador/   # Directorio donde se encuentra el Dockerfile para construir la imagen
      dockerfile: Dockerfile  # Nombre del archivo Dockerfile
    container_name: balanceador_asir  # Nombre del contenedor
    networks:
      red-capa-1:
        ipv4_address: 192.168.22.2  # Dirección IP estática en la red-capa-1
      red-capa-2:
        ipv4_address: 192.168.23.2  # Dirección IP estática en la red-capa-2
    ports:
      - "80:80"    # Mapea el puerto 80 del contenedor al puerto 80 del host
      - "443:443"  # Mapea el puerto 443 del contenedor al puerto 443 del host
    restart: unless-stopped  # Reinicia el contenedor a menos que se detenga manualmente

  # Servidor Nginx 1
  nginx1asir:
    build:
      context: nginx1/          # Directorio donde se encuentra el Dockerfile para la imagen de Nginx 1
      dockerfile: Dockerfile    # Nombre del archivo Dockerfile
    container_name: nginx1_asir  # Nombre del contenedor
    volumes:
      - asirown:/var/www/owncloud  # Monta el volumen asirown en el contenedor para persistir datos de OwnCloud
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.3  # Dirección IP estática en la red-capa-2
    ports:
      - "81:80"  # Mapea el puerto 80 del contenedor al puerto 81 del host
    restart: unless-stopped  # Reinicia el contenedor a menos que se detenga manualmente
    depends_on:
      - balanceadorasir  # Este contenedor depende del contenedor balanceadora, se inicia después de él

  # Servidor Nginx 2
  nginx2asir:
    build:
      context: nginx2/        # Directorio donde se encuentra el Dockerfile para la imagen de Nginx 2
      dockerfile: Dockerfile  # Nombre del archivo Dockerfile
    container_name: nginx2_asir  # Nombre del contenedor
    volumes:
      - asirown:/var/www/owncloud  # Monta el volumen asirown en el contenedor para persistir datos de OwnCloud
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.4  # Dirección IP estática en la red-capa-2
    ports:
      - "82:80"  # Mapea el puerto 80 del contenedor al puerto 82 del host
    restart: unless-stopped  # Reinicia el contenedor a menos que se detenga manualmente
    depends_on:
      - balanceadorasir  # Este contenedor depende del contenedor balanceadora, se inicia después de él

  # Servidor PHP (PHP-FPM)
  phpasir:
    build:
      context: php/          # Directorio donde se encuentra el Dockerfile para la imagen de PHP
      dockerfile: Dockerfile  # Nombre del archivo Dockerfile
    container_name: php7.4-fpm_asir  # Nombre del contenedor
    volumes:
      - asirown:/var/www/owncloud  # Monta el volumen asirown en el contenedor para persistir datos de OwnCloud
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.7  # Dirección IP estática en la red-capa-2

  # Base de datos MariaDB
  mariadbasir:
    container_name: mariadb_asir  # Nombre del contenedor
    image: mariadb  # Utiliza la imagen oficial de MariaDB
    environment:
      MARIADB_ROOT_PASSWORD: nuevacontraseña1234  # Contraseña para el usuario root de MariaDB
    volumes:
      - ./database/basedatos.sh:/docker-entrypoint-initdb.d/base.sh  # Script de inicialización de la base de datos
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.5  # Dirección IP estática en la red-capa-2
      red-capa-3:
        ipv4_address: 192.168.24.2  # Dirección IP estática en la red-capa-3
    restart: unless-stopped  # Reinicia el contenedor a menos que se detenga manualmente

# Definición de volúmenes
volumes:
  asirown: 
    driver: local  # Usa el driver local para persistir datos en el volumen asirown

# Definición de redes
networks:
  red-capa-1:
    driver: bridge  # Utiliza el driver 'bridge' para la red
    ipam:
      config:
        - subnet: 192.168.22.0/24  # Rango de direcciones IP para la red-capa-1
  red-capa-2:
    driver: bridge  # Utiliza el driver 'bridge' para la red
    ipam:
      config:
        - subnet: 192.168.23.0/24  # Rango de direcciones IP para la red-capa-2
  red-capa-3:
    driver: bridge  # Utiliza el driver 'bridge' para la red
    ipam:
      config:
        - subnet: 192.168.24.0/24  # Rango de direcciones IP para la red-capa-3

```

## Balanceador de carga-Capa1

En esta capa he configurado el balanceador de carga Nginx utilizando un **Dockerfile** y un archivo de configuración personalizado (`nginx.conf`). A continuación, explico cómo he configurado cada uno de estos archivos:

- **Dockerfile**:
    
    El `Dockerfile` utiliza **Ubuntu 20.04** como base para construir el contenedor. Primero actualiza el sistema e instala **Nginx**. Luego, elimina el archivo de configuración predeterminado de Nginx para poder usar el archivo personalizado. También instalo **OpenSSL** para configurar el servidor con SSL. Finalmente, copio el archivo `nginx.conf` al contenedor y expongo los puertos 80 y 443 para permitir conexiones HTTP y HTTPS.
    
- **nginx.conf**:
    
    El archivo `nginx.conf` está configurado para que Nginx funcione como balanceador de carga. He creado un bloque `upstream owncloud_backend` donde especifico las direcciones IP de los dos servidores OwnCloud (192.168.23.3 y 192.168.23.4), de forma que el tráfico se distribuye entre ellos.
    
    Además, he configurado Nginx para que escuche en el puerto 443 con SSL, utilizando certificados autofirmados generados con `openssl`.
    
    En el bloque `location /`, el tráfico se redirige a los servidores de backend utilizando `proxy_pass`. También configuro varios encabezados para que la información del cliente se preserve correctamente durante la redirección y se mantenga la seguridad.
    
    Finalmente, defino tiempos de espera para evitar que se interrumpan las conexiones largas y añado cabeceras para evitar problemas de caché.
    

### Código-Dockerfile

```docker
# Usar Ubuntu como imagen base
FROM ubuntu:20.04

# Actualizar el sistema e instalar Nginx y OpenSSL
RUN apt-get update && apt-get install -y nginx-full && apt-get clean && rm -rf /etc/nginx/nginx.conf && apt install -y openssl

# Configurar Nginx como balanceador de carga
# Crear un archivo de configuración para el balanceador

# Establecer una variable de entorno para el dominio
ENV DOMAIN=jesusnube.com

# Crear un certificado SSL autofirmado usando OpenSSL para el dominio especificado
RUN sh -c "openssl req -x509 -nodes -days 365 \
-subj '/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN' \
-newkey rsa:2048 -keyout '/etc/ssl/certs/jesusnube.com.key' -out '/etc/ssl/certs/jesusnube.com.crt'"

# Copiar el archivo de configuración de Nginx al contenedor
COPY nginx.conf /etc/nginx/nginx.conf

# Exponer el puerto 80 y 443 para permitir que Nginx acepte conexiones HTTP y HTTPS
EXPOSE 80
EXPOSE 443

# Iniciar Nginx en primer plano (evita que el contenedor se detenga)
CMD ["nginx", "-g", "daemon off;"]

```

### Código-nginx.conf

```docker
# Definir el número de procesos de trabajo para Nginx
worker_processes auto;  # Nginx ajusta automáticamente el número de procesos de trabajo según el número de núcleos del sistema

events {
    worker_connections 1024;  # Número máximo de conexiones simultáneas por proceso de trabajo
}

http {
    # Configuración de balanceo de carga para el backend de OwnCloud
    upstream owncloud_backend {
       #ip_hash;  # Se podría usar 'ip_hash' para balanceo de carga basado en la IP del cliente, pero está descomentado
        server 192.168.23.3;  # Servidor OwnCloud 1
        server 192.168.23.4;  # Servidor OwnCloud 2
    }

    server {
        listen 443 ssl http2;  # Escuchar en el puerto 443 para HTTPS con soporte HTTP/2
        server_name jesusnube.com;  # Nombre de dominio para este servidor

        # Configuración de SSL para habilitar HTTPS
        ssl_certificate /etc/ssl/certs/jesusnube.com.crt;  # Ruta al certificado SSL
        ssl_certificate_key /etc/ssl/certs/jesusnube.com.key;  # Ruta a la clave privada del certificado
        ssl_protocols TLSv1.2 TLSv1.3;  # Habilitar los protocolos SSL/TLS seguros
        ssl_ciphers HIGH:!aNULL:!MD5;  # Configuración de cifrados seguros, deshabilitar NULL y MD5
        ssl_prefer_server_ciphers on;  # Preferir los cifrados del servidor en lugar de los del cliente

        # Configuración de la redirección del tráfico al backend de OwnCloud
        location / {
            proxy_pass http://owncloud_backend;  # Redirige el tráfico al grupo de servidores OwnCloud configurado arriba
            proxy_set_header Host $host;  # Establece el encabezado 'Host' para el backend (nombre del host original)
            proxy_set_header X-Forwarded-Host $host;  # Establece el encabezado 'X-Forwarded-Host' para el backend
            proxy_set_header X-Real-IP $remote_addr;  # Pasa la IP real del cliente al backend
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;  # Encabezado con la cadena de IPs del cliente
            proxy_set_header X-Forwarded-Proto https;  # Indica que la solicitud original usó HTTPS
            proxy_http_version 1.1;  # Usa HTTP/1.1 para la comunicación entre el balanceador y el backend
            proxy_request_buffering off;  # Desactiva el almacenamiento en búfer de las solicitudes para mejorar el rendimiento

            # Configuración de tiempos de espera para la comunicación con el backend
            proxy_connect_timeout 300;  # Tiempo de espera para la conexión con el backend (en segundos)
            proxy_read_timeout 300;     # Tiempo de espera para leer la respuesta del backend (en segundos)
            proxy_send_timeout 300;     # Tiempo de espera para enviar la solicitud al backend (en segundos)

            # Configuración para evitar problemas de caché en las respuestas
            add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0" always;
            add_header Pragma "no-cache" always;  # Encabezado adicional para evitar la caché
        }
    }
}

```

## Servidores Nginx-Capa2

En esta capa, he configurado los servidores web Nginx para servir el CMS OwnCloud. Para ello, he utilizado un **Dockerfile**, un archivo de configuración de Nginx (`nginx-owncloud.conf`) y un archivo de configuración de Supervisor (`supervisord.conf`). A continuación, explico cómo he configurado cada uno de estos archivos:

- **Dockerfile**:
    
    El `Dockerfile` crea un contenedor basado en **Ubuntu 20.04** e instala los siguientes paquetes esenciales:
    
    - **sed**, **supervisor**, **nginx-full**, **curl**, **unzip**, **mariadb-client**, **netcat**: Herramientas necesarias para la configuración del sistema, el servidor web y la conexión a la base de datos.
    - **OpenSSL**: Para habilitar la configuración SSL en los servidores web si es necesario.
    
    Después de instalar los paquetes, el `Dockerfile` descarga y descomprime la última versión estable de **OwnCloud** desde su sitio oficial, asegurándose de que todos los archivos sean propiedad de `www-data`, el usuario adecuado para ejecutar el servidor web.
    
    Se copian dos archivos de configuración importantes:
    
    - **nginx-owncloud.conf**: Configura el servidor Nginx para servir OwnCloud.
    - **supervisord.conf**: Configura **Supervisor** para gestionar el proceso de Nginx y PHP-FPM.
    
    Finalmente, se expone el puerto 80 para permitir el acceso a través de HTTP y se configura el contenedor para que inicie **Supervisor**, que a su vez gestionará Nginx y PHP-FPM.
    
- **nginx-owncloud.conf**:
    
    Este archivo es la configuración de Nginx para servir el CMS OwnCloud. Los puntos clave de la configuración son:
    
    - El servidor escucha en el puerto 80 y la raíz del servidor se establece en `/var/www/owncloud`, donde se ha instalado OwnCloud.
    - Se configuran varias ubicaciones:
        - La ubicación raíz (`/`) se redirige a `index.php` para manejar las solicitudes de la aplicación.
        - Se bloquean las solicitudes a directorios o archivos sensibles como `build`, `tests`, `config`, entre otros, devolviendo un error 404.
        - Se configuran las ubicaciones PHP (como `index.php`, `remote.php`, `cron.php`, etc.) para que se gestionen a través de **PHP-FPM**, apuntando al contenedor PHP-FPM en `192.168.23.7:9000`.
        - Se añaden configuraciones de optimización, como la desactivación del almacenamiento en caché para archivos estáticos (CSS, JS, imágenes) y la interceptación de errores para mejorar la fiabilidad del servidor.
- **supervisord.conf**:
    
    El archivo `supervisord.conf` configura **Supervisor**, que es el encargado de ejecutar y gestionar los procesos dentro del contenedor:
    
    - El **programa Nginx** se configura para que se ejecute en primer plano con el comando `/usr/sbin/nginx -g "daemon off;"`, lo que permite que Nginx se inicie y se mantenga en ejecución.
    - El **programa PHP-FPM** se configura para que se ejecute con el comando `/usr/sbin/php-fpm7.4 -F`, asegurando que el motor PHP-FPM esté siempre activo para procesar las solicitudes PHP.
    - Ambos programas están configurados para **arrancar automáticamente** y reiniciarse en caso de fallos.

### Código-Dockerfile

```docker
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

```

### Código-nginx-owncloud.conf

```docker
server {
    # Escuchar en el puerto 80 para conexiones HTTP
    listen 80;
    listen [::]:80;  # Escuchar también en IPv6

    # Establecer la raíz del servidor y los archivos índice
    root /var/www/owncloud;
    index index.php index.html index.htm;

    # Configuración para la ubicación raíz
    location / {
        rewrite ^ /index.php$uri;  # Redirigir todas las solicitudes a index.php
        proxy_set_header Host $host;  # Establecer el encabezado Host con el valor del host solicitado
        proxy_set_header X-Real-IP $remote_addr;  # Pasar la IP real del cliente al backend
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;  # Encabezado de IPs de clientes previos
        proxy_set_header X-Forwarded-Proto $scheme;  # Indicar si la solicitud original fue HTTP o HTTPS
    }

    # Bloquear el acceso a directorios sensibles o innecesarios
    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
        return 404;  # Devuelve un error 404 si se intenta acceder a estos directorios
    }

    # Bloquear el acceso a archivos internos y scripts de administración
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
        return 404;  # Devuelve un error 404 si se intenta acceder a estos archivos o directorios
    }

    # Configuración para manejar las solicitudes PHP específicas de OwnCloud
    location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\.php(?:$|/) {
         include snippets/fastcgi-php.conf;  # Incluir configuración de FastCGI para PHP
         fastcgi_pass 192.168.23.7:9000;  # Pasar la solicitud al servidor PHP-FPM en la IP y puerto indicados
         fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;  # Definir la ruta completa del script PHP
         include fastcgi_params;  # Incluir parámetros de FastCGI adicionales
         fastcgi_intercept_errors on;  # Interceptar errores de FastCGI para manejar los 404 y otros
         fastcgi_request_buffering off;  # Desactivar el almacenamiento en búfer de solicitudes
    }

    # Configuración para las rutas de actualización de OwnCloud
    location ~ ^/(?:updater|ocs-provider)(?:$|/) {
        try_files $uri $uri/ =404;  # Intentar acceder al archivo o directorio, devolver 404 si no existe
        index index.php;  # Usar index.php como archivo índice en esta ruta
    }

    # Configuración para archivos estáticos (CSS, JS)
    location ~* \.(?:css|js)$ {
        try_files $uri /index.php$uri$is_args$args;  # Si el archivo no existe, redirigir a index.php
        access_log off;  # Desactivar el registro de acceso para estos archivos
    }

    # Configuración para otros archivos estáticos (imágenes, fuentes, etc.)
    location ~* \.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$ {
        try_files $uri /index.php$uri$is_args$args;  # Si el archivo no existe, redirigir a index.php
        access_log off;  # Desactivar el registro de acceso para estos archivos
    }
}

```

### Código-supervisord.conf

```docker
[supervisord]
nodaemon=true  # Ejecutar supervisord en primer plano (no en modo demonio)

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"  # Comando para iniciar Nginx en primer plano (para que el contenedor no termine)
autostart=true  # Iniciar Nginx automáticamente cuando se inicie Supervisor
autorestart=true  # Reiniciar Nginx automáticamente si se detiene inesperadamente
priority=1  # Prioridad de inicio, 1 es la más alta
stdout_logfile=/var/log/supervisor/nginx.log  # Archivo donde se guardan los registros estándar de Nginx
stderr_logfile=/var/log/supervisor/nginx_err.log  # Archivo donde se guardan los registros de error de Nginx

[program:php-fpm]
command=/usr/sbin/php-fpm7.4 -F  # Comando para iniciar PHP-FPM 7.4 en primer plano
autostart=true  # Iniciar PHP-FPM automáticamente cuando se inicie Supervisor
autorestart=true  # Reiniciar PHP-FPM automáticamente si se detiene inesperadamente
priority=2  # Prioridad de inicio, PHP-FPM inicia después de Nginx
stdout_logfile=/var/log/supervisor/php-fpm.log  # Archivo donde se guardan los registros estándar de PHP-FPM
stderr_logfile=/var/log/supervisor/php-fpm_err.log  # Archivo donde se guardan los registros de error de PHP-FPM

```

## Php-Fpm-Capa2

En esta capa, he configurado el contenedor PHP-FPM necesario para ejecutar el CMS OwnCloud. Para ello, he utilizado un **Dockerfile** y un archivo de entrada personalizado (`entrypoint.sh`). A continuación, explico cómo está configurado cada uno de estos archivos:

- **Dockerfile**:
    
    El `Dockerfile` está basado en la imagen oficial **php:7.4-fpm**, y realiza las siguientes acciones:
    
    - **Instalación de dependencias**: Se instalan las bibliotecas necesarias para que OwnCloud funcione correctamente, como **libicu-dev**, **libpng-dev**, **libjpeg-dev**, **libcurl4-openssl-dev**, entre otras. También se instalan las extensiones de PHP necesarias, como `pdo_mysql`, `opcache`, `mbstring`, `xml`, `gd`, entre otras.
    - **Instalación de Composer**: Se descarga e instala **Composer**, que es una herramienta de gestión de dependencias de PHP, para poder gestionar las librerías de OwnCloud si es necesario.
    - **Configuración de Opcache**: Se configura **Opcache** para mejorar el rendimiento de PHP, ajustando parámetros como la memoria de Opcache y la frecuencia de validación de archivos.
    - **Exposición de puerto**: Se expone el puerto 9000 para permitir que el contenedor PHP-FPM se comunique con Nginx, que redirige las solicitudes PHP al contenedor PHP-FPM.
    - **Archivo de entrada**: Se copia el script `entrypoint.sh` al contenedor y se le otorgan permisos de ejecución.
- **entrypoint.sh**:
    
    El archivo `entrypoint.sh` es un script que se ejecuta al iniciar el contenedor. Este script realiza las siguientes acciones:
    
    - **Esperar la base de datos**: La función `wait_for_db` espera a que la base de datos MariaDB esté disponible antes de continuar con la instalación de OwnCloud. El script intenta conectarse a la base de datos en la dirección `192.168.23.5` (la IP del contenedor MariaDB) y verifica si está lista para recibir conexiones.
    - **Instalación de OwnCloud**: Una vez la base de datos esté disponible, el script instala las variables de **OwnCloud** usando el comando `occ maintenance:install`, configurando la base de datos y el usuario administrador.
    - **Agregar dominios confiables**: Después de la instalación, el script agrega dominios confiables a la configuración de OwnCloud para permitir el acceso desde diferentes IPs y nombres de dominio.

### Código-Dockerfile

```docker
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
```

### Código-Entrypoint.sh

```bash
#!/bin/bash

# Definir parámetros de conexión a la base de datos
DB_HOST="192.168.23.5"
DB_PORT=3306
WAIT_TIMEOUT=30

# Iniciar PHP-FPM en segundo plano
php-fpm &

# Función para esperar que la base de datos esté disponible
wait_for_db() {
  echo "Esperando a que la base de datos en $DB_HOST:$DB_PORT esté disponible..."
  for ((i=1; i<=WAIT_TIMEOUT; i++)); do
    # Intentar conectar con la base de datos utilizando PDO
    if php -r "try { new PDO('mysql:host=$DB_HOST;port=$DB_PORT;', 'ownclouduser', 'pass190863'); exit(0); } catch (Exception \$e) { exit(1); }"; then
      echo "La base de datos está disponible."
      return 0
    fi
    # Si no se puede conectar, esperar 2 segundos antes de reintentar
    echo "Intento $i/$WAIT_TIMEOUT: La base de datos no está lista, esperando..."
    sleep 2
  done
  echo "Error: La base de datos no está disponible después de $WAIT_TIMEOUT segundos."
  exit 1
}

# Función para instalar OwnCloud
install_owncloud() {
  echo "Iniciando instalación de OwnCloud..."
  su -s /bin/bash www-data -c "php /var/www/owncloud/occ maintenance:install \
    --database 'mysql' \
    --database-name 'owncloud_db' \
    --database-user 'ownclouduser' \
    --database-pass 'pass190863' \
    --database-host '$DB_HOST' \
    --admin-user 'admin' \
    --admin-pass 'admin'"
  echo "Instalación de OwnCloud completada."
}

# Función para agregar dominios confiables en OwnCloud
add_trusted_domains() {
  echo "Agregando dominios confiables..."
  su -s /bin/bash www-data -c "php /var/www/owncloud/occ config:system:set trusted_domains 0 --value='jesusnube.com'"
  su -s /bin/bash www-data -c "php /var/www/owncloud/occ config:system:set trusted_domains 1 --value='192.168.23.2'"
  su -s /bin/bash www-data -c "php /var/www/owncloud/occ config:system:set trusted_domains 2 --value='192.168.23.3'"
  su -s /bin/bash www-data -c "php /var/www/owncloud/occ config:system:set trusted_domains 3 --value='192.168.23.4'"
  echo "Dominios confiables agregados correctamente."
}

# Ejecutar las funciones en orden
wait_for_db
install_owncloud
add_trusted_domains

# Esperar indefinidamente para que el contenedor siga ejecutándose
wait

```

## Mariadb-Capa3

En esta capa, se configura la base de datos para **OwnCloud**. He creado un script que automatiza la creación de la base de datos, la creación de un usuario con privilegios específicos y la asignación de los permisos necesarios para que **OwnCloud** pueda acceder y modificar la base de datos. A continuación, explico cómo se realiza cada paso:

### **Configuración de la base de datos**:

1. **Definición de variables**:
Se definen varias variables clave, como el nombre de usuario y la contraseña de la base de datos para **OwnCloud**, la IP de la red que tiene acceso a la base de datos, y la contraseña del usuario **root** de **MariaDB**.
2. **Creación de la base de datos**:
Se crea la base de datos **`owncloud_db`** en **MariaDB** utilizando el usuario **root**. Después, se ejecuta un comando para asegurarse de que todos los privilegios se recarguen correctamente.
3. **Creación de un usuario para OwnCloud**:
Se crea un nuevo usuario de base de datos, **`ownclouduser`**, y se le asigna una contraseña. Este usuario tiene permisos para acceder a la base de datos **`owncloud_db`** desde cualquier máquina dentro de la red especificada, en este caso, **`192.168.23.%`**.
4. **Concesión de privilegios**:
Finalmente, se le otorgan al usuario **`ownclouduser`** todos los privilegios necesarios para acceder y modificar la base de datos **`owncloud_db`**.

### Código-basededatos.sh

```bash
# Definición de variables para el acceso a la base de datos
DB_USER=ownclouduser  # Nombre del usuario de la base de datos para OwnCloud
DB_PASS=pass190863     # Contraseña para el usuario de la base de datos
IP_MAS=192.168.23.%    # IP de la red a la que se le concede acceso al usuario (en este caso, toda la red 192.168.23)
db_passwd=nuevacontraseña1234  # Contraseña del usuario root de MariaDB (se usa para autenticarse)

# Crear la base de datos OwnCloud
mariadb -u root -p$db_passwd -e "CREATE DATABASE owncloud_db;FLUSH PRIVILEGES;"

# Crear un nuevo usuario para OwnCloud y permitir el acceso desde la red especificada
mariadb -u root -p$db_passwd -e "CREATE USER '$DB_USER'@'$IP_MAS' IDENTIFIED BY '$DB_PASS';"

# Conceder privilegios al usuario para acceder y modificar la base de datos OwnCloud
mariadb -u root -p$db_passwd -e "GRANT ALL PRIVILEGES ON owncloud_db.* TO '$DB_USER'@'$IP_MAS';FLUSH PRIVILEGES;"

```

### Redes en Docker

Definí tres redes internas:

- **red-capa-1**: Conectada al balanceador de carga y la red pública.
- **red-capa-2**: Para la comunicación entre los servidores web y PHP-FPM.
- **red-capa-3**: Para la comunicación con la base de datos MariaDB.

# Desplegar infraestructura

- **Clonar el repositorio** donde se encuentran los archivos de configuración (`docker-compose.yml`, Dockerfiles, etc.).
- **Construir y desplegar los contenedores** ejecutando el siguiente comando desde el directorio donde se encuentra el archivo `docker-compose.yml`:
    
    ```bash
    docker compose -d --build
    ```
    
- Este comando:
    - Construye las imágenes necesarias para los contenedores (si no están construidas previamente).
    - Inicia los contenedores en segundo plano (`d` para modo "detached").
- **Verificar el estado de los contenedores**:
    
    Puedo comprobar que todos los contenedores están en ejecución con el siguiente comando:
    
    ```bash
    docker-compose ps
    ```
    
    Este comando muestra el estado de todos los contenedores definidos en el archivo `docker-compose.yml`.
    

# Entrega Opcional-MariaDBGalera

Un punto crítico en nuestra infraestructura es la capa de datos, ya que, en caso de fallo de la base de datos, no contamos con una réplica de los datos.

### **Configuración del Clúster MariaDB**

El clúster de **MariaDB Galera** se compone de dos nodos que replican los datos entre sí en tiempo real. He configurado ambos nodos de la siguiente forma:

- **Configuración de los nodos**: Se configuró un nodo como nodo inicial del clúster y el segundo nodo se unió al clúster. Ambos nodos están configurados para replicar datos entre sí, lo que asegura que si uno de ellos falla, el otro sigue disponible.
- **Archivo `my.cnf` de cada nodo**: Este archivo define las configuraciones necesarias para que la replicación Galera funcione correctamente, como la dirección de los nodos en el clúster y el método de sincronización de estado (MariaBackup).

### **Problema encontrado**:

A pesar de la configuración de los nodos, no he conseguido que la replicación entre los nodos funcionara correctamente. No se lograba sincronizar los datos entre los servidores, lo que impidió que el clúster pudiera replicar de manera efectiva los datos entre los dos nodos de MariaDB.

### **Balanceo de la Base de Datos**

Para balancear las solicitudes entre los dos nodos de MariaDB, he implementado un **balanceador de carga** utilizando **HAProxy**. Esto permite que las solicitudes sean enviadas de forma automática a cualquiera de los nodos disponibles, mejorando la disponibilidad y escalabilidad de la base de datos.

### Código-Compose

```docker
services:
  balanceadorasir:
    build: 
      context: balanceador/
      dockerfile: Dockerfile
    container_name: balanceador_asir
    networks:
      red-capa-1:
        ipv4_address: 192.168.22.2
      red-capa-2:
        ipv4_address: 192.168.23.2
    ports:
      - "80:80"
      - "443:443"
    restart: unless-stopped

  nginx1asir:
    build:
      context: nginx1/          
      dockerfile: Dockerfile
    container_name: nginx1_asir
    volumes:
      - asirown:/var/www/owncloud
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.3
    ports:
      - "81:80" 
    restart: unless-stopped
    depends_on:
      - balanceadorasir

  nginx2asir:
    build:
      context: nginx2/        
      dockerfile: Dockerfile
    container_name: nginx2_asir
    volumes:
      - asirown:/var/www/owncloud
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.4
    ports:
      - "82:80" 
    restart: unless-stopped
    depends_on:
      - balanceadorasir

  phpasir:
    build:
      context: php/          
      dockerfile: Dockerfile
    container_name: php7.4-fpm_asir
    volumes:
      - asirown:/var/www/owncloud
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.7

  galera-node1:
    image: bitnami/mariadb-galera:latest
    container_name: galera_node2
    environment:
      MARIADB_ROOT_PASSWORD: root_password
      MARIADB_DATABASE: owncloud_db
      MARIADB_USER: user_owncloud
      MARIADB_PASSWORD: GHHJHSGDY
      MARIADB_GALERA_CLUSTER_NAME: "galera_cluster"
      MARIADB_GALERA_NODE_ADDRESS: "192.168.23.11"
      MARIADB_GALERA_CLUSTER_BOOTSTRAP: "yes"
      MARIADB_GALERA_MARIABACKUP_PASSWORD: mariabackup_password
    volumes:
      - galera_data_node2:/bitnami/mariadb
      - ./galera_node2/my.cnf:/opt/bitnami/mariadb/conf/my.cnf
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.11
    restart: unless-stopped

  galera-node2:
    image: bitnami/mariadb-galera:latest
    container_name: galera_node1
    environment:
      MARIADB_ROOT_PASSWORD: root_password
      MARIADB_DATABASE: owncloud_db
      MARIADB_USER: user_owncloud
      MARIADB_PASSWORD: GHHJHSGDY
      MARIADB_GALERA_CLUSTER_NAME: "galera_cluster"
      MARIADB_GALERA_NODE_ADDRESS: "192.168.23.10"
      MARIADB_GALERA_CLUSTER_JOIN: "192.168.23.11"
      MARIADB_GALERA_MARIABACKUP_PASSWORD: mariabackup_password
    volumes:
      - galera_data_node1:/bitnami/mariadb
      - ./galera_node1/my.cnf:/opt/bitnami/mariadb/conf/my.cnf
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.10
    restart: unless-stopped
  
  haproxy:
    image: haproxy:2.7
    container_name: haproxy_server
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    networks:
      red-capa-2:
        ipv4_address: 192.168.23.6
    depends_on:
      - galera-node1
      - galera-node2
    restart: unless-stopped

volumes:
  asirown: 
    driver: local
  galera_data_node1:
    driver: local
  galera_data_node2:
    driver: local

networks:
  red-capa-1:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.22.0/24
  red-capa-2:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.23.0/24
  red-capa-3:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.24.0/24
```

# Conclusión

En este proyecto, he desplegado una infraestructura basada en Docker para crear un entorno de alta disponibilidad con una pila LEMP (Linux, Nginx, MariaDB, PHP). El objetivo era mejorar la disponibilidad de los servicios, garantizando que la aplicación fuera capaz de resistir fallos en uno de sus componentes sin afectar a la operativa. A lo largo del proceso, se realizaron varias configuraciones y se implementaron herramientas clave para asegurar que los servicios trabajaran correctamente.
