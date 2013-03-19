#
# restores ipfire settings
#
# thomas@linuxmuster.net
# 19.03.2013
# GPL v3
#

# get local backup archive
latest_ipf="$(ls -1rt $BACKUPDIR/ipfire/*.ipf | tail -1)"

# upload it to ipfire
echo -n " * Uploading $(basename $latest_ipf) to IPFire ... "
put_ipcop "$latest_ipf" /var/ipfire/backup || bailout "Error!"
echo "Success!"

# untar it on ipfire
echo -n " * Unpacking archive ... "
exec_ipcop /bin/tar xpf /var/ipfire/backup/$(basename $latest_ipf) -C / || bailout "Error!"
echo "Success!"

# repair permissions
echo -n " * Repairing permissions ... "
exec_ipcop /var/linuxmuster/repair.sh || bailout "Error!"
echo "Success!"

echo
echo "To finish the restore you have to reboot IPFire!"
echo
