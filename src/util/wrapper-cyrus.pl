=head1 NAME

wrapper-cyrus.pl - wrapper for accessing mail quota

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::CYRUSQUOTAAPP;

 open SCRIPT, "| $Schulkonsole::Config::_wrapper_cyrus";
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id
 
 INPUT

=head1 DESCRIPTION

=cut

use strict;
use utf8;
use lib '/usr/share/schulkonsole';
use open ':utf8';
use open ':std';
use Schulkonsole::Wrapper;
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::CyrusError;
use POSIX;


my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

SWITCH: {

	$app_id == Schulkonsole::Config::CYRUSQUOTAAPP and do {
		cyrus_quota();
		last SWITCH;
	};
};

exit -2;	# program error

=head3 cyrus_quota

numeric constant: C<Schulkonsole::Config::CYRUSQUOTAAPP>

=head4 Description

collects and returns mail quota

=cut

sub cyrus_quota {

	my @users;
	while (<>) {
		my ($user) = /^(.+)$/;
		last unless $user;
	
		push @users, "user.\Q$user";
	}
	
	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open(CMDIN, "/usr/sbin/cyrquota @users |")
		or exit (Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);
	while(<CMDIN>){
		print $_;
	}
	close(CMDIN) or exit (Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);
	
	exit 0;

}
