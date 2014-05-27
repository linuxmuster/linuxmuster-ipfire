#!/bin/bash
#
# reload outgoing firewall
#
# 27.05.2014
# thomas@linuxmuster.net
# GPL v3
#

# check minimum core update level
SETUPDIR="/var/linuxmuster"
. "$SETUPDIR/check_mincore"

IPFDIR="/var/ipfire"
TPLDIR="$SETUPDIR/templates"
ALLOWEDHOSTS="$IPFDIR/fwhosts/allowedhosts"
ALLOWEDNETWORKS="$IPFDIR/fwhosts/allowednetworks"
CSTGRPS="$IPFDIR/fwhosts/customgroups"
FWCFG="$IPFDIR/firewall/config"
FWCFG_TPL="$TPLDIR/firewall/config"
CSTSRVGRPS="$IPFDIR/fwhosts/customservicegrp"
CSTSRVGRPS_TPL="$TPLDIR/fwhosts/customservicegrp"
CSTNETS="$IPFDIR/fwhosts/customnetworks"
CSTNETS_IMP="${CSTNETS}.import"
TMPFILE="/tmp/reload_outgoing.$$"


# functions

# renumber lines
renumber(){
 local files="$1"
 local i
 for i in $files; do
  awk 'sub(/[0-9]*/,++c)' "$i" > "$TMPFILE"
  mv "$TMPFILE" "$i"
 done
}


# test for updated firewall config
if ! grep -q ",allowedports," "$CSTSRVGRPS"; then

 # provide customservicegrp
 cat "$CSTSRVGRPS_TPL" >> "$CSTSRVGRPS"

 # remove deprecated firewall rules
 for i in macs ips ports; do
  sed -e "/,allowed$i,/d" -i "$FWCFG"
  sed -e "/,allowed$i,/d" -i "$CSTGRPS"
 done

 # paste new rules from template to config
 grep ",allowedports," "$FWCFG_TPL" >> "$FWCFG"

 # save files for renumbering
 renumber_files="$FWCFG $CSTSRVGRPS $CSTGRPS"

fi


# process imported custom networks
if [ -e "$CSTNETS_IMP" ]; then

 # remove imported networks
 sed -e '/import_workstations/d' -i "$CSTNETS"

 # merge networks
 cat "$CSTNETS_IMP" >> "$CSTNETS"
 rm -f "$CSTNETS_IMP"

 # save file for renumbering
 renumber_files="$renumber_files $CSTNETS"

fi


# process allowed hosts
if [ -e "$ALLOWEDHOSTS" ]; then

 # remove all allowed hosts first
 sed -e '/,allowedhosts,/d' -i "$CSTGRPS"
 
 # merge allowed networks
 cat "$ALLOWEDHOSTS" >> "$CSTGRPS"
 rm -f "$ALLOWEDHOSTS"
 
 # save file for renumbering
 echo "$renumber_files" | grep -q "$CSTGRPS" || renumber_files="$renumber_files $CSTGRPS"

 # check if allowedhosts fw rule is present
 if ! grep -q ",allowedhosts," "$FWCFG"; then
  grep ",allowedhosts," "$FWCFG_TPL" >> "$FWCFG"
  # save file for renumbering
  renumber_files="$renumber_files $FWCFG"
 fi

fi


# process allowed networks
if [ -e "$ALLOWEDNETWORKS" ]; then

 # remove all allowed networks first
 sed -e '/,allowednetworks,/d' -i "$CSTGRPS"
 
 # merge allowed networks
 cat "$ALLOWEDNETWORKS" >> "$CSTGRPS"
 rm -f "$ALLOWEDNETWORKS"
 
 # save file for renumbering if not yet done
 echo "$renumber_files" | grep -q "$CSTGRPS" || renumber_files="$renumber_files $CSTGRPS"
 
 # check if allowednetworks fw rule is present
 if ! grep -q ",allowednetworks," "$FWCFG"; then
  grep ",allowednetworks," "$FWCFG_TPL" >> "$FWCFG"
  # save file for renumbering if not yet done
   echo "$renumber_files" | grep -q "$FWCFG" || renumber_files="$renumber_files $FWCFG"
 fi

fi


# do renumbering
[ -n "$renumber_files" ] && renumber "$renumber_files"


# repair permissions
chown nobody:nobody "$IPFDIR/firewall" -R
chown nobody:nobody "$IPFDIR/fwhosts" -R


# reload outgoing rules
/usr/local/bin/firewallctrl
