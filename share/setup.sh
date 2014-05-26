#
# starts ipfire configuration setup for linuxmuster.net
#
# thomas@linuxmuster.net
# 29.11.2013
# GPL v3
#

# initial setup
if [ -n "$first" ]; then
 if [ -z "$password" ]; then
  echo
  stty -echo
  read -p "Please enter IPFire's root password: " password; echo
  stty echo
 fi
 [ -z "$password" ] && bailout "No password given!"
 mykey="$(cat /root/.ssh/id_dsa.pub)"
 [ -z "$mykey" ] && bailout "No ssh key available!"
 if [ -s /root/.ssh/known_hosts ]; then
  for i in ipfire ipcop "$ipcopip"; do
   ssh-keygen -f "/root/.ssh/known_hosts" -R ["$i"]:222 &> /dev/null
  done
 fi
 # upload root's public key
 echo "$password" | "$SCRIPTSDIR/sshaskpass.sh" ssh -oStrictHostKeyChecking=no -p222 "$ipcopip" "mkdir -p /root/.ssh && echo "$mykey" > /root/.ssh/authorized_keys"
 # test passwordless ssh connection again
 test_pwless_fw || bailout "Aborting!"
 echo
fi

# test if firewall is IPFire
fwtype="$(get_fwtype)"
if [ "$fwtype" != "ipfire" ]; then
 bailout "This is not an IPFire firewall!"
fi

# copy templates to a temp dir
UPLOADTMP="/var/tmp/ipfire-upload.$$"
rm -rf "$UPLOADTMP"
mkdir -p "$UPLOADTMP"
[ -d "$UPLOADTMP" ] || cancel "Cannot create ipfire upload temp dir."
cp -a /var/lib/linuxmuster-ipfire/* "$UPLOADTMP/"

# update allowed ips file
"$SCRIPTSDIR"/internet_on_off.sh --nofirewall
# and copy it to the files to be uploaded
[ -e "$ALLOWEDIPS" ] && cp "$ALLOWEDIPS" "$UPLOADTMP/templates/outgoing/groups/ipgroups/allowedips"

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

# prepare necessary settings values for upload
echo "Adding linuxmuster settings ..."
cp "$NETWORKSETTINGS" "$UPLOADTMP/.settings"
echo "internmask=$INTERNMASK" >> "$UPLOADTMP/.settings"
echo "subnetmask=$SUBNETMASK" >> "$UPLOADTMP/.settings"

# upload linuxmuster.net scripts and templates
echo "Uploading linuxmuster.net's IPFire configuration scripts ..."
exec_ipcop /bin/rm -rf /var/linuxmuster
put_ipcop "$UPLOADTMP" /var/linuxmuster ; RC="$?"
rm -rf "$UPLOADTMP"

if [ "$RC" = "0" ]; then
 # start setup
 echo "Starting setup ..."
 exec_ipcop "/var/linuxmuster/linuxmuster-ipfire-setup && /sbin/reboot" || RC="1"
 if [ "$RC" = "0" ]; then
  echo "Rebooting IPFire. Done!"
 else
  bailout "Setup on IPFire failed!"
 fi
else
 bailout "Upload to IPFire failed!"
fi
