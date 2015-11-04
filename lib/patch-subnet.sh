#!/bin/sh
#
# changes netmask for green interface and sets static route
# invoked by linuxmuster-setup --modify
# never invoke this directly on ipfire!
#
# 26.11.2013
# Thomas Schmitt <thomas@linuxmuster.net>
# GPL v3
#

# read command line
internalnet="$1"
internmask="$2"
internbc="$3"
subnetgw="$4"
subnetmask="$5"
subnetbc="$6"
subnetting="$7"
[ -z "$internalnet" -o -z "$internmask" -o -z "$internbc" -o -z "$subnetgw" -o -z "$subnetmask" -o -z "$subnetbc" -o -z "$subnetting" ] && exit 1

rclocal="/etc/sysconfig/rc.local"
comment="# static route to L3 switch"
line="route add -net $internalnet netmask $internmask gw $subnetgw green0 $comment"

[ -e "$rclocal" ] && sed "/\($comment\)$/d" -i "$rclocal"
if [ "$subnetting" = "true" ]; then
 echo "$line" >> "$rclocal"
 chmod 755 "$rclocal"
 netmask="$subnetmask"
 broadcast="$subnetbc"
else
 netmask="$internmask"
 broadcast="$internbc"
fi

# patch netmask and broadcast for green interface
sed -e "s|^GREEN_NETMASK=.*|GREEN_NETMASK=$netmask|
        s|^GREEN_BROADCAST=.*|GREEN_BROADCAST=$broadcast|" -i /var/ipfire/ethernet/settings
