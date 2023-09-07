#!/bin/bash
# Descarga e instala WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz
sudo mv wordpress /var/www/html/
sudo chown -R apache:apache /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# Crea una copia del archivo de configuración de ejemplo de WordPress
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

# Genera las claves secretas para WordPress
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wordpress/wp-config.php

# Configura la base de datos de WordPress
sudo sed -i 's/database_name_here/wordpress/' /var/www/html/wordpress/wp-config.php
sudo sed -i 's/username_here/wordpressuser/' /var/www/html/wordpress/wp-config.php
sudo sed -i 's/password_here/password/' /var/www/html/wordpress/wp-config.php

# Habilita la modificación de archivos desde el panel de administración de WordPress
sudo mkdir /var/www/html/wordpress/wp-content/uploads
sudo chown -R :apache /var/www/html/wordpress/wp-content/uploads

# Reinicia Apache
sudo systemctl restart httpd

echo "El servidor LAMP con MariaDB, WordPress y HTTPS habilitado se ha instalado correctamente. Puedes acceder a tu sitio de WordPress en https://tu_dominio_o_dirección_ip/wordpress"
exit 0
