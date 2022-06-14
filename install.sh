#!/bin/bash -x
serverip=`ip route get 8.8.8.8 | cut -d ' ' -f 7 | head -n 1`

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#get website name
read -p 'Enter website name as something.com or first.something.com(without www): ' websitename


#update repo
apt-get update

#install required packeges
apt-get install -y curl apt-transport-https ca-certificates lsb-release dirmngr pwgen vim rsync sudo snap

#vars
dbrootpass=`pwgen -s 24`
dbwebuser=`pwgen -s 12`
dbwebpass=`pwgen -s 24`
webdbname=`echo $websitename | cut -d '.' -f 1`
drupaluser=`pwgen -s 12`
drupalpass=`pwgen -s 24`


echo -e "mysql root password = $dbrootpass \nDrupal mysql db user = $dbwebuser \nDrupal mysql db password = $dbwebpass\nDrupal database name = $webdbname\nDrupal user =$drupaluser\nDrupal Password=$drupalpass" >> /root/info.txt;chmod 600 /root/info.txt 

#install php sury repo
curl -sSL https://packages.sury.org/php/README.txt | bash -x

#install LAMP stack
apt-get install -y apache2 libapache2-mod-php8.1 php8.1 php8.1-common php8.1-cli php8.1-gd php8.1-fpm php8.1-mysql php8.1-xml php8.1-mbstring php8.1-curl git unzip mariadb-server mariadb-client 

#configure MariaDB
mysql_secure_installation <<EOF
n
$dbrootpass
$dbrootpass
y
y
y
y
y
EOF

mysql -e "CREATE DATABASE $webdbname;"
mysql -e "CREATE USER '$dbwebuser'@'localhost' identified by '$dbwebpass';"
mysql -e "GRANT ALL PRIVILEGES ON $webdbname.* TO '$dbwebuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

#download composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

#configure apache2
echo -e "<VirtualHost $serverip:80>
   ServerName $websitename
   DocumentRoot /var/www/$websitename/web
   <Directory "/var/www/$websitename/web">
     Options +Includes -Indexes
        Allowoverride All
        Order allow,deny
        allow from all
        Require all granted
</Directory>
   ErrorLog /var/log/apache2/$websitename.error.log
   CustomLog /var/log/apache2/$websitename.access.log combined
</VirtualHost>" > /etc/apache2/sites-available/$websitename.conf


#make web directory
mkdir -p /var/www/$websitename

#download drush and drupal through composer
cd /var/www/$websitename && composer -n create-project drupal/recommended-project .
cd /var/www/$websitename && composer -n require drush/drush
cd /var/www/$websitename/web/sites/ && chown -R www-data default

#enable apache config
ln -s /etc/apache2/sites-available/$websitename.conf /etc/apache2/sites-enabled/$websitename.conf
systemctl restart apache2
#install drupal
cd /var/www/$websitename && composer -n require drupal/bootstrap && vendor/bin/drush theme:enable bootstrap
cd /var/www/$websitename && vendor/bin/drush config:set system.theme bootstrap <<EOF
yes
EOF
cd /var/www/$websitename && vendor/bin/drush si standard --db-url=mysql://$dbwebuser:$dbwebpass@localhost/$webdbname --account-name=$drupaluser --account-pass=$drupalpass  --site-name="$websitename" <<EOF
yes
EOF

