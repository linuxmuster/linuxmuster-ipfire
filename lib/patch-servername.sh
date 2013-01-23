#!/bin/sh
#
# change servername on ipfire
# invoked by linuxmuster-setup --modify
# never invoke this directly on ipfire!
#
# 15.01.2013
# Thomas Schmitt <thomas@linuxmuster.net>
# GPL v3
#

# read command line
servername_old=$1
servername=$2
[ -z "$servername_old" ] && exit 1
[ -z "$servername" ] && exit 1

domainname=`dnsdomainname`

# /etc/hosts
sed -e "s/$servername_old.$domainname.*/$servername.$domainname\t$servername/" -i /etc/hosts

# /var/ipfire/main/hosts
sed -e "s/,$servername_old,/,$servername,/" -i /var/ipfire/main/hosts

# /var/ipfire/ovpn/server.conf
sed -e "s/$servername_old.$domainname/$servername.$domainname/g" -i /var/ipfire/ovpn/server.conf

#  /var/ipfire/ovpn/settings
sed -e "s/$servername_old.$domainname/$servername.$domainname/g" -i /var/ipfire/ovpn/settings

