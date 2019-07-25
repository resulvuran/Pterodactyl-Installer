#!/bin/bash

update(){
	apt update -y && apt upgrade -y
}

install_dependency(){
	# Add "add-apt-repository" command
	apt -y install software-properties-common curl

	# Add additional repositories for PHP, Redis, and MariaDB
	LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
	add-apt-repository -y ppa:chris-lea/redis-server
	curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

	# Update repositories list
	apt update

	# Add universe repository if you are on Ubuntu 18.04
	apt-add-repository universe

	# Install Dependencies
	apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip mariadb-server nginx tar unzip git redis-server
}

install_composer(){
	curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
}

dl_files(){
	mkdir -p /var/www/pterodactyl
	cd /var/www/pterodactyl
	curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.14/panel.tar.gz
	tar --strip-components=1 -xzvf panel.tar.gz
	chmod -R 755 storage/* bootstrap/cache/
}

setup_mysql(){
	mysql_secure_installation

	mysql -u root -p -e "USE mysql;"
	mysql -u root -p -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'somePassword';"
	mysql -u root -p -e "CREATE DATABASE panel;"
	mysql -u root -p -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
	mysql -u root -p -e "FLUSH PRIVILEGES;"
}

installation(){
	cp .env.example .env
	composer install --no-dev --optimize-autoloader

	# Only run the command below if you are installing this Panel for
	# the first time and do not have any Pterodactyl Panel data in the database.
	php artisan key:generate --force
}

configure(){
	php artisan p:environment:setup
	php artisan p:environment:database
	php artisan p:environment:mail
}

database_setup(){
	php artisan migrate --seed
}

adduser() {
	php artisan p:user:make
}

setPermission(){
	chown -R www-data:www-data * 
}

crontab_setup(){
	CRON="* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"
	crontab -l | { cat; echo "${CRON}"; } | crontab -
}

create_pteroq(){
	cd /etc/systemd/system;
	wget 
}