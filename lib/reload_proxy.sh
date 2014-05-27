#!/bin/bash
#
# patch squid.conf according to process banned ips
#
# 27.05.2014
# thomas@linuxmuster.net
# GPL v3
#

# omit proxy reload if set
[ "$1" = "--noreload" ] && noreload="yes"

PROXYDIR=/var/ipfire/proxy
SQUIDCONF="$PROXYDIR/squid.conf"
INCLUDEACL="$PROXYDIR/advanced/acls/include.acl"
PROXY_ALLOWED_IPS="$PROXYDIR/advanced/acls/src_allowed_ip.acl"
PROXY_UNRESTRICTED_IPS="$PROXYDIR/advanced/acls/src_unrestricted_ip.acl"
CUSTOM_INCLUDES_START="#Start of custom includes"
CUSTOM_INCLUDES_END="#End of custom includes"


# if there are allowed ips
if [ -s "$PROXY_ALLOWED_IPS" ]; then

 # test if allowed_ips statement is already configured, if not add it
 if ! grep -q IPFire_allowed_ips "$INCLUDEACL"; then
  touch "$INCLUDEACL"
  echo "acl IPFire_allowed_ips src \"$PROXY_ALLOWED_IPS\"" >> "$INCLUDEACL"
  echo "http_access allow IPFire_allowed_ips within_timeframe" >> "$INCLUDEACL"
 fi
 if ! grep -q IPFire_allowed_ips "$SQUIDCONF"; then
  if ! grep -q "$CUSTOM_INCLUDES_START" "$SQUIDCONF"; then
   sed "/acl CONNECT method CONNECT/ a\\
\\
$CUSTOM_INCLUDES_START\\
\\
$CUSTOM_INCLUDES_END" -i "$SQUIDCONF"
  fi
  sed "/$CUSTOM_INCLUDES_START/ a\\
\\
acl IPFire_allowed_ips src \"$PROXY_ALLOWED_IPS\"\\
http_access allow IPFire_allowed_ips within_timeframe" -i "$SQUIDCONF"
 fi

else # remove allowed_ips statement
 sed '/IPFire_allowed_ips/d' -i "$INCLUDEACL"
 sed '/^$/d' -i "$INCLUDEACL"
 sed '/IPFire_allowed_ips/d' -i "$SQUIDCONF"
fi


# if there are unrestricted ips
if [ -s "$PROXY_UNRESTRICTED_IPS" ]; then

 # test if banned_ip statement is already there, if not add it
 if ! grep -q ^"acl IPFire_unrestricted_ips" $SQUIDCONF; then
  sed -e "/acl CONNECT method CONNECT/i\
acl IPFire_unrestricted_ips src \"$PROXY_UNRESTRICTED_IPS\"" -i "$SQUIDCONF"
 fi
 if ! grep ^"http_access allow" "$SQUIDCONF" | grep -q IPFire_unrestricted_ips; then
  sed -e "/#Set custom configured ACLs/a\
http_access allow IPFire_unrestricted_ips" -i "$SQUIDCONF"
 fi

else # remove unrestricted_ips statement
 sed "/IPFire_unrestricted_ips/d" -i "$SQUIDCONF"
fi

# permissions
chown nobody:nobody "$PROXYDIR/advanced/acls" -R

# reload proxy finally
[ -z "$noreload" ] && /usr/local/bin/squidctrl reconfigure
