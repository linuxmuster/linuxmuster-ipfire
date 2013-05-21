#!/bin/bash
#
# reload outgoing firewall
#
# 21.05.2013
# thomas@linuxmuster.net
# GPL v3
#

# remove obsolete mac group file
rm -f /var/ipfire/outgoing/groups/macgroups/allowedmacs*

# reload outgoing rules
/usr/local/bin/outgoingfwctrl
