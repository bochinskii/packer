#!/bin/sh
#
# Hostname
#
export HOSTNAME=rocinante.int

hostnamectl set-hostname $HOSTNAME

#
# Update repos
#
yum makecache
yum update -y

#
# Timezone
#
export TIMEZONE=Europe/Moscow

timedatectl set-timezone $TIMEZONE

#
# SSH
#
export SSH_PORT=22

sed -i "s/^#Port .*/Port $SSH_PORT/g" /etc/ssh/sshd_config
systemctl reload sshd

#
# NGINX
#
yum install yum-utils -y
touch /etc/yum.repos.d/nginx.repo
cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/amzn2/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/amzn2/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

yum-config-manager --enable nginx-stable
yum makecache
yum install nginx -y
systemctl start nginx; sudo systemctl enable nginx

#
# MYSQL
#
# https://dev.mysql.com/get/mysql80-community-release-el7-6.noarch.rpm
export MYSQL_REPO="https://dev.mysql.com/get/mysql80-community-release-el7-6.noarch.rpm"

yum install $MYSQL_REPO -y
amazon-linux-extras install epel -y
yum makecache
yum install --nogpgcheck  mysql-community-server -y
systemctl start mysqld; sudo systemctl enable mysqld

export MYSQL_TEMP_PASS=`grep 'temporary password' /var/log/mysqld.log | cut -d " " -f13`
export MYSQL_ROOT_PASS=P@ssw0rd12345

# Secure installation
mysql --connect-expired-password -uroot -p$MYSQL_TEMP_PASS \
-e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_ROOT_PASS';"
mysql --connect-expired-password -uroot -p$MYSQL_ROOT_PASS \
-e "DELETE FROM mysql.user WHERE User='';"
mysql --connect-expired-password -uroot -p$MYSQL_ROOT_PASS \
-e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql --connect-expired-password -uroot -p$MYSQL_ROOT_PASS \
-e "DROP DATABASE IF EXISTS test; DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
mysql --connect-expired-password -uroot -p$MYSQL_ROOT_PASS -e "FLUSH PRIVILEGES;"
mysql --connect-expired-password -uroot -p$MYSQL_ROOT_PASS \
-e "ALTER USER 'root'@'localhost' REQUIRE SSL;"

export MYSQL_ADMIN_USER=admin
export MYSQL_ADMIN_USER_PASS=P@ssw0rd12345

# Create Admin user
mysql --connect-expired-password -uroot -p$MYSQL_ROOT_PASS \
-e "CREATE USER '$MYSQL_ADMIN_USER'@'localhost' IDENTIFIED BY '$MYSQL_ADMIN_USER_PASS';" --ssl-mode=REQUIRE
mysql --connect-expired-password -uroot -p$MYSQL_ROOT_PASS \
-e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_ADMIN_USER'@'localhost'; FLUSH PRIVILEGES;" --ssl-mode=REQUIRE

export MYSQL_DRUPAL_USER=drupaluser
export MYSQL_DRUPAL_USER_PASS=P@ssw0rd12345
export MYSQL_DRUPAL_DB=drupaldb

# Create Drupal
mysql --connect-expired-password -u$MYSQL_ADMIN_USER -p$MYSQL_ADMIN_USER_PASS \
-e "CREATE DATABASE $MYSQL_DRUPAL_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql --connect-expired-password -u$MYSQL_ADMIN_USER -p$MYSQL_ADMIN_USER_PASS \
-e "CREATE USER '$MYSQL_DRUPAL_USER'@'localhost' IDENTIFIED BY '$MYSQL_DRUPAL_USER_PASS';"
mysql --connect-expired-password -uroot -p$MYSQL_ROOT_PASS \
-e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON $MYSQL_DRUPAL_DB.* TO '$MYSQL_DRUPAL_USER'@'localhost'; FLUSH PRIVILEGES;" --ssl-mode=REQUIRE

