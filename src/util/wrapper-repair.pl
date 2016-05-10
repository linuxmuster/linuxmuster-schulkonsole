=head1 NAME

wrapper-repair.pl - wrapper für root Funktionen

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = 1;

 open SCRIPT, "| /usr/lib/schulkonsole/bin/wrapper-repair";
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
use Schulkonsole::Error::Error;
use Schulkonsole::Error::RepairError;
use Schulkonsole::Config;
use POSIX;


my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

SWITCH: {

	$app_id == Schulkonsole::Config::REPAIRPERMISSIONSAPP and do {
		repair_permissions();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::REPAIRMYHOMEAPP and do {
		repair_myhome();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::REPAIRCLASSHOMESAPP and do {
		repair_classhome();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::REPAIRPROJECTHOMESAPP and do {
		repair_projecthome();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::REPAIRHOMESAPP and do {
		repair_homes();
		last SWITCH;
	};

};

exit -2;	# program error

=head3 repair_permissions

numeric constant: C<REPAIRPERMISSIONSAPP>

=head4 Description

Repair selected permissions.

=cut

sub repair_permissions {

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	system($Schulkonsole::Config::_cmd_sophomorix_repair) == 0
		or exit (Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);

	exit 0;

}

=head3 repair_myhome

numeric constant: C<REPAIRMYHOMEAPP>

=head4 Description

Repair invoking users home folder

=cut

sub repair_myhome {

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open(CMDIN, "/usr/sbin/muster-script2 |")
		or exit (Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);
	while(<CMDIN>){
		print $_;
	}
	close(CMDIN) or exit (Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);
	
	exit 0;

}
