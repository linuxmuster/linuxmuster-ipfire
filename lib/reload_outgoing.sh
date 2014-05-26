#!/bin/bash
#
# reload outgoing firewall
#
# 26.05.2014
# thomas@linuxmuster.net
# GPL v3
#

# check minimum core update level
SETUPDIR="/var/linuxmuster"
. "$SETUPDIR/check_mincore"

IPFDIR="/var/ipfire"
TPLDIR="$SETUPDIR/templates"
ALLOWEDMACS="$IPFDIR/fwhosts/allowedmacs"
CSTGRPS="$IPFDIR/fwhosts/customgroups"
CSTGRPS_TMP="${CSTGRPS}.tmp"
FWCFG="$IPFDIR/firewall/config"
FWCFG_TMP="${FWCFG}.tmp"
FWCFG_TPL="$TPLDIR/firewall/config"
CSTSRVGRPS="$IPFDIR/fwhosts/customservicegrp"
CSTSRVGRPS_TPL="$TPLDIR/fwhosts/customservicegrp"

# test for updated firewall config
if ! grep -q allowedports "$FWCFG"; then

 # copy customservicegrp
 cp "$CSTSRVGRPS_TPL" "$CSTSRVGRPS"

 # remove old allowedmacs rules
 sed -e "/,allowedmacs,/d" -i "$FWCFG"

 # paste new rule from template to config
 grep allowedports "$FWCFG_TPL" >> "$FWCFG"

 # repair line numbers
 awk 'sub(/[0-9]*/,++c)' "$FWCFG" > "$FWCFG_TMP"
 mv "$FWCFG_TMP" "$FWCFG"

 # repair permissions
 chown nobody:nobody "$IPFDIR/firewall" -R

fi

# process uploaded allowed_macs file
if [ -e "$ALLOWEDMACS" ]; then

 # remove old entries
 grep -v ",allowedmacs," "$CSTGRPS" > "$CSTGRPS_TMP"

 # merge uploaded file
 cat "$ALLOWEDMACS" >> "$CSTGRPS_TMP"
 rm -rf "$ALLOWEDMACS"

 # repair line numbers
 awk 'sub(/[0-9]*/,++c)' "$CSTGRPS_TMP" > "$CSTGRPS"
 rm -rf "$CSTGRPS_TMP"

 # repair permissions
 chown nobody:nobody "$IPFDIR/fwhosts" -R

fi

# reload outgoing rules
/usr/local/bin/firewallctrl
