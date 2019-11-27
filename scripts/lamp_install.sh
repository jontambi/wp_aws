#!/bin/bash

## Install Apache
sudo yum install -y httpd

## Configuration firewall
#sudo firewall-cmd --permanent -add-service=http -add-service=https
#sudo firewall-cmd --reload
sudo systemctl start httpd
sudo systemctl enable httpd

## Install Database MariaDB
sudo yum -y install mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb

## Install PHP
sudo yum -y install centos-release-scl.noarch
sudo yum -y install rh-php72
sudo ln -s /opt/rh/rh-php72/root/usr/bin/php /usr/bin/php
sudo yum -y install rh-php72-php-mysqlnd
sudo systemctl restart httpd


## Update OS
sudo yum update -y

## Configure WP
wget -P /tmp/ http://wordpress.org/latest.tar.gz
tar -xzvf /tmp/latest.tar.gz -C /tmp
sudo mv /tmp/wordpress /var/www/html/
sudo mkdir /var/www/html/wordpress/uploads
sudo cp -p /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sudo chown -R apache:apache /var/www/html/*
