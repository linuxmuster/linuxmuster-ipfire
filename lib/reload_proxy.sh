#!/bin/bash
#
# patch squid.conf according to process banned ips
#
# 22.05.2013
# thomas@linuxmuster.net
# GPL v3
#

proxydir=/var/ipfire/proxy
squidconf="$proxydir/squid.conf"
includeacl="$proxydir/advanced/acls/include.acl"
proxy_allowed_ips="$proxydir/advanced/acls/src_allowed_ip.acl"
proxy_unrestricted_ips="$proxydir/advanced/acls/src_unrestricted_ip.acl"
outgoing_allowed_ips="/var/ipfire/outgoing/groups/ipgroups/allowedips"
custom_includes_start="#Start of custom includes"
custom_includes_end="#End of custom includes"


# update allowed ips
if [ -e "$outgoing_allowed_ips" ]; then
 cp -f "$outgoing_allowed_ips" "$proxy_allowed_ips"
 sed '/^$/d' -i "$proxy_allowed_ips"
 chown nobody:nobody "$proxy_allowed_ips"
else
 rm -f "$proxy_allowed_ips"
fi


# if there are allowed ips
if [ -s "$proxy_allowed_ips" ]; then

 # test if allowed_ips statement is already configured, if not add it
 if ! grep -q IPFire_allowed_ips "$includeacl"; then
  touch "$includeacl"
  echo "acl IPFire_allowed_ips src \"$proxy_allowed_ips\"" >> "$includeacl"
  echo "http_access allow IPFire_allowed_ips within_timeframe" >> "$includeacl"
 fi
 if ! grep -q IPFire_allowed_ips "$squidconf"; then
  if ! grep -q "$custom_includes_start" "$squidconf"; then
   sed "/acl CONNECT method CONNECT/ a\\
\\
$custom_includes_start\\
\\
$custom_includes_end" -i "$squidconf"
  fi
  sed "/$custom_includes_start/ a\\
\\
acl IPFire_allowed_ips src \"$proxy_allowed_ips\"\\
http_access allow IPFire_allowed_ips within_timeframe" -i "$squidconf"
 fi

else # remove allowed_ips statement
 sed '/IPFire_allowed_ips/d' -i "$includeacl"
 sed '/^$/d' -i "$includeacl"
 sed '/IPFire_allowed_ips/d' -i "$squidconf"
fi
chown nobody:nobody "$includeacl"


# if there are unrestricted ips
if [ -s "$proxy_unrestricted_ips" ]; then

 # test if banned_ip statement is already there, if not add it
 if ! grep -q ^"acl IPFire_unrestricted_ips" $squidconf; then
  sed -e "/acl CONNECT method CONNECT/i\
acl IPFire_unrestricted_ips src \"$proxy_unrestricted_ips\"" -i "$squidconf"
 fi
 if ! grep ^"http_access allow" "$squidconf" | grep -q IPFire_unrestricted_ips; then
  sed -e "/#Set custom configured ACLs/a\
http_access allow IPFire_unrestricted_ips" -i "$squidconf"
 fi

else # remove unrestricted_ips statement
 sed "/IPFire_unrestricted_ips/d" -i "$squidconf"
fi

# reload proxy finally
/usr/local/bin/squidctrl reconfigure
