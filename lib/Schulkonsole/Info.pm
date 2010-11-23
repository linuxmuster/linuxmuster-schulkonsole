use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Net::IMAP::Simple;
use Schulkonsole::Config;
use Schulkonsole::Error;

=head1 NAME

Schulkonsole::Info - get info about users

=cut

package Schulkonsole::Info;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.05;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	disk_quotas
	mail_quotas
	mailaliases
	workstation_users
	groups_classes
	groups_projects
);


=head1 DESCRIPTION

=head2 Public Functions

=head3 C<disk_quotas($uidnumber)>

=cut

sub disk_quotas {
	my $uidnumber = shift;

	my $pid = IPC::Open3::open3 \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN,
		$Schulkonsole::Config::_wrapper_user
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_user, $!);

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
	    my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_wrapper_user, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_USER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_user);
		}
	}


	print SCRIPTOUT "$uidnumber\n", Schulkonsole::Config::QUOTAAPP, "\n";

	close SCRIPTOUT
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_wrapper_user, $!);

	my @quotas;
	while (<SCRIPTIN>) {
		chomp;
		my @quota = split "\t";
		next unless defined $quota[8];

		push @quotas, \@quota;
	}
	$re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
	    my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::Config::_wrapper_user, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_USER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_user);
		}
	}

	close SCRIPTIN
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_user, $!);


	return \@quotas;
}



=head3 C<mail_quotas($username, $password)>

=cut

sub mail_quotas {
	my $username = shift;
	my $password = shift;

	my $imap = new Net::IMAP::Simple($Schulkonsole::Config::_imap_host)
		or die "Connection to $Schulkonsole::Config::_imap_host failed\n";

	$imap->login($username, $password) or die($imap->errstr, "\n");

	my $quotas = getallquota($imap);

	quit_no_expunge($imap);


	return $quotas;
}




=head3 C<member_projects($groups)>

=cut

sub groups_projects {
	my $groups = shift;

	return Schulkonsole::DB::groups_projects($groups);
}




=head3 C<groups_classes($groups)>

=cut

sub groups_classes {
	my $groups = shift;

	my $classs = Schulkonsole::DB::groups_classes($groups);
	delete $$classs{'attic'};


	return $classs;
}




=head3 C<mailaliases($username)>

=cut

sub mailaliases {
	my $username = shift;
	my %aliass;

	local *get_aliases = sub {
		my $aliased = shift;

		return unless $aliass{$aliased};

		my @aliass = @{ $aliass{$aliased} };
		my @re = @aliass;
		delete $aliass{$aliased};

		foreach my $alias (@aliass) {
			push @re, get_aliases($alias);
		}


		return @re;
	};



	my $aliases_file = '/etc/aliases';

	open ALIASES, "<$aliases_file"
		or die "$0: Cannot open $aliases_file: $!\n";

	my @lines;
	while (<ALIASES>) {
		next if /^#/;

		if (/^\s./) {
			chomp $lines[-1];
			$lines[-1] .= $_;
		} elsif (/:/) {
			push @lines, $_;
		}
	}

	close ALIASES;

	foreach my $line (@lines) {
		my ($alias, $aliaseds) = $line =~ /^(.*?):\s*(.+?)\s*$/;
		$alias = lc $alias;
		foreach my $aliased (split /\s*,\s*/, $aliaseds) {
			if ($aliass{$aliased}) {
				push @{ $aliass{$aliased} }, $alias;
			} else {
				$aliass{$aliased} = [ $alias ];
			}
		}
	}

	return get_aliases($username);
}











sub getquotaroot {
	my ( $self, $mbox ) = @_;

	$mbox = 'INBOX' unless $mbox;

	my $t_mbox = $mbox;

	$self->_process_cmd(
		cmd	 => [GETQUOTAROOT => Net::IMAP::Simple::_escape($t_mbox)],
		final   => sub { 1 },
		process => sub {
			if($_[0] =~ /^\*\s+QUOTAROOT\s+$mbox(?:\s+(.*?))?\s*$/i){
				$self->{BOXES}->{$mbox}->{quotaroot} = [ split /\s+/, $1 ];
			} elsif($_[0] =~ /^\*\s+QUOTA\s+(.+?)\s+\(\s*(\S+)\s+(\d+)\s+(\d+)\s*\)/i){
				$self->{QUOTA}{$1}{$2}{usage} = $3;
				$self->{QUOTA}{$1}{$2}{limit} = $4;
			}
		}
	);

	return $self->{QUOTA}{$self->{BOXES}{$mbox}{quotaroot}[0]};
}



sub getallquota {
	my ( $self ) = @_;

	my %quotaroots;

	foreach my $mbox ($self->mailboxes) {
		my $quota = getquotaroot($self, $mbox);

		foreach my $quotaroot (@{ $self->{BOXES}{$mbox}{quotaroot} }) {
			if ($quotaroots{$quotaroot}) {
				push @{ $quotaroots{$quotaroot}{mbox} }, $mbox;
			} else {
				$quotaroots{$quotaroot}{quota} = $quota;
				$quotaroots{$quotaroot}{mbox} = [ $mbox ];
			}
		}
	}

	return \%quotaroots;
}



sub quit_no_expunge {
	my ( $self, $hq ) = @_;

	if(!$hq){
		$self->_process_cmd(cmd => ['LOGOUT'], final => sub {}, process => sub{});
	} else {
		$self->_send_cmd('LOGOUT');
	}

	$self->_sock->close;
	return 1;
}






1;
