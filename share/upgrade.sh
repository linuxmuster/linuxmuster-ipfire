#
# upgrades ipfire to latest supported version
#
# thomas@linuxmuster.net
# 29.12.2015
# GPL v3
#

# get version
MAXCORE="$(cat /var/lib/linuxmuster-ipfire/maxcore)"
ipfrel="$CACHEDIR/ipfire-release"
if get_ipcop /etc/system-release "$ipfrel"; then
  curver="$(cat "$ipfrel" | awk '{ print $2 }')"
  curcore="$(cat "$ipfrel" | awk '{ print $5 }' | sed 's/core//')"
  echo "IPFire $curver core $curcore detected"
  echo ""
    if [ "$curcore" -gt "$MAXCORE" ]; then
      bailout "Your current IPFire core update level is higher than the supported level ($MAXCORE)!"
    fi
fi

# If Core < 94, than tell user to run dpkg-reconfigure
if [ "$curcore" -lt 94 ]; then
  DPKGRE="1"
else 
  DPKGRE="0"
fi

# check if pakfire is already running
PAKPID="$(exec_ipcop_fb pidof pakfire)"

if [ ! -z "$PAKPID" ]; then
  bailout "there is already an update process running. Please run \"linuxmuster-ipfire --upgrade\" in serveral minutes again"
fi 

# Rebooting if necessary
if ( exec_ipcop_fb "test -e /var/run/need_reboot" ); then
  echo "IPFire needs a reboot before upgrading"
  exec_ipcop "reboot"
  bailout "Rebooting IPFire ..."
fi

# get new package lists
echo "downloading package lists ..."
if ! exec_ipcop "pakfire update --force"; then
  bailout "... downloading package liste failed"
fi

 echo "... package lists are up-to-date"
 echo ""

# get new version
ipfrel="$CACHEDIR/core-list.db"
if get_ipcop /opt/pakfire/db/lists/core-list.db "$ipfrel"; then
  newcore="$(cat "$ipfrel" | sed -ne '/core_release/p' | sed -e 's/[^0-9]//g')"
fi

# check if upgrade necessary
if [ "$curcore" -eq "$MAXCORE" ]; then
  bailout "your IPFire is up-to-date"
fi

# check if new level is supported by linuxmuster.net, otherwise patch IPFire
if [ "$newcore" -gt "$MAXCORE" ]; then
  exec_ipcop "sed -i 's/.*core_release.*/\$core_release=\"$MAXCORE\";/g' /opt/pakfire/db/lists/core-list.db"
fi

# upgrade IPFire to latest supported version
if [ ! -z "$PAKPID" ]; then
  bailout "there is already an update process running. Please run \"linuxmuster-ipfire --update\" in serveral minutes again"
fi 
echo "upgrading IPFire ..."

exec_ipcop_fb "-t screen pakfire upgrade -y"

while [ $? -eq 255 ]
 do
  echo "reconnecting to ipfire ..."
  exec_ipcop_fb "-t screen -r"
 done

# check if upgrade was successful
if [ $? -eq 0 ]; then
  ipfrel="$CACHEDIR/ipfire-release"
  if get_ipcop /etc/system-release "$ipfrel"; then
    curcore="$(cat "$ipfrel" | awk '{ print $5 }' | sed 's/core//')"
    if [ $curcore -eq $MAXCORE ]; then
      echo "... upgrade was successful"
      echo ""
    else
      bailout "... upgrade failed"
    fi
  else
    bailout "... upgrade failed"
  fi
else
  bailout "... upgrade failed"
fi

# Rebooting if necessary
if ( exec_ipcop_fb "test -e /var/run/need_reboot" ); then
echo "Rebooting IPfire ..."
echo ""
exec_ipcop "reboot"
fi

# Tell user to run reconfigure
if [ $DPKGRE -eq 1 ]; then
  echo "You have to run \"dpkg-reconfigure linuxmuster-ipfire\" (after IPFire has booted)."
fi
