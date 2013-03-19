#
# backs up ipfire settings
# 
# thomas@linuxmuster.net
# 19.03.2013
# GPL v3
#

# backup settings on IPFire
echo -n " * Backing up ipfire settings ... "
[ -d "$BACKUPDIR/ipfire" ] || mkdir -p $BACKUPDIR/ipfire
for cmd in makedirs exclude; do
 exec_ipcop /usr/local/bin/backupctrl $cmd >/dev/null 2>&1 || bailout "Error executing ${cmd}!"
done
echo "Success!"

# download the last backup archive
latest_ipf="$(ssh -p 222 root@${ipcopip} ls -1rt /var/ipfire/backup/*.ipf | tail -1)"
[ -z "$latest_ipf" ] && bailout " * Fatal: No backup archive found on IPFire!"
echo -n " * Downloading backup archive $(basename $latest_ipf) ... "
get_ipcop $latest_ipf $BACKUPDIR/ipfire || bailout "Error!"
echo "Success!"

# keep the last three archives
archives="$(ls $BACKUPDIR/ipfire/*.ipf)"
nr_all="$(echo $archives | wc -w)"
nr_del=$(( $nr_all - 3 ))
msg="archive"
[ $nr_del -gt 1 ] && msg="archives"
if [ $nr_del -gt 0 ]; then
 echo -n " * Removing $nr_del old $msg ... "
 c=1
 for i in $archives; do
  rm -f "$i"
  c=$(( $c + 1 ))
  [ $c -gt $nr_del ] && break
 done
 echo "Done!"
fi
echo
