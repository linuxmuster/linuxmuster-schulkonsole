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
use Schulkonsole::Repair;
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
		repair_classhomes();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::REPAIRPROJECTHOMESAPP and do {
		repair_projecthomes();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::REPAIRHOMESAPP and do {
		repair_homes();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::REPAIRGETINFOAPP and do {
		repair_get_info();
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

=head3 repair_classhomes

numeric constant: C<REPAIRCLASSHOMESAPP>

=head4 Description

Repair selected class users homes.

=cut

sub repair_classhomes {
	my $class = <>;
	($class) = $class =~ /^(\w+)$/;
	exit ( Schulkonsole::Error::RepairError::WRAPPER_NO_CLASS ) unless $class;
	
	my $opts = " --repairhomes --class $class";
	
	prepare_start();
	
	my $pid = fork;
	exit ( Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK ) unless $pid;
	
	if (not $pid) {
		do_repair( $opts );		
	}

	exit 0;

}

=head3 repair_projecthomes

numeric constant: C<REPAIRPROJECTHOMESAPP>

=head4 Description

Repair selected projects users homes.

=cut

sub repair_projecthomes {
	my $project = <>;
	($project) = $project =~ /^(p_[[:alnum:]]+)$/;
	exit ( Schulkonsole::Error::RepairError::WRAPPER_NO_PROJECT ) unless $project;
	
	my $opts = " --repairhomes --project $project";
	
	prepare_start();
	
	my $pid = fork;
	exit ( Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK ) unless $pid;
	
	if (not $pid) {
		do_repair( $opts );		
	}

	exit 0;

}

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

sub prepare_start {
	use Proc::ProcessTable;

	my $process_table = new Proc::ProcessTable;
	my $app_cmnd = Schulkonsole::Encode::to_cli($Schulkonsole::Config::_cmd_sophomorix_repair);
	$app_cmnd =~ s:.*/::;
	foreach my $process (@{ $process_table->table }) {
		if (    $process->uid == $>
		    and $process->fname =~ /^sophomor/
		    and $process->cmndline =~ /$app_cmnd/) {
			exit (  Schulkonsole::Error::RepairError::WRAPPER_PROCESS_RUNNING );
		}
	}
	system("rm -f $Schulkonsole::Repair::LOGFILE") or exit ( Schulkonsole::Error::RepairError::WRAPPER_CANNOT_DELETE_LOG );
}

sub do_repair {
	my $opts = shift;
	
	close STDIN;
	$< = $>;
	$) = 0;
	$( = $);
	umask(022);
	open STDOUT, '>>', Schulkonsole::Encode::to_fs($Schulkonsole::Repair::LOGFILE);	# ignore errors
	open STDERR, '>>&', *STDOUT;

	$ENV{PATH} = '/bin:/sbin:/usr/sbin:/usr/bin';
	$ENV{DEBIAN_FRONTEND} = 'teletype';
	exec $Schulkonsole::Config::_cmd_sophomorix_repair . $opts or return;
}
