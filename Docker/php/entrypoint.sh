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
