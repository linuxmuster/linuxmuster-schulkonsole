#! /usr/bin/perl

=head1 NAME

wrapper-files.pl - wrapper for writing files

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::WRITEFILEAPP;

 open SCRIPT, '|-', $Schulkonsole::Config::_wrapper_files;
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id
 1
 line1
 line2

 INPUT

=head1 DESCRIPTION

=cut

use strict;
use lib '/usr/share/schulkonsole';
use open ':utf8';
use open ':std';
use Schulkonsole::Wrapper;
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::FilesError;



my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

my $opts;
SWITCH: {
	$app_id == Schulkonsole::Config::WRITEFILEAPP and do {
		write_file();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::IMPORTWORKSTATIONSAPP and do {
		import_workstations();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::IMPORTPRINTERSAPP and do {
		import_printers();
		last SWITCH;
	};
}

exit -2;	# program error


=head3 write_file

numeric constant: C<Schulkonsole::Config::WRITEFILEAPP>

=head4 Parameters from standard input

=over

=item file

0 = classrooms, 1 = printers, 2 = workstations, 3 = room_defaults,
5 = preferences.conf, 6 = wlan_defaults

=back

=cut
sub write_file {
	my $file = <>;
	($file) = $file =~ /^(\d+)$/;
	exit (  Schulkonsole::Error::FilesError::WRAPPER_INVALID_FILENUMBER  )
		unless defined $file;

	my $filename;
	my $perm;
	SWITCHWRITEFILE: {
		$file == 0 and do {
			$filename = Schulkonsole::Encode::to_fs(
			            	$Schulkonsole::Config::_classrooms_file);
			last SWITCHWRITEFILE;
		};
		$file == 1 and do {
			$filename = Schulkonsole::Encode::to_fs(
			            	$Schulkonsole::Config::_printers_file);
			last SWITCHWRITEFILE;
		};
		$file == 2 and do {
			$filename = Schulkonsole::Encode::to_fs(
			            	$Schulkonsole::Config::_workstations_file);
			last SWITCHWRITEFILE;
		};
		$file == 3 and do {
			$filename = Schulkonsole::Encode::to_fs(
			            	$Schulkonsole::Config::_room_defaults_file);
			last SWITCHWRITEFILE;
		};
		$file == 5 and do {
			$filename = Schulkonsole::Encode::to_fs(
			            	$Schulkonsole::Config::_preferences_conf_file);
			$perm = 0644 unless -e $filename;
			last SWITCHWRITEFILE;
		};
        $file == 6 and do {
                $filename = Schulkonsole::Encode::to_fs(
                                $Schulkonsole::Config::_wlan_defaults_file);
                $perm = 0644 unless -e $filename;
                last SWITCHWRITEFILE;
        };
	}

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open FILE, '>', $filename
		or exit(  Schulkonsole::Error::FilesError::WRAPPER_CANNOT_OPEN_FILE );
	flock FILE, 2;
	seek FILE, 0, 0;

	while (<>) {
		print FILE;
	}

	if (defined $perm) {
		chmod $perm, $filename;
	}

	close FILE;

	exit 0;
}

=head3 import_workstations

numeric constant: C<Schulkonsole::Config::IMPORTWORKSTATIONSAPP>

=cut

sub import_workstations {
	my $sid = <>;
	($sid) = $sid =~ /^(.+)$/;
	exit (  Schulkonsole::Error::FilesError::WRAPPER_INVALID_SESSION_ID)
		unless defined $sid;

	my $pid = fork;
	exit (  Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK )
		unless defined $pid;

	if (not $pid) {
		close STDIN;

		$< = $>;
		$) = 0;
		$( = $);
		umask(022);
		open STDOUT, ">>", "/dev/null";
		open STDERR, ">>&", *STDOUT;

		my $lockfile = Schulkonsole::Config::lockfile('import_workstations');
		open LOCK, '>>', Schulkonsole::Encode::to_fs($lockfile)
			or exit(  Schulkonsole::Error::FilesError::WRAPPER_CANNOT_OPEN_FILE);
		flock LOCK, 2;
		seek LOCK, 0, 0;
		truncate LOCK, 0;
		print LOCK "$$\n";

		system Schulkonsole::Encode::to_fs(
		     	$Schulkonsole::Config::_cmd_import_workstations);
		close LOCK;
		
		exit 0;
	}
	exit 0;
}

=head3 import_printers

numeric constant: C<Schulkonsole::Config::IMPORTPRINTERSAPP>

=cut

sub import_printers {
	$< = $>;
	$) = 0;
	$( = $);
	umask(022);
	exec Schulkonsole::Encode::to_cli(
	     	$Schulkonsole::Config::_cmd_import_printers)
	     	or exit ( Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED );
}
