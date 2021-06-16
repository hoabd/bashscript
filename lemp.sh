#!/bin/bash
pwd=`dirname $0`

read -e -p "Target directory: " -i "/var/www/html" dir
dir=${dir:-"/var/www/html"}

if [ ! -d "$dir" ]; then
	sudo mkdir -p $dir
fi

sudo apt-get install -y \
	mysql-server \
	nginx \
	php5-curl \
	php5-fpm \
	php5-gd \
	php5-mysql \
	wget \
	unzip

sudo replace "2M" "10M" -- /etc/php5/fpm/php.ini
sudo service php5-fpm restart

sudo chown -R www-data:www-data $dir
sudo chmod -R 775 $dir

u=$SUDO_USER
if [ -z $u ]; then
	u=$USER
fi

if !(groups $u | grep >/dev/null www-data); then
	sudo adduser $u www-data
fi

cd - >/dev/null

sites="/etc/nginx/sites-enabled"

if [ -e "$sites/default" ]; then
	read -r -n 1 -p "Delete 'default' nginx site? (y/n)"
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		sudo rm "$sites/default"
	fi
	echo ""
fi

# Create virtual host file.
cat > /etc/nginx/sites-available/example.com << EOF
server {
        listen 80;
        root /var/www/html;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name example.com;

        location / {
                try_files $uri $uri/ =404;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}
EOF

sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/


cat /var/www/html/index.html << EOF
<html>
    <head>
        <title>Welcome to your_domain!</title>
    </head>
    <body>
        <h1>Success!  The your_domain server block is working!</h1>
    </body>
</html>
EOF


cat /var/www/html/info.php << EOF
<?php
phpinfo();
EOF


if nginx -s reload | grep -q 'OK'; then
   echo "NGINX was configured successfully"
fi


sudo service nginx restart

echo ""
echo "Install complete!"
echo "Please restart your session."
echo ""