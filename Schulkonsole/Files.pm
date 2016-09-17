use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Wrapper;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::FilesError;
use Schulkonsole::Config;


package Schulkonsole::Files;

=head1 NAME

Schulkonsole::Files - interface to read and write files

=head1 SYNOPSIS

 use Schulkonsole::Files;
 use Schulkonsole::Session;

 my $session = new Schulkonsole::Session('file.cgi');
 my $id = $session->userdata('id');
 my $password = $session->get_password();


 Schulkonsole::Files::write_classrooms_file($id, $password,
 	[ 'Dining-Room', 'Hall' ]);

=head1 DESCRIPTION

Schulkonsole::Files is an interface to write files with root premissions

If a wrapper command fails, it usually dies with a Schulkonsole::Error::FilesError.
The output of the failed command is stored in the Schulkonsole::Error::FilesError.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	write_classrooms_file
	write_printers_file
	write_workstations_file
	write_room_defaults_file
	write_preferences_conf_file
        write_group_defaults_file
	import_printers
	import_workstations
	read_import_log_file
);


my $wrapcmd = $Schulkonsole::Config::_wrapper_files;
my $errorclass = "Schulkonsole::Error::FilesError";


=head2 Functions

=cut

#sub read_file {
#	my $id = shift;
#	my $password = shift;
#	my $file_number = shift;
#
#	my $pid = start_wrapper(Schulkonsole::Config::READFILEAPP,
#		$id, $password,
#		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
#
#	print SCRIPTOUT "$file_number\n";
#
#	my @re;
#	while (<SCRIPTIN>) {
#		push @re, $_;
#	}
#
#
#	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
#
#
#	return \@re;
#}




sub write_file {
	my $id = shift;
	my $password = shift;
	my $lines = shift;
	my $file_number = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::WRITEFILEAPP,
						$id, $password,
						"$file_number\n" . join('', @$lines));
}




=head3 C<write_classrooms_file($id, $password, $lines)>

Write new classrooms file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/linuxmuster/classrooms

=cut

sub write_classrooms_file {
	write_file(@_, 0);
}




=head3 C<write_printers_file($id, $password, $lines)>

Write new printers file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/linuxmuster/printers

=cut

sub write_printers_file {
	write_file(@_, 1);
}




=head3 C<write_workstations_file($id, $password, $lines)>

Write new workstations file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/linuxmuster/workstations

=cut

sub write_workstations_file {
	write_file(@_, 2);
}




=head3 C<write_room_defaults_file($id, $password, $lines)>

Write new room_defaults file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/linuxmuster/room_defaults

=cut

sub write_room_defaults_file {
	write_file(@_, 3);
}




=head3 C<write_preferences_conf_file($id, $password, $lines)>

Write new preferences.conf

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/linuxmuster/schulkonsole/preferences.conf

=cut

sub write_preferences_conf_file {
	write_file(@_, 5);
	Schulkonsole::Config::init_preferences();
}




=head3 C<write_wlan_defaults_file($id, $password, $lines)>

Write new group_defaults file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/linuxmuster/group_defaults

=cut

sub write_wlan_defaults_file {
        write_file(@_, 6);
}




=head3 C<import_workstations($id, $password)>

Import workstations

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Description

This wraps the command C<import_workstations>

=cut

sub import_workstations {
	my $id = shift;
	my $password = shift;
	my $sk_session = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::IMPORTWORKSTATIONSAPP,
					      $id, $password,
					      $sk_session->session_id() . "\n");
}




=head3 C<read_import_log_file($id, $password)>

Read last import_workstations log file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the log file

=head4 Description

Reads the sorted list of
/var/tmp/import_workstations.log if existing otherwise
/var/log/linuxmuster/import_workstations.log, i.e. the newest.

=cut

sub read_import_log_file {
        my @re;

        if (open IMPORTLOG, '<', Schulkonsole::Encode::to_fs(
                $Schulkonsole::Config::_workstations_tmp_log_file)) {
            while (<IMPORTLOG>) {
                    push @re, $_;
            }
            close IMPORTLOG;
        } elsif (open IMPORTLOG, '<', Schulkonsole::Encode::to_fs(
                $Schulkonsole::Config::_workstations_log_file)) {
            while (<IMPORTLOG>) {
                    push @re, $_;
            }
            close IMPORTLOG;
        } else {
                warn "$0: Cannot open "
                    . $Schulkonsole::Config::_workstations_tmp_log_file
                    . " nor "
                    . $Schulkonsole::Config::_workstations_log_file
                    . ": $!\n";
        }
        
        return \@re;
}

=head3 C<import_printers($id, $password)>

Import printers

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Description

This wraps the command C<import_printers>

=cut

sub import_printers {
	my $id = shift;
	my $password = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::IMPORTPRINTERSAPP,
					      $id, $password);
}


1;
