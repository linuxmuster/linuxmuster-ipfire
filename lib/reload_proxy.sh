#!/bin/bash
#
# patch squid.conf according to process banned ips
#
# 25.02.2015
# thomas@linuxmuster.net
# GPL v3
#

# omit proxy reload if set
[ "$1" = "--noreload" ] && noreload="yes"

# variables
PROXYDIR=/var/ipfire/proxy
SQUIDCONF="$PROXYDIR/squid.conf"
INCLUDEACL="$PROXYDIR/advanced/acls/include.acl"
PROXY_ALLOWED_IPS="$PROXYDIR/advanced/acls/src_allowed_ip.acl"
PROXY_UNRESTRICTED_IPS="$PROXYDIR/advanced/acls/src_unrestricted_ip.acl"
CUSTOM_INCLUDES_START="#Start of custom includes"
CUSTOM_INCLUDES_END="#End of custom includes"

# PROXY auth required
if grep -q "^acl for_inetusers" "$SQUIDCONF"; then
 proxyauth=" for_inetusers"
else
 proxyauth=
fi

# within timeframe
if grep -q "^acl within_timeframe" "$SQUIDCONF"; then
 timeframe=" within_timeframe"
else
 timeframe=
fi

# remove custom includes from squid.conf
sed -e "/$CUSTOM_INCLUDES_START/,/$CUSTOM_INCLUDES_END/d" -i "$SQUIDCONF"

# remove allowed ip acl from include.acl
sed -e "/^acl IPFire_allowed_ips/d
        /^http_access allow IPFire_allowed_ips/d" -i "$INCLUDEACL"
touch "$INCLUDEACL"

# add new custom includes to include.acl if there are allowed ips
if [ -s "$PROXY_ALLOWED_IPS" ]; then
 # add to include.acl
 echo "acl IPFire_allowed_ips src \"$PROXY_ALLOWED_IPS\"" >> "$INCLUDEACL"
 echo "http_access allow IPFire_allowed_ips${timeframe}${proxyauth}" >> "$INCLUDEACL"
fi

# if there are unrestricted ips add relevant options to squid.conf if not present (has to be done before reinserting custom includes)
if [ -s "$PROXY_UNRESTRICTED_IPS" ]; then

 # test if unrestricted_ips statement is already there, if not add it after last occurence of acl
 if ! grep -q ^"acl IPFire_unrestricted_ips" $SQUIDCONF; then
  awk 'NR==FNR{if (/^acl/) nr=NR; next} 1; FNR==nr{print "\nacl IPFire_unrestricted_ips src \"'"$PROXY_UNRESTRICTED_IPS"'\"\n"}' "$SQUIDCONF" "$SQUIDCONF" >  "$SQUIDCONF".new
  mv -f "$SQUIDCONF".new "$SQUIDCONF"
 fi
 if ! grep ^"http_access allow" "$SQUIDCONF" | grep -q IPFire_unrestricted_ips; then
  sed -e "/#Set custom configured ACLs/a\
http_access allow IPFire_unrestricted_ips" -i "$SQUIDCONF"
 fi

else # remove unrestricted_ips statement
 sed "/IPFire_unrestricted_ips/d" -i "$SQUIDCONF"
fi

# insert custom includes comment to squid.conf after last occurence of acl
awk 'NR==FNR{if (/^acl/) nr=NR; next} 1; FNR==nr{print "\n'"$CUSTOM_INCLUDES_START"'\n\n'"$CUSTOM_INCLUDES_END"'\n"}' "$SQUIDCONF" "$SQUIDCONF" >  "$SQUIDCONF".new
mv -f "$SQUIDCONF".new "$SQUIDCONF"
# insert custom includes between comment lines
sed -e "/$CUSTOM_INCLUDES_START/ r $INCLUDEACL
        s/$CUSTOM_INCLUDES_START/$CUSTOM_INCLUDES_START\n/" -i "$SQUIDCONF"
# remove doubled empty lines
sed '/^$/{N;/^\n$/d;}' -i $SQUIDCONF

# permissions
chown nobody:nobody "$PROXYDIR/advanced/acls" -R
chown nobody:nobody "$SQUIDCONF"

# reload/start proxy finally
if [ -z "$noreload" ]; then
 if ps ax | grep -v grep | grep -q squid; then
  /usr/local/bin/squidctrl reconfigure
 else
  /usr/local/bin/squidctrl start
 fi
fi
