#!/bin/sh
#
# Wordpress Setup Script
#
# This script will install and configure WordPress on
# an Ubuntu 16.04 droplet
export DEBIAN_FRONTEND=noninteractive;

# Generate root and WordPress mysql passwords
rootmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;
wpmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;

# Write passwords to file
echo "Root MySQL Password: $rootmysqlpass" > /root/passwords.txt;
echo "Wordpress MySQL Password: $wpmysqlpass" >> /root/passwords.txt;


# Update Ubuntu
apt-get update;
apt-get -y upgrade;

# Install Apache/MySQL
apt-get -y install apache2 php php-mysql libapache2-mod-php7.2 php7.2-mysql php7.2-curl php7.2-zip php7.2-json php7.2-xml mysql-server mysql-client unzip wget;

# Download and uncompress WordPress
wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip;
cd /tmp/;
unzip /tmp/wordpress.zip;
# Set up database user
/usr/bin/mysqladmin -u root -h localhost create wordpress;
/usr/bin/mysqladmin -u root -h localhost password $rootmysqlpass;
/usr/bin/mysql -uroot -p$rootmysqlpass -e "CREATE USER wordpress@localhost IDENTIFIED BY '"$wpmysqlpass"'";
/usr/bin/mysql -uroot -p$rootmysqlpass -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost";

# Configure WordPress
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php;
sed -i "s/'DB_NAME', 'database_name_here'/'DB_NAME', 'wordpress'/g" /tmp/wordpress/wp-config.php;
sed -i "s/'DB_USER', 'username_here'/'DB_USER', 'wordpress'/g" /tmp/wordpress/wp-config.php;
sed -i "s/'DB_PASSWORD', 'password_here'/'DB_PASSWORD', '$wpmysqlpass'/g" /tmp/wordpress/wp-config.php;

for i in `seq 1 8`
do
wp_salt=$(</dev/urandom tr -dc 'a-zA-Z0-9!@#$%^&*()\-_ []{}<>~`+=,.;:/?|' | head -c 64 | sed -e 's/[\/&]/\\&/g');
sed -i "0,/put your unique phrase here/s/put your unique phrase here/$wp_salt/" /tmp/wordpress/wp-config.php;
done

cp -Rf /tmp/wordpress/* /var/www/html/.;
rm -f /var/www/html/index.html;
chown -Rf www-data:www-data /var/www/html;
a2enmod rewrite;

# increase php limits
sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' /etc/php/7.2/apache2/php.ini
sed -i 's/^post_max_size.*/post_max_size = 64M/' /etc/php/7.2/apache2/php.ini
sed -i 's/^memory_limit.*/memory_limit = 128M/' /etc/php/7.2/apache2/php.ini
sed -i 's/^max_execution_time.*/max_execution_time = 300/' /etc/php/7.2/apache2/php.ini

service apache2 restart;

# upload default WordPress theme
wget https://github.com/lamazingco/onehour-resources/raw/master/theme.zip -O /tmp/theme.zip;
cd /tmp/;
unzip /tmp/theme.zip;
cp -Rf /tmp/foton /var/www/html/wp-content/themes/;

# install wp cli to control wordpress from command line
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
cd /tmp/;
chmod +x wp-cli.phar;
mv wp-cli.phar /usr/local/bin/wp;


# activate foton theme by default
cd /var/www/html/;
wp theme activate foton;
sudo -u www-data wp theme activate foton;

# install & activate plugins required for foton
sudo -u www-data wp plugin install wp-content/themes/foton/includes/plugins/foton-core.zip --activate
sudo -u www-data wp plugin install wp-content/themes/foton/includes/plugins/foton-instagram-feed.zip --activate
sudo -u www-data wp plugin install wp-content/themes/foton/includes/plugins/foton-twitter-feed.zip --activate
sudo -u www-data wp plugin install wp-content/themes/foton/includes/plugins/revslider.zip --activate
sudo -u www-data wp plugin install wp-content/themes/foton/includes/plugins/js_composer.zip --activate
sudo -u www-data wp plugin install contact-form-7 --activate

