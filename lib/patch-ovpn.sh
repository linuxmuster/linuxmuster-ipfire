#!/bin/sh
#
# modify openvpn settings on ipfire
# invoked by linuxmuster-setup --modify
# never invoke this directly on ipfire!
#
# 15.01.2013
# Thomas Schmitt <thomas@linuxmuster.net>
# GPL v3
#

# read command line
country="$1"
state="$2"
location="$3"
schoolname="$4"
[ -z "$country" ] && exit 1
[ -z "$state" ] && exit 1
[ -z "$location" ] && exit 1
[ -z "$schoolname" ] && exit 1

# /var/ipfire/ovpn/settings
sed -e "s/^ROOTCERT_CITY=.*/ROOTCERT_CITY=$location/
	s/^ROOTCERT_ORGANIZATION=.*/ROOTCERT_ORGANIZATION=$schoolname/
	s/^ROOTCERT_STATE=.*/ROOTCERT_STATE=$state/
	s/^ROOTCERT_COUNTRY=.*/ROOTCERT_COUNTRY=$country/" -i /var/ipfire/ovpn/settings
