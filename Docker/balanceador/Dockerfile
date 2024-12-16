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
