#! /usr/bin/perl
use strict;
use Quota;

my %mountpoints_seen;
Quota::setmntent();
while (my ($dev, $path, $type, $opts) = Quota::getmntent()) {
	next unless $dev =~ m:^/:;
	my @quota = Quota::query($dev);
	next unless @quota;
	if (not exists $mountpoints_seen{$dev}){
	     $mountpoints_seen{$dev}="$path";
	     print join("\t", $dev, $path, @quota), "\n";
        }
}
Quota::endmntent();

