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

=head3 funktion1

numeric constant: C<1>

=head4 Description

<<Beschreibung der ersten Funktion>>

=cut

sub funktion1 {

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	system("/usr/sbin/muster-script1") == 0
		or exit (Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);

	exit 0;

}

=head3 funktion2

numeric constant: C<2>

=head4 Description

<<Beschreibung der zweiten Funktion>>

=cut

sub funktion1 {

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
