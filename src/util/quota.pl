#! /usr/bin/perl
use strict;
use Quota;

Quota::setmntent();
while (my ($dev, $path, $type, $opts) = Quota::getmntent()) {
	next unless $dev =~ m:^/:;
	my @quota = Quota::query($dev);
	next unless @quota;

	print join("\t", $dev, $path, @quota), "\n";
}
Quota::endmntent();

