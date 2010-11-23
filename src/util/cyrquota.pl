#! /usr/bin/perl
use strict;

print STDERR ">\n";

my @users;
while (<>) {
	my ($user) = /^(.+)$/;
	last unless $user;

	push @users, "user.\Q$user";
}

exec "/usr/sbin/cyrquota @users";
