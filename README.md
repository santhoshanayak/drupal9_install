# Drupal 9 Install Script

This repository provides a bash script to automate the installation of Drupal 9 on an Ubuntu server. The script installs necessary packages, configures the server, and sets up Drupal 9.

## Prerequisites

Before running the script, ensure you have the following:

- An Ubuntu server
- Root or sudo access
- Git installed on your system

## Installation
1. Clone the repository to your server:
```
git clone https://github.com/santhoshanayak/drupal9_install.git
cd drupal9_install

```

2. Make the script executable:
```
chmod +x install.sh
```
3. Run the installation script:
```
sudo ./install.sh
```

## Usage
The script will:

1. Update package lists.
2. Install Apache, MySQL, PHP, and necessary PHP extensions.
3. Start Apache and MySQL services.
4. Enable Apache mod_rewrite.
5. Clone the Drupal 9 recommended project.
6. Install Composer dependencies.
7. Set the appropriate file permissions.
8. Create a MySQL database and user for Drupal.
9. Configure Apache to serve the Drupal site.


After running the script, you should be able to access your Drupal site via your server's IP address or domain name.

## Configuration

You can modify the script to suit your needs. Key configuration variables include:

- DRUPAL_REPO: URL of the Drupal repository to clone.
- DRUPAL_DIR: Directory to clone the Drupal repository into.
- DB_NAME: Name of the MySQL database.
- DB_USER: MySQL user name.
- DB_PASS: MySQL user password.
- DB_HOST: MySQL host.

info.txt created at same location with all credentials 
