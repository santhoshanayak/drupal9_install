#!/bin/bash

# Constants
DRUPAL_REPO="https://github.com/drupal/recommended-project.git"
DRUPAL_DIR="drupal9"
DB_NAME="drupal9"
DB_USER="root"
DB_PASS="root"
DB_HOST="localhost"

# Function to check command execution status
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Update and install necessary packages
sudo apt-get update
check_status "Updating package lists failed."

sudo apt-get install -y apache2 mysql-server php php-mysql libapache2-mod-php php-xml php-mbstring php-curl php-gd php-json php-opcache php-pear php-zip unzip git
check_status "Installing packages failed."

# Start Apache and MySQL
sudo systemctl start apache2
check_status "Starting Apache failed."

sudo systemctl start mysql
check_status "Starting MySQL failed."

# Enable Apache mod_rewrite
sudo a2enmod rewrite
check_status "Enabling mod_rewrite failed."

sudo systemctl restart apache2
check_status "Restarting Apache failed."

# Clone Drupal repository
if [ ! -d "$DRUPAL_DIR" ]; then
    git clone $DRUPAL_REPO $DRUPAL_DIR
    check_status "Cloning Drupal repository failed."
else
    echo "Directory $DRUPAL_DIR already exists. Skipping clone."
fi

cd $DRUPAL_DIR

# Install Composer dependencies
composer install
check_status "Composer install failed."

# Set permissions
sudo chown -R www-data:www-data .
sudo chmod -R 755 .

# Create MySQL database and user
sudo mysql -u$DB_USER -p$DB_PASS -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
check_status "Creating database failed."

sudo mysql -u$DB_USER -p$DB_PASS -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASS';"
check_status "Granting privileges failed."

sudo mysql -u$DB_USER -p$DB_PASS -e "FLUSH PRIVILEGES;"
check_status "Flushing privileges failed."

# Configure Apache for Drupal
APACHE_CONF="/etc/apache2/sites-available/$DRUPAL_DIR.conf"
if [ ! -f "$APACHE_CONF" ]; then
    sudo bash -c "cat > $APACHE_CONF" <<EOL
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/$DRUPAL_DIR/web
    <Directory /var/www/html/$DRUPAL_DIR/web>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL
    check_status "Creating Apache configuration failed."

    sudo ln -s $APACHE_CONF /etc/apache2/sites-enabled/
    check_status "Linking Apache configuration failed."
else
    echo "Apache configuration for $DRUPAL_DIR already exists. Skipping configuration."
fi

sudo systemctl restart apache2
check_status "Restarting Apache failed."

echo "Drupal 9 installation completed successfully."
