use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Wrapper;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::PrinterError;
use Schulkonsole::Config;

=head1 NAME

Schulkonsole::Printer - access printing system

=cut

package Schulkonsole::Printer;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	printer_info
	printer_on
	printer_off
	printer_deny
);


my $wrapcmd = $Schulkonsole::Config::_wrapper_printer;
my $errorclass = "Schulkonsole::Error::PrinterError";


=head2 C<printer_info($id, $password)>

Return information about configured printers

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Return value

A reference to a hash with printer names as keys and a reference to a
hash with the information as values. The information for the keys
State, StateMessage, Info, Location, and Accepting are scalar values.
The values for AllowUser and DenyUser are references to hashes with
usernames as keys.

=head3 Description

Execute the command lpstat, parse and return the information.

=cut

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub printer_info {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::PRINTERINFOAPP,
		$id, $password,"",Schulkonsole::Wrapper::MODE_LINES);

	my %printers = ();
	my %printer = ();
	my $pname;
	
	my @in = split('\R', $in);
	while(@in) {#
		$_ = shift @in;
		chomp;
		if (/^printer /){
			if ($pname) {
				$printers{$pname}={%printer};
			}
			%printer = ();
			my @line = split(' ');
			$pname = $line[1];
			if ($line[3] =~ /idle/) {
				$printer{'State'}='Idle';
			} else {
				$printer{'State'}='Busy';
			}
			$printer{'Accepting'}='Yes';
		} elsif (/^\tDescription:/) {
			my @line = split(':');
			$printer{'Info'}=trim($line[1]);
		} elsif (/^\tLocation:/) {
			my @line = split(':');
			$printer{'Location'}=trim($line[1]);
		} elsif (/^\tRejecting Jobs/) {
			$printer{'Accepting'}='No';
		} elsif (/^\tUsers allowed:/) {
			$_ = shift @in;
			chomp;
			if (/\(all\)/) {
				$printer{'Deny'}='None';
			} elsif (/\(none\)/) {
				$printer{'Deny'}='All';
			} else {
				$printer{'Allow'}=trim($_);
			}
		}
	}
	if ($pname) {
		$printers{$pname}={%printer};
	}

	return \%printers;
}




=head2 C<printer_on($id, $password, $printers)>

Turn accepting of print jobs on

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$printers>

A reference to an array of printers

=back

=head3 Description

This wraps the command C</usr/sbin/accept printer1 printer2,...>
where C<printer1>, C<printer2> are the printers in C<$printers>.

=cut

sub printer_on {
	my $id = shift;
	my $password = shift;
	my $printers = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::PRINTERONOFFAPP,
		$id, $password, "1\n" . join("\n", @$printers) . "\n\n");

}




=head2 C<printer_off($id, $password, $printers)>

Turn accepting of print jobs off

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$printers>

A reference to an array of printers

=back

=head3 Description

This wraps the command C</usr/sbin/reject printer1 printer2,...>
where C<printer1>, C<printer2> are the printers in C<$printers>.

=cut

sub printer_off {
	my $id = shift;
	my $password = shift;
	my $printers = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::PRINTERONOFFAPP,
		$id, $password, "0\n" . join("\n", @$printers) . "\n\n");

}





=head2 C<printer_deny($id, $password, $printer_users)>

Deny users access to printers

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$printer_users>

A reference to hash with printer names as keys and a reference to an array
of users to be denied access to this printer as value

=back

=head3 Description

This wraps commands C</usr/sbin/lpadmin -pprinter -u deny:user1,user2,...>
for each printer in C<keys %$printer_users> and C<user1>, C<user2> the
users in C<$$printer_users{$printer}>.

=cut

sub printer_deny {
	my $id = shift;
	my $password = shift;
	my $printer_users = shift;

	my $out = "";
	foreach my $printer (keys %$printer_users) {
		$out .= "$printer\n" . join("\n", @{ $$printer_users{$printer} }, '') . "\n";
	}

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::PRINTERALLOWDENYAPP,
		$id, $password, "$out\n");

}



1;
