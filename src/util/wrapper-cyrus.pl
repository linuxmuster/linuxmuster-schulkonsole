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
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::CyrusError;
use POSIX;


my $id = <>;
$id = int($id);
my $password = <>;
chomp $password;

my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHENTICATED_ID
      )
	unless $userdata;

my $app_id = <>;
($app_id) = $app_id =~ /^(\d+)$/;
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST
      )
	unless defined $app_id;

my $app_name = $Schulkonsole::Config::_id_root_app_names{$app_id};
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST
      )
	unless defined $app_name;



my $permissions = Schulkonsole::Config::permissions_apps();
my $groups = Schulkonsole::DB::user_groups(
	$$userdata{uidnumber}, $$userdata{gidnumber}, $$userdata{gid});

my $is_permission_found = 0;
foreach my $group (('ALL', keys %$groups)) {
	if ($$permissions{$group}{$app_name}) {
		$is_permission_found = 1;
		last;
	}
}
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHORIZED_ID
      )
	unless $is_permission_found;

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