#
# PHP
#
amazon-linux-extras enable php8.0
yum clean metadata
yum makecache
yum install php php-fpm php-pdo php-mysqlnd php-xml php-gd php-curl \
php-mbstring php-json php-common php-gmp php-intl php-gd php-cli php-zip php-opcache -y

# PHP-FPM Settings
sed -i "s/^user = .*/user = nginx/g" /etc/php-fpm.d/www.conf
sed -i "s/^group = .*/group = nginx/g" /etc/php-fpm.d/www.conf
sed -i "s/^;listen.owner = .*/listen.owner = nginx/g" /etc/php-fpm.d/www.conf
sed -i "s/^;listen.group = .*/listen.group = nginx/g" /etc/php-fpm.d/www.conf
sed -i "s/^;listen.mode = .*/listen.mode = 0660/g" /etc/php-fpm.d/www.conf

# Important
chown nginx: /var/lib/php/session
chmod 0775 /var/lib/php

systemctl enable php-fpm; sudo systemctl start php-fpm
systemctl restart nginx

#
# TLS
#
mkdir /etc/nginx/tls
openssl dhparam -out /etc/nginx/tls/dhparam.pem 2048

export SSL_CERT=rocinante.crt
export SSL_KEY=rocinante.key

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/tls/$SSL_KEY -out /etc/nginx/tls/$SSL_CERT -subj "/C=MA/ST= /L=MCR/O= /OU= /CN=rocinante.in"

#
# Drupal
#
export SITE_DIR=/var/www/html/rocinante

mkdir -p $SITE_DIR/{www,log}
curl -Lo /tmp/drupal.tar.gz https://www.drupal.org/download-latest/tar.gz
tar -xzvf /tmp/drupal.tar.gz -C $SITE_DIR/www --strip-components=1
chown -R nginx: $SITE_DIR

export SITE_CONFIG=rocinante.conf

touch /etc/nginx/conf.d/$SITE_CONFIG
sudo cat << EOF > /etc/nginx/conf.d/$SITE_CONFIG
server {
    listen 443 ssl http2 default_server;
    server_name _;
    root $SITE_DIR/www;

    ssl_certificate /etc/nginx/tls/$SSL_CERT;
    ssl_certificate_key /etc/nginx/tls/$SSL_KEY;

    access_log $SITE_DIR/log/access.log main;
    error_log $SITE_DIR/log/error.log;

   # phpMyAdmin:
    location /dbadmin {
        index index.php;

    auth_basic "Only for me";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }


    # Very rarely should these ever be accessed outside of your lan
    location ~* \.(txt|log)$ {
        allow 192.168.0.0/16;
        deny all;
    }

    location ~ \..*/.*\.php$ {
        return 403;
    }

    location ~ ^/sites/.*/private/ {
        return 403;
    }

    location ~ ^/sites/[^/]+/files/.*\.php$ {
        deny all;
    }

    location ~* ^/.well-known/ {
        allow all;
    }

    # Block access to "hidden" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.

    location ~ (^|/)\. {
        return 403;
    }

   location / {
        try_files \$uri /index.php?\$query_string;
    }

    location @rewrite {
        rewrite ^ /index.php;
    }

    location ~ /vendor/.*\.php$ {
        deny all;
        return 404;
    }

    location ~* \.(engine|inc|install|make|module|profile|po|sh|.*sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig|\.save)?$|^(\.(?!well-known).*|Entries.*|Repository|Root|Tag|Template|composer\.(json|lock)|web\.config)$|^#.*#$|\.php(~|\.sw[op]|\.bak|\.orig|\.save)$ {
        deny all;
        return 404;
    }

    location ~ '\.php$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)$;

        try_files \$fastcgi_script_name =404;

        include fastcgi_params;

        fastcgi_param DOCUMENT_ROOT \$document_root;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_script_name;
        fastcgi_param REQUEST_METHOD \$request_method;
        fastcgi_param CONTENT_TYPE \$content_type;
        fastcgi_param CONTENT_LENGTH \$content_length;
        # when https is on
        fastcgi_param HTTPS on;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param QUERY_STRING \$query_string;

        fastcgi_intercept_errors on;
        fastcgi_index index.php;
        fastcgi_ignore_client_abort off;
        fastcgi_connect_timeout 60;
        fastcgi_send_timeout 180;
        fastcgi_read_timeout 180;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;

        fastcgi_pass unix:/run/php-fpm/www.sock;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        try_files \$uri @rewrite;
        expires max;
        log_not_found off;
    }

    location ~ ^/sites/.*/files/styles/ {
        try_files \$uri @rewrite;
    }

    location ~ ^(/[a-z\-]+)?/system/files/ {
        try_files \$uri /index.php?\$query_string;
    }

    if (\$request_uri ~* "^(.*/)index\.php/(.*)") {
        return 307 \$1\$2;
    }
}

