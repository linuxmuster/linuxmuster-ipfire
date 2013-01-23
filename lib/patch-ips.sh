#!/bin/sh
#
# change ips on ipfire
# invoked by linuxmuster-setup --modify
# never invoke this directly on ipfire!
#
# 15.01.2013
# Thomas Schmitt <thomas@linuxmuster.net>
# GPL v3
#

# read command line
sub_old=$1
sub_new=$2
[ -z "$sub_old" ] && exit 1
[ -z "$sub_new" ] && exit 1

# compute ips
serverip_old=10.$sub_old.1.1
ipcopip_old=10.$sub_old.1.254
serverip=10.$sub_new.1.1
ipcopip=10.$sub_new.1.254
orangesub_old=$(( $sub_old+1 ))
ovpnsub_old=$(( $sub_old+2 ))
orangesub=$(( $sub_new+1 ))
ovpnsub=$(( $sub_new+2 ))
ipcopblue_old=172.16.$sub_old
ipcoporange_old=172.16.$orangesub_old
ipcopovpn_old=172.16.$ovpnsub_old
ipcopblue=172.16.$sub_new
ipcoporange=172.16.$orangesub
ipcopovpn=172.16.$ovpnsub

# /etc/hosts & /etc/snort/vars
for i in /etc/hosts /etc/snort/vars; do
	sed -e "s/10.$sub_old./10.$sub_new./g
        	s/$ipcopblue_old./$ipcopblue./g
        	s/$ipcoporange_old./$ipcoporange./g
        	s/$ipcopovpn_old./$ipcopovpn./g" -i $i
done

# /var/ipfire
maxsub=$(( $sub_new+16 ))
n=$sub_new; o=$sub_old
while [ $n -lt $maxsub ]; do
	for i in `grep -r "10\.$o\." /var/ipfire/* | grep -v blacklists | awk -F\: '{ print $1 }'`; do
		sed -e "s/10.$o./10.$n./g" -i $i
	done
	let n+=1
	let o+=1
done
for i in `grep -r "$ipcopblue_old\." /var/ipfire/* | grep -v blacklists | awk -F\: '{ print $1 }'`; do
	sed -e "s/$ipcopblue_old./$ipcopblue./g" -i $i
done
for i in `grep -r "$ipcoporange_old\." /var/ipfire/* | grep -v blacklists | awk -F\: '{ print $1 }'`; do
	sed -e "s/$ipcoporange_old./$ipcoporange./g" -i $i
done
for i in `grep -r "$ipcopovpn_old\." /var/ipfire/* | grep -v blacklists | awk -F\: '{ print $1 }'`; do
	sed -e "s/$ipcopovpn_old./$ipcopovpn./g" -i $i
done
