#!/bin/sh
#
# change domainname on ipfire
# invoked by linuxmuster-setup --modify
# never invoke this directly on ipfire!
#
# 15.01.2013
# Thomas Schmitt <thomas@linuxmuster.net>
# GPL v3
#

# read command line
domainname_old=$1
domainname=$2
servername=$3
[ -z "$domainname_old" ] && exit 1
[ -z "$domainname" ] && exit 1
[ -z "$servername" ] && exit 1

# basedn
basedn="dc=`echo $domainname|sed 's/\./,dc=/g'`"

# /etc/hosts
sed -e "s/ipfire.$domainname_old.*/ipfire.$domainname\tipfire/g
	s/$servername.$domainname_old.*/$servername.$domainname\t$servername/g" -i /etc/hosts

# /var/ipfire
cd /var/ipfire
for i in main/hostname.conf main/hosts main/settings ovpn/server.conf ovpn/settings proxy/advanced/settings proxy/squid.conf proxy/.squid.conf; do
	sed -e "s/DOMAIN $domainname_old.*/DOMAIN $domainname\"/g
        	s/\@$domainname_old.*/\@$domainname/g
        	s/,$domainname_old.*/,$domainname/g
        	s/=$domainname_old.*/=$domainname/g
        	s/.$domainname_old.*/.$domainname/g
		s/^LDAP_BASEDN=.*/LDAP_BASEDN=ou=accounts,$basedn/" -i $i
done