server {
    listen 80 default_server;
    server_name _;

    return 301 https://\$host\$request_uri;
}
EOF
systemctl restart nginx

#
# PHP My Admin
#
mkdir $SITE_DIR/www/dbadmin
curl -Lo /tmp/phpmyadmin.tar.xz https://files.phpmyadmin.net/phpMyAdmin/5.1.3/phpMyAdmin-5.1.3-all-languages.tar.xz
tar -xvf /tmp/phpmyadmin.tar.xz -C $SITE_DIR/www/dbadmin/ --strip-components=1
touch $SITE_DIR/www/dbadmin/config.in.php

export PMA_BLOWFISH=`echo $RANDOM | md5sum | head -c 32; echo;`

cat << EOF > $SITE_DIR/www/dbadmin/config.in.php
<?php

\$i = 0;

/* Server: localhost [1] */
\$i++;
\$cfg['Servers'][\$i]['verbose'] = '';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['port'] = '';
\$cfg['Servers'][\$i]['socket'] = '';
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['user'] = '';
\$cfg['Servers'][\$i]['password'] = '';

/* End of servers configuration */

\$cfg['DefaultLang'] = 'en';
\$cfg['blowfish_secret'] = '$PMA_BLOWFISH';
\$cfg['ServerDefault'] = 1;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';

\$cfg['TempDir'] = '$SITE_DIR/www/dbadmin/tmp';
?>
EOF
chown -R nginx: $SITE_DIR/www/dbadmin

export PMA_USER=$MYSQL_ADMIN_USER
export PMA_HTPASSW=$MYSQL_ADMIN_USER_PASS

htpasswd -b -c /etc/nginx/.htpasswd $PMA_USER $PMA_HTPASSW

#
# Logrotate
#
cat << EOF > /etc/logrotate.d/nginx
/var/log/nginx/*.log {
        daily
        missingok
        rotate 10
        size 10M
        compress
        delaycompress
        notifempty
        create 640 nginx adm
        sharedscripts
        postrotate
                if [ -f /var/run/nginx.pid ]; then
                        kill -USR1 `cat /var/run/nginx.pid`
                fi
        endscript
}
EOF

cat << EOF > /etc/logrotate.d/php-fpm
/var/log/php-fpm/*.log {
    daily
    missingok
    rotate 10
    size 10M
    notifempty
    sharedscripts
    compress
    delaycompress
    postrotate
        /bin/kill -SIGUSR1 `cat /run/php-fpm/php-fpm.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
EOF

cat << EOF > /etc/logrotate.d/mysql
/var/log/mysqld.log {
    create 640 mysql mysql
    notifempty
    daily
    rotate 10
    size 10M
    missingok
    compress
    postrotate
       # just if mysqld is really running
       if test -x /usr/bin/mysqladmin && \
          /usr/bin/mysqladmin ping &>/dev/null
       then
          /usr/bin/mysqladmin flush-logs
       fi
    endscript
}
EOF
