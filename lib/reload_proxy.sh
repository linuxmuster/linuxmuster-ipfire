#!/bin/bash
#
# patch squid.conf according to process banned macs
#
# 25.01.2013
# thomas@linuxmuster.net
# GPL v3
#

fwname=IPFire
proxydir=/var/ipfire/proxy
squidconf="$proxydir/squid.conf"
bannedmacs="$proxydir/advanced/acls/src_banned_mac.acl"

# if there are banned macs
if [ -s "$bannedmacs" ]; then

 # test if banned_mac statement is already there, if not add it
 if ! grep -q ${fwname}_banned_mac $proxydir/squid.conf; then
  sed -e "/acl CONNECT method CONNECT/a\
acl ${fwname}_banned_mac       arp \"$bannedmacs\"" -i "$squidconf"
  sed -e "/#Set custom configured ACLs/a\
http_access deny  ${fwname}_banned_mac" -i "$squidconf"
 fi

else # remove banned_mac statement
 sed "/${fwname}_banned_mac/d" -i "$squidconf"
fi

# reload proxy finally
/usr/local/bin/squidctrl reconfigure