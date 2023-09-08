#!/bin/bash
#Instala librerias recomendadas para wordpress
yum install php-zip php-intl -y

# Verifica si el usuario es root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ser ejecutado como root o con privilegios de superusuario."
    exit 1
fi

# Especifica la ruta que deseas explorar
ruta="/var/www/"

# Verifica si la ruta existe
if [ ! -d "$ruta" ]; then
    echo "La ruta '$ruta' no existe."
    exit 1
fi

# Lista todas las carpetas en la ruta
carpetas=("$ruta"*/)

# Verifica si se encontraron carpetas
if [ ${#carpetas[@]} -eq 0 ]; then
    echo "No se encontraron carpetas en la ruta '$ruta'."
    exit 1
fi

# Muestra las carpetas disponibles al usuario
echo "Carpetas disponibles en la ruta '$ruta':"
for i in "${!carpetas[@]}"; do
    echo "$(($i+1)). ${carpetas[$i]}"
done

# Pide al usuario que seleccione una carpeta
read -p "Ingresa el número correspondiente a la carpeta donde deseas instalar WordPress: " seleccion

# Verifica la elección del usuario
if ((seleccion < 1 || seleccion > ${#carpetas[@]})); then
    echo "Opción no válida. Saliendo."
    exit 1
fi

# Directorio webroot seleccionado por el usuario
webroot="${carpetas[$(($seleccion-1))]}"

# Pregunta al usuario por la información de la base de datos
read -p "Nombre de la base de datos para WordPress: " db_name
read -p "Nombre de usuario de la base de datos: " db_user
read -sp "Contraseña del usuario de la base de datos: " db_password
echo


# Crear la base de datos y el usuario en MySQL/MariaDB
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $db_name;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Verifica si se crearon con éxito la base de datos y el usuario
if [ $? -eq 0 ]; then
    echo "Base de datos '$db_name' y usuario '$db_user' creados con éxito."
else
    echo "Error al crear la base de datos y el usuario."
    exit 1
fi



# Descarga la última versión de WordPress
wget https://wordpress.org/latest.tar.gz -P /tmp
tar -xzvf /tmp/latest.tar.gz -C /tmp

# Mueve los archivos de WordPress al directorio webroot
sudo mv /tmp/wordpress/* $webroot

# Configura el archivo de configuración de WordPress
sudo cp $webroot/wp-config-sample.php $webroot/wp-config.php
sudo sed -i "s/database_name_here/$db_name/g" $webroot/wp-config.php
sudo sed -i "s/username_here/$db_user/g" $webroot/wp-config.php
sudo sed -i "s/password_here/$db_password/g" $webroot/wp-config.php

# Genera las "Authentication Unique Keys and Salts"
auth_keys=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Agrega las claves y sal a wp-config.php
sudo sed -i "/#@-/a $auth_keys" $webroot/wp-config.php


# Establece permisos en los archivos de WordPress
sudo chown -R apache:apache $webroot
sudo chmod -R 755 $webroot

# Reinicia Apache
sudo systemctl restart httpd

echo "WordPress se ha instalado y configurado correctamente en la carpeta $webroot."
