#!/bin/bash
#
# starts ipfire configuration setup for linuxmuster.net
#
# thomas@linuxmuster.net
# 21.01.2013
# GPL v3
#

# read linuxmuster.net settings
. /usr/share/linuxmuster/config/dist.conf || exit 1
. $HELPERFUNCTIONS || exit 1

# help
if [ "$1" = "--help" -o "$1" = "-h" ]; then
 echo "Usage: $0 [--first] [<password>]"
 echo
 echo "\"--first\" does an initial setup of passwordless ssh connection to ipfire first."
 echo "If password is not provided as second parameter it will be queried."
 echo "Note: Invokation without any parameter starts ipfire setup immediatly!"
 echo
 exit 0
fi

# initial setup
if [ "$1" = "--first" ]; then
 fwpasswd="$2"
 if [ -z "$fwpasswd" ]; then
  echo
  stty -echo
  read -p "Please enter IPFire's root password: " fwpasswd; echo
  stty echo
 fi
 [ -z "$fwpasswd" ] && exit 1
 mykey="$(cat /root/.ssh/id_dsa.pub)"
 [ -z "$mykey" ] && exit 1
 if [ -s /root/.ssh/known_hosts ]; then
  for i in ipfire ipcop "$ipcopip"; do
   ssh-keygen -f "/root/.ssh/known_hosts" -R ["$i"]:222 &> /dev/null
  done
 fi
 # upload root's public key
 echo "$fwpasswd" | "$SCRIPTSDIR/sshaskpass.sh" ssh -oStrictHostKeyChecking=no -p222 "$ipcopip" "mkdir -p /root/.ssh && echo "$mykey" > /root/.ssh/authorized_keys"
fi

# test passwordless ssh connection
test_pwless_fw || exit 1

# test if firewall is IPFire
fwtype="$(get_fwtype)"
if [ "$fwtype" != "ipfire" ]; then
 echo "This is not an IPFire firewall!"
 exit 1
fi

# copy templates to a temp dir
UPLOADTMP="/var/tmp/ipfire-upload.$$"
rm -rf "$UPLOADTMP"
mkdir -p "$UPLOADTMP"
[ -d "$UPLOADTMP" ] || cancel "Cannot create ipfire upload temp dir."
cp -a /var/lib/linuxmuster-ipfire/* "$UPLOADTMP/"

# create allowed macs
echo "Creating list of macaddresses for outgoing firewall ..."
allowedmacs="$UPLOADTMP/templates/outgoing/groups/macgroups/allowedmacs"
rm -f "$allowedmacs"
touch "$allowedmacs"
if [ -s "$BLOCKEDHOSTSINTERNET" ]; then
 echo "Active internet blockade detected, removing ..."
 rm -f "$BLOCKEDHOSTSINTERNET"
 touch "$BLOCKEDHOSTSINTERNET"
fi
grep ^[a-zA-Z0-9] $WIMPORTDATA | awk -F\; '{ print $4 }' | sort -u | tr a-z A-Z > "$allowedmacs"

# import ipcop ovpn certs & keys
IPCOPBAK="$(ls -xrt $BACKUPDIR/ipcop/backup-*.tar.gz 2> /dev/null | tail -1)"
if [ -n "$IPCOPBAK" ]; then
 echo "Found an IPCop-Backup, looking for OpenVPN certs ..."
 IPCOPTMP="/var/tmp/ipcop-backup.$$"
 rm -rf "$IPCOPTMP"
 mkdir -p "$IPCOPTMP"
 tar xf "$IPCOPBAK" -C "$IPCOPTMP" ; RC="$?"
 if [ -s "$IPCOPTMP/var/ipcop/ovpn/ovpnconfig" -a "$RC" = "0" ]; then
  echo "Importing OpenVPN certs ..."
  for i in ca certs crls openssl ovpnconfig server.conf settings; do
   cp -a "$IPCOPTMP/var/ipcop/ovpn/$i" "$UPLOADTMP/templates/ovpn"
  done
 else
  echo "No certs found."
 fi
 rm -rf "$IPCOPTMP"
 mv "$BACKUPDIR/ipcop" "$BACKUPDIR/ipcop_old"
fi

# copy settings file
echo "Adding linuxmuster settings ..."
cp "$NETWORKSETTINGS" "$UPLOADTMP/.settings"

# upload linuxmuster.net scripts and templates
echo "Uploading linuxmuster.net's IPFire configuration scripts ..."
exec_ipcop /bin/rm -rf /var/linuxmuster
put_ipcop "$UPLOADTMP" /var/linuxmuster ; RC="$?"
rm -rf "$UPLOADTMP"

if [ "$RC" = "0" ]; then
 # start setup
 echo "Starting setup ..."
 exec_ipcop "/var/linuxmuster/linuxmuster-ipfire-setup && /sbin/reboot" ; RC="$?"
 if [ "$RC" = "0" ]; then
  echo "Rebooting IPFire. Done!"
 else
  echo "Setup on IPFire failed!"
 fi
else
 echo "Upload to IPFire failed!"
fi

exit "$RC"
