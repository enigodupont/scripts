#!/bin/sh

iocage create -n "cups" -r 13.1-RELEASE vnet="on" allow_raw_sockets="1" dhcp="on" vnet_default_interface="igb0" bpf="yes" boot="on" devfs_ruleset=2; 

iocage exec "cups" "IGNORE_OSVERSION=yes pkg install -y cups hplip py39-pycups wget vim";

iocage exec "cups" 'echo "cupsd_enable=YES" >> /etc/rc.conf;'; 

iocage exec "cups" "cd /usr/local/etc/cups; mv cupsd.conf cupsd.conf.bkp; wget https://gist.githubusercontent.com/chetan/b147bb584d8c7b3554f51f4a84f1b67f/raw/46b12f782ad5f435f2475a5b6debb6ad628dde75/cupsd.conf";

iocage exec "cups" "service cupsd start";

#  py39-avahi 
# echo "avahi_daemon_enable=YES" >> /etc/rc.conf';
# echo "dbus_enable=YES" >> /etc/rc.conf';
#service avahi-daemon status
#/usr/local/etc/avahi
