#!/bin/bash

CONFIG="https://raw.githubusercontent.com/SanjaySRocks/Pterodactyl-Installer/master/config"

greenMessage() {
	echo -e "\\033[32;1m${@}\033[0m"
}

update(){
	greenMessage "** Updating & Upgrading.."
	apt update -y && apt upgrade -y
}

install_dependency(){
	greenMessage "** Installing Required Dependencies for Panel.."

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
	greenMessage "** Installing Composer.."
	curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
}

dl_files(){
	greenMessage "** Downloading Some Files.."
	mkdir -p /var/www/pterodactyl
	cd /var/www/pterodactyl
	curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.14/panel.tar.gz
	tar --strip-components=1 -xzvf panel.tar.gz
	chmod -R 755 storage/* bootstrap/cache/
}

setup_mysql(){
	greenMessage "** Mysql Setup Starting.."

	mysql_secure_installation

	greenMessage "Please Enter Same MySQL Password if asked 5 times.."
	mysql -u root -p -e "USE mysql;"
	mysql -u root -p -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'somePassword';"
	mysql -u root -p -e "CREATE DATABASE panel;"
	mysql -u root -p -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
	mysql -u root -p -e "FLUSH PRIVILEGES;"
}

installation(){
	greenMessage "** Main Installation.."
	cp .env.example .env
	composer install --no-dev --optimize-autoloader

	# Only run the command below if you are installing this Panel for
	# the first time and do not have any Pterodactyl Panel data in the database.
	php artisan key:generate --force
}

configure(){
	greenMessage "** Configurations.."

	php artisan p:environment:setup

	php artisan p:environment:database

	php artisan p:environment:mail
}

database_setup(){
	greenMessage "** Setup Database.."
	php artisan migrate --seed
}

adduser() {
	greenMessage "** Adding User.."
	php artisan p:user:make
}

setPermission(){
	greenMessage "** File Permission Setup.."
	chown -R www-data:www-data * 
}

crontab_setup(){
	greenMessage "** Cronjob Setup.."
	CRON="* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"
	crontab -l | { cat; echo "${CRON}"; } | crontab -
}

create_pteroq(){
	greenMessage "** Pteroq Config File Downloading.."
	cd /etc/systemd/system;
	wget ${CONFIG}/pteroq.service

	#sudo systemctl enable --now redis-server
	sudo systemctl enable --now pteroq.service
}

web_ngnix(){
	greenMessage "** Ngnix Config Downloading & Setup"

	cd /etc/nginx/sites-available/
	wget ${CONFIG}/pterodactyl.conf

	echo -n "* Enter Panel IP or Hostname: "
  	read FQDN
  	
	sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf

	sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
	systemctl restart nginx
}

install_complete(){
	greenMessage "** Pterodactyl Panel Installed Successfull!"
}

update
install_dependency
install_composer
dl_files
setup_mysql
installation
configure
database_setup
adduser
setPermission
crontab_setup
create_pteroq
web_ngnix
install_complete