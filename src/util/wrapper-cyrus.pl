#! /usr/bin/perl
use strict;
use CGI::Inspect;

print STDERR ">\n";

my @users;
while (<>) {
	CGI::Inspect::inspect();
	my ($user) = /^(.+)$/;
	last unless $user;

	push @users, "user.\Q$user";
}

exec "/usr/sbin/cyrquota @users";
