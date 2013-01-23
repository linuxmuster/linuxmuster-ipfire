#!/bin/bash
#
# repair permissions in /var/ipfire
#
# 16.01.2013
# Thomas Schmitt <thomas@linuxmuster.net>
# GPL v3
#

OWNROOT="addon-lang backup dhcpc extrahd/scan extrahd/bin firebuild fireinfo \
         general-functions.pl header.pl lang.pl langs menu.d red \
         proxy/errorpage-*.css proxy/calamaris/bin/* ethernet/scanned_nics \
         snort/oinkmaster.conf main/gpl_accepted main/hostname.conf"

chmod 644 /var/log/squidGuard/*
chown -R squid:squid /var/log/squid*
chown -R nobody:nobody /var/ipfire/*
for i in $OWNROOT; do
 chown -R root:root /var/ipfire/$i
done
chgrp nobody /var/ipfire/dhcpc
chown nobody:nobody /var/ipfire/extrahd/bin/*
chmod 600 /var/ipfire/ovpn/ca/cakey.pem
chmod 600 /var/ipfire/ovpn/certs/serverkey.pem
find /var/ipfire/urlfilter -name \*.db -exec chmod 666 '{}' \;
