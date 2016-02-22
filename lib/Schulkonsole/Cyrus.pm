use strict;
use utf8;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error::Error;
use Schulkonsole::Error::CyrusError;
use Schulkonsole::Config;
use Safe;


package Schulkonsole::Cyrus;

=head1 NAME

Schulkonsole::Cyrus - interface to Cyrus commands

=head1 SYNOPSIS

 use Schulkonsole::Cyrus;

 Schulkonsole::Cyrus::quota(@users);

=head1 DESCRIPTION

Schulkonsole::Cyrus is an interface to Cyrus commands used
by schulkonsole.

If a wrapper command fails, it usually dies with a Schulkonsole::Error::CyrusError.
The output of the failed command is stored in the Schulkonsole::Error::CyrusError.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	quota
);

my $errorclass = "Schulkonsole::Error::CyrusError";
my $wrapcmd = $Schulkonsole::Config::_cmd_wrapper_cyrus;



=head2 Functions

=head3 C<quota(@users)>

Returns users' IMAP quotas

=head4 Parameters

=over

=item C<@users>

The usernames on the IMAP server

=back

=head4 Return value

A reference to a hash of the form C<< $username =>  quotaroot >>, where
C<$username> is the user's name on the IMAP server and
quotaroot is a hash with the quotaroot as key and a reference to the
following hash structure as a value:

=over

=item C<< quota => STORAGE => usage >>

	the quota usage

=item C<< quota => STORAGE => limit >>

	the quota limit

=item C<mbox>

	a reference to an array of the quota's mailboxes

=back

=head4 Description

Returns the quotas of the users C<@users>.

=cut

sub quota {
	my $user = shift;
	my $password = shift;
	my @users = @_;

	my %user_quotaroots;

	return {} unless @users;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::CYRUSQUOTAAPP, $user, $password,
			join("\n", @users) . "\n\n", Schulkonsole::Wrapper::MODE_FILE);

	foreach (split('\R', $in)) {
		if (my ($limit, $usage_percent, $usage, $user)
		    	= /^\s*(\d+)\s+(\d+)\s+(\d+)\s+user\.(.+)/) {
			$user_quotaroots{$user}{"user.$user"}{quota}{STORAGE}{usage}
				= $usage;
			$user_quotaroots{$user}{"user.$user"}{quota}{STORAGE}{limit}
				= $limit;
			$user_quotaroots{$user}{"user.$user"}{mbox} = [ 'INBOX' ];
		}
	}

	return \%user_quotaroots;
}






1;
