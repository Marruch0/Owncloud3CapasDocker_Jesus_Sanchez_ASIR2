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
