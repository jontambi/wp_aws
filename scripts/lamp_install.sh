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

## Installing PHP 7.3.3
sudo yum install -y epel-release
sudo yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum install -y yum-utils
sudo yum-config-manager --disable remi-php54
sudo yum-config-manager --enable remi-php73
sudo yum install php-mysql


## Update OS
sudo yum update -y

## Configure WP
wget -P /tmp/ http://wordpress.org/latest.tar.gz
tar -xzvf /tmp/latest.tar.gz -C /tmp
sudo mv /tmp/wordpress /var/www/html/store
sudo mkdir /var/www/html/store/uploads
sudo cp -p /var/www/html/store/wp-config-sample.php /var/www/html/store/wp-config.php
sudo chown -R apache:apache /var/www/html/*

