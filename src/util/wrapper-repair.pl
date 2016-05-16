use CGI::Inspect;
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

my $child_initialized = 0;

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
	my @nums;
	my $list = <>;
	@nums = split(/,/, $list);
	foreach my $num (@nums) {
		($num) = $num =~ /^(\d+)$/;
		exit (  Schulkonsole::Error::RepairError::WRAPPER_INVALID_COMMAND )
			unless $num;
		exit ( Schulkonsole::Error::RepairError::WRAPPER_INVALID_COMMAND )
			if $num <= 0;
	}
	prepare_start();
	
	my $pid = fork;
	exit ( Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK ) unless defined $pid;
	if (not $pid) {
		if( @nums ){
			my @opts;
			foreach my $num (@nums) {
				my $opts = " --permissions --command-number $num";
				push @opts, $opts;
			}
			do_repair( @opts );
		}
		else {
			my $opts = " --permissions";
			do_repair( $opts );
		}
	#	system("rm -f " . Schulkonsole::Repair::LOGFILE);
	}
	
	exit 0;
}

=head3 repair_myhome

numeric constant: C<REPAIRMYHOMEAPP>

=head4 Description

Repair invoking users home folder

=cut

sub repair_myhome {
	my $user = $$userdata{uid};
	exit ( Schulkonsole::Error::RepairError::WRAPPER_NO_USER ) unless $user;
	
	my $opts = " --repairhome --user $user ";
	
	prepare_start();
	
	my $pid = fork;
	exit ( Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK ) unless defined $pid;
	
	if (not $pid) {
		do_repair( $opts );
	}
	
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
	
	my $opts = " --repairhome --class $class";
	
	prepare_start();
	
	my $pid = fork;
	exit ( Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK ) unless defined $pid;
	
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
	
	my $opts = " --repairhome --project $project";
	
	prepare_start();
	
	my $pid = fork;
	exit ( Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK ) unless defined $pid;
	
	if (not $pid) {
		do_repair( $opts );		
	}

	exit 0;

}

=head3 repair_homes

numeric constant: C<REPAIRHOMESAPP>

=head4 Description

Repair selected user groups home directories.

=cut

sub repair_homes {

	my $group = <>;
	($group) = $group =~ /^(\d+)$/;
	exit ( Schulkonsole::Error::RepairError::WRAPPER_NO_GROUP ) unless $group;
	
	my $opts = " --repairhome";
	if ( $group & Schulkonsole::Repair::STUDENTS ) {
	  $opts .= " --students";
	}
	elsif ( $group & Schulkonsole::Repair::TEACHERS ) {
	  $opts .= " --class teachers";
	}
	elsif ( $group & Schulkonsole::Repair::WORKSTATIONS ) {
	  $opts .= " --workstations";
	}
	elsif ( $group & Schulkonsole::Repair::ALL ) {
	  $opts = " --repairhome";
	}
	exit ( Schulkonsole::Error::RepairError::WRAPPER_INVALID_GROUP ) unless $group;
	
	prepare_start();
	
	my $pid = fork;
	exit ( Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK ) unless defined $pid;
	
	if (not $pid) {
		do_repair( $opts );
		# system("rm -f ".Schulkonsole::Repair::LOGFILE);
	}

	exit 0;
}

=head3 repair_get_info

numeric constant: C<REPAIRGETINFOAPP>

=head4 Description

Write possible permission repair options to stdout.

=cut

sub repair_get_info {
	
	my $opts = " --permissions --info ";
	
	my $command = $Schulkonsole::Config::_cmd_sophomorix_repair . $opts . " |";
	$< = $>;
	$( = $);
	$ENV{HOME}="/root" if not defined $ENV{HOME};	
	open(SCRIPTIN, $command) or
	exit (  Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);

	my $line;
	while(<SCRIPTIN>) {
	    ($line) = $_ =~ /^(.*?)$/;
	    print "$line\n" if defined $line;
	}
	close(SCRIPTIN) or 
	exit (  Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);
	
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
	system("rm -f " . Schulkonsole::Repair::LOGFILE);
}

sub init_child {
	close STDIN;
	$< = $>;
	$) = 0;
	$( = $);
	umask(022);
	open STDOUT, ">>", Schulkonsole::Encode::to_fs(Schulkonsole::Repair::LOGFILE);
	open STDERR, ">>&", *STDOUT;
	$ENV{PATH} = '/bin:/sbin:/usr/sbin:/usr/bin';
	$ENV{DEBIAN_FRONTEND} = 'teletype';
	$child_initialized = 1;
}

sub do_repair {
	my $opts = shift;
	my $cmd = $Schulkonsole::Config::_cmd_sophomorix_repair . $opts;
	foreach my $opts (@_) {
		$cmd .= "; " . $Schulkonsole::Config::_cmd_sophomorix_repair . $opts;
	}
	init_child();
	exec $cmd or return;
}
