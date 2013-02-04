#!/usr/bin/perl
#
# This code is distributed under the terms of the GPL V3
#
# (c) written from scratch
#
# 04.02.2013
# Thomas Schmitt <thomas@linuxmuster.net>

use strict;
use File::Copy;

my $c;
my $found;
my $acl;
my $skip;
my $skipcount;
my $squidGuardConf = "/var/ipfire/urlfilter/squidGuard.conf";
my $settings = "/var/ipfire/urlfilter/settings";
my $squidGuardConftmp = "/tmp/squidGuard.conf.$$";
my $settingstmp = "/tmp/settings.$$";

my $unfiltered_ips = "@ARGV";

# filter out UNFILTERED_CLIENTS from settings file
system("/bin/grep -v UNFILTERED_CLIENTS $settings > $settingstmp");

# open temp file to append new setting
open(TMP, ">> $settingstmp") or die "Cannot open $settingstmp: $!";

# if ips are set
if ($unfiltered_ips) {

  # print ip list to temp file
  print TMP "UNFILTERED_CLIENTS=\'$unfiltered_ips\'\n" or die "Cannot write $settingstmp: $!";

# if ips are not set
} else {

  # print message
  print "Your have to specify at least the server ip as argument!\n";
  print "\n";
  print "Usage example:\n";
  print "linuxmuster-unfilter.pl 10.16.1.1 10.16.100.1 10.16.100.2 ...\n";
  exit(1);

}

# close temp file
close TMP;

# move temp file
copy($settingstmp, $settings) or die "Cannot write $settings: $!";
unlink($settingstmp) or die "Cannot delete $settingstmp: $!";

# change owner and group to nobody
system("chown nobody:nobody $settings");

# open conf files
open(TMP, "> $squidGuardConftmp") or die "Cannot open $squidGuardConftmp: $!";
open(CONF, "< $squidGuardConf") or die "Cannot open $squidGuardConf: $!";

# write $squidGuardConftmp and change unfiltered client ips
$acl = 0;
$found = 0;
$skip = 0;
$skipcount = -1;

while (<CONF>){

  # skipping lines
  if ($skip > 0) {
    if ($skip == $skipcount) {
      $skip = 0;
      $skipcount = -1;
    } else {
      $skip++;
    }
    next;
  }

  # if src unfiltered statement is present
  if ($_ =~ /src unfiltered {/) {

    # if ips are set change ip statement
    if ($unfiltered_ips) {

      print TMP $_;
      print TMP "    ip $unfiltered_ips\n";
      $found = 1;
      $skip = 1;
      $skipcount= 1;
      next;

    # delete lines if no ips are set
    } else {

      $found = 1;
      $skip = 1;
      $skipcount = 3;
      next;

    } # endif $unfiltered_ips

  } # endif src unfiltered

  # write src unfiltered statement if it was not present before
  # and unfiltered ips are set
  if ($_ =~ /^dest .*/ && $found == 0 && $unfiltered_ips) {

    print TMP "src unfiltered {\n";
    print TMP "    ip $unfiltered_ips\n";
    print TMP "}\n";
    print TMP "\n";
    $found = 1;

  }

  # check acl section
  if ($_ =~ /^acl {/) {

    print TMP $_;
    $acl = 1;
    next;

  }

  # write unfiltered acl, if we are in acl section
  if ($acl == 1) {

    # unfiltered statement is present
    if ($_ =~ /unfiltered {/) {

      # unfiltered ips are set, do nothing
      if ($unfiltered_ips) {

        $acl = 0;

      # unfiltered ips are not set, skip lines with unfiltered statement
      } else {

        $acl = 0;
        $skip = 1;
        $skipcount = 3;
        next;

      } # end if unfiltered ips are set

    # unfiltered statement is not present
    } else {

      # unfiltered ips are set, print unfiltered statement
      if ($unfiltered_ips) {

        print TMP "    unfiltered {\n";
        print TMP "        pass all\n";
        print TMP "    }\n";
        print TMP "\n";
        $acl = 0;

      # unfiltered ips are not set, do nothing
      } else {

        $acl = 0;

      } # end if unfiltered ips are set

    } # end if unfiltered statement

  } # end if acl section

  # write line to temp file
  print TMP $_;

} # end while CONF

# close files
close CONF;
close TMP;

# move temp file
copy($squidGuardConftmp, $squidGuardConf) or die "Cannot write $squidGuardConf: $!";
unlink($squidGuardConftmp) or die "Cannot delete $squidGuardConftmp: $!";

# change owner and group to nobody
system("chown nobody:nobody $squidGuardConf");

# restarting squid
system("/usr/sbin/squid -k reconfigure");

exit 0;
