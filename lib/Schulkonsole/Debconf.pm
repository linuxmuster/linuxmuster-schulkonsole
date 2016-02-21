use strict;
use utf8;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Wrapper;
use Schulkonsole::Error::DebconfError;
use Schulkonsole::Config;


package Schulkonsole::Debconf;

=head1 NAME

Schulkonsole::Debconf - interface to read debconf section/values

=head1 SYNOPSIS

 use Schulkonsole::Debconf;
 use Schulkonsole::Session;

 my $session = new Schulkonsole::Session('file.cgi');
 my $id = $session->userdata('id');
 my $password = $session->get_password();


 Schulkonsole::Debconf::read($id, $password,
 	'linuxmuster-base','internsubmask');

 Schulkonsole::Debconf::read_smtprelay($id, $password);

=head1 DESCRIPTION

Schulkonsole::Debconf is an interface to read debconf values with root premissions

If a wrapper command fails, it usually dies with a Schulkonsole::Error::DebconfError.
The output of the failed command is stored in the Schulkonsole::Error::DebconfError.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	read
);

my $wrapcmd = $Schulkonsole::Config::_wrapper_debconf;
my $errorclass = "Schulkonsole::Error::DebconfError";

=head2 Functions

=head3 C<read($id, $password, $section, $name)>

Read and return a debconf value.

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$section>

The debconf section to read the value from.

=item C<$name>

The debconf name for the variable to read the value from.

=head4 Output

Return the value.

=back

=head4 Description

Read the value C<$name> specified in C<$section> from the
debconf database.

=cut

sub read {
	my $id = shift;
	my $password = shift;
	my $section = shift;
	my $name = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::DEBCONFREADAPP,
										$id, $password, "$section\n$name\n", Schulkonsole::Wrapper::MODE_FILE);

	my $value;
	while my $line (split('\R', $in)) {
		($ret,$value) = $line =~ /^(\d+)\s+([a-zA-Z\d\-]+)$/;
		next if not defined $ret;
		die new Schulkonsole::Error::DebconfError(
			Schulkonsole::Error::DebconfError::WRAPPER_INVALID_REQUEST,
			$Schulkonsole::Config::_wrapper_debconf, $!,
			    "debconf-communicate error $ret")
			unless $ret == 0;
	}

	return $value;
}


=head3 C<read_smtprelay($id, $password)>

Read and return the debconf value linuxmuster-base/smtprelay.

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=head4 Output

Return the linuxmuster-base/smtprelay value.

=back

=head4 Description

Read the value C<linuxmuster-base/smtprelay> from the
debconf database.

=cut

sub read_smtprelay {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::DEBCONFREADSMTPRELAYAPP,
										$id, $password, "\n",Schulkonsole::Wrapper::MODE_FILE);

	my $ret;
	my $value;
	while my $line (split('\R', $in)) {
		($ret,$value) = $_ =~ /^(\d+)\s+([a-zA-Z\d\-\.]+)$/;
		next if not defined $ret;
		die new Schulkonsole::Error::DebconfError(
			Schulkonsole::Error::DebconfError::WRAPPER_INVALID_REQUEST,
			$Schulkonsole::Config::_wrapper_debconf, $!,
			    "debconf-communicate error $ret")
			unless $ret == 0 || $ret == 10;
	}

	if($ret == 0) {
	    return $value;
	} else {
	    return "";
	}
}



1;
