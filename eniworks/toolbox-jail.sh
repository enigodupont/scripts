#!/bin/sh

# Jail should have the following parameters
# Name: toolbox
# Type: Basejail
# Release: LATEST
# NET: VNET + TOOL-IP / 24 + BCE1
# MOUNTPOINT: /mnt/postgresql

## Postgres Install, I NEED 14
pkg install vim postgresql14-server postgresql14-docs postgresql14-contrib
sysrc postgresql_enable=YES

sysrc postgresql_data=/mnt/postgresql

/usr/local/etc/rc.d/postgresql initdb


chown -R postgres:postgres /mnt/postgresql/

# * on listen addresses
vim /mnt/postgresql/postgresql.conf

echo "host    all             all             10.64.0.0/16            trust" >> /mnt/postgresql/pg_hba.conf

service postgresql start

service postgresql status

# Reset postgres password
passwd postgres

## Install LDAP

pkg install openldap26-server openldap26-client ca_root_nss apache24 phpldapadmin-php74 mod_php74

sysrc slapd_enable=YES

# Needed for SSL later
#sysrc slapd_flags='-h "ldapi://%2fvar%2frun%2fopenldap%2fldapi/ ldap://0.0.0.0/"'
#sysrc slapd_sockets="/var/run/openldap/ldapi"

echo "Hash LDAP Pass, copy quickly"
slappasswd

echo '
include         /usr/local/etc/openldap/schema/core.schema
include         /usr/local/etc/openldap/schema/cosine.schema
include         /usr/local/etc/openldap/schema/nis.schema
include         /usr/local/etc/openldap/schema/inetorgperson.schema
'

echo "Modify slapd.conf with password hash and includes."
echo "Open another shell and add your ldif temp file and slapadd it"
echo "slapadd -v -c -l ~/eniworks.ldif -f /usr/local/etc/openldap/slapd.conf; service slapd restart"
sleep 10
vim /usr/local/etc/openldap/slapd.conf

service slapd start

service slapd status

# PHPLDAPADMIN Setup

sysrc apache24_enable=YES

chown -R www:www /usr/local/www/phpldapadmin

echo '
Alias /phpldapadmin/ "/usr/local/www/phpldapadmin/htdocs/"

<Directory "/usr/local/www/phpldapadmin/htdocs">
    Options none
    AllowOverride none    
    Require all granted
</Directory>
' > /usr/local/etc/apache24/Includes/phpldapadmin.conf

echo '
<FilesMatch "\.php$">
    SetHandler application/x-httpd-php
</FilesMatch>
<FilesMatch "\.phps$">
    SetHandler application/x-httpd-php-source
</FilesMatch>
' >> /usr/local/etc/apache24/httpd.conf
 
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

echo "Increase php memory to 256"
vim /usr/local/etc/php.ini

echo "Set ldap config for phpldapadmin"
vim /usr/local/www/phpldapadmin/config/config.php

service apache24 start

service apache24 status

## Install Mailserver

pkg install postfix

sysrc postfix_enable="YES"
sysrc sendmail_enable="NONE"


mkdir -p /usr/local/etc/mail

service postfix start

sleep 3

install -m 0644 /usr/local/share/postfix/mailer.conf.postfix /usr/local/etc/mail/mailer.conf

echo "smtputf8_enable = no" >> /usr/local/etc/postfix/main.cf

echo "Set mynetworks to your cidr and remove the host setting"
vim /usr/local/etc/postfix/main.cf

newaliases
postfix reload

service postfix restart