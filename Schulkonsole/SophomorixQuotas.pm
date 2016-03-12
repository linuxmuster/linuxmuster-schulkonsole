use strict;
use utf8;

use Schulkonsole::Error::SophomorixError;
use Schulkonsole::Wrapper;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::SophomorixError;
use Schulkonsole::Sophomorix;

use Sophomorix::SophomorixAPI;
use Sophomorix::SophomorixConfig;


package Schulkonsole::SophomorixQuotas;

=head1 NAME

Schulkonsole::SophomorixQuotas - interface to Sophomorix quota settings

=head1 SYNOPSIS

 use Schulkonsole::SophomorixQuotas;
 use Schulkonsole::Session;

 my $session = new Schulkonsole::Session('file.cgi');
 my $id = $session->userdata('id');
 my $password = $session->get_password();


 my @mountpoints = Schulkonsole::SophomorixQuotas::mountpoints();

=head1 DESCRIPTION

Schulkonsole::SophomorixQuotas offers commands to change the quota
settings of Sophomorix.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	mountpoints
	split_diskquotas_to_hash
	hash_to_quotastring
	standard_quota
	read_quota_log_file

	read_quota_conf
	write_quota_conf
	new_quota_lines
	
	read_mailquota_conf
	write_mailquota_conf
	new_mailquota_lines

	process_quota
	project_set_quota
	class_set_quota

	is_passwd_user
	
);



our $diskquota_undefined = 'quota';
our $mailquota_undefined = 'mailquota';
our $use_quota = $Conf::use_quota;

my @mountpoints;
my %mountpoints_seen;

my $wrapcmd = $Schulkonsole::Config::_wrapper_sophomorix;
my $errorclass = "Schulkonsole::Error::SophomorixError";

=head2 Functions

=head3 C<mountpoints()>

Get the mountpoints with activated quota

=head4 Return value

An array of the mountpoints

=head4 Description

Returns a list of the mountpoints in the same order as Sophomorix uses them

=cut

sub mountpoints {
	return @mountpoints if @mountpoints;

	if (    @Conf::quota_filesystems
	    and $Conf::quota_filesystems[0] ne 'auto') {
		@mountpoints = @Conf::quota_filesystems;
	} else {
		use Quota;

		Quota::setmntent();
		while (my ($dev, $path, $type, $opts) = Quota::getmntent()) {
			if ($opts =~ /usrquota/) {
			    if (not exists $mountpoints_seen{$dev}){
				push @mountpoints, $path;
				$mountpoints_seen{$dev}="$path";
			    }
			}
		}
		Quota::endmntent();
	}

	return @mountpoints;
}




=head3 C<split_diskquotas_to_hash($diskquota)>

Converts a Sophomorix disk quota string to hash

=head4 Parameters

=over

=item C<$diskquotas>

A disk quota string in the format used by Sophomorix

=back

=head4 Return value

A reference to a hash with mountpoints as keys and quotas as values

=head4 Description

Converts a Sophomorix disk quota string to a hash

=cut

sub split_diskquotas_to_hash {
    my $diskquota = shift;

	my %diskquotas;
	if ($diskquota ne $diskquota_undefined) {
		my @quotas = split /\+(?!\+)/, $diskquota;
		if ($#quotas == $#mountpoints) {
			foreach my $mountpoint (@mountpoints) {
				$diskquotas{$mountpoint} = shift @quotas;
			}
		}
	}

	return \%diskquotas;
}





=head3 C<hash_to_quotastring($diskquotas)>

Converts a hash to a Sophomorix disk quota string

=head4 Parameters

=over

=item C<$diskquotas>

A reference to a hash with mountpoints as keys and quotas as values

=back

=head4 Return value

A disk quota string in the format used by Sophomorix

=head4 Description

Converts a hash to a Sophomorix disk quota string.

=cut

sub hash_to_quotastring {
	my $diskquotas = shift;
	return $diskquota_undefined unless $diskquotas and %$diskquotas;
	my $defaults = shift;

	my $is_defined = 0;
	foreach my $mountpoint (@mountpoints) {
		if  (length $$diskquotas{$mountpoint}) {
			$is_defined++;
			last if $defaults;
		}
	}
	return $diskquota_undefined unless $is_defined;

	die new Schulkonsole::Error::SophomorixError(Schulkonsole::Error::SophomorixError::QUOTA_NOT_ALL_MOUNTPOINTS)
		unless ($defaults or $is_defined == @mountpoints);


	my @diskquotas;
	foreach my $mountpoint (@mountpoints) {
		push @diskquotas,
		     (defined $$diskquotas{$mountpoint} ?
		      $$diskquotas{$mountpoint} :
		      (defined $$defaults{$mountpoint} ? $$defaults{$mountpoint} : 0));
	}


	return join '+', @diskquotas;
}




=head3 C<standard_quota($group)>

Get the standard disk quota of a group

=head4 Parameters

=over

=item C<$group>

A group name

=back

=head4 Return value

A reference to a hash as returned by split_diskquotas_to_hash()

=head4 Description

Reads the standard quota of the group C<$group> from C<quota.txt>.

=cut

sub standard_quota {
	my $group = shift;
	my $re;


	if (open QUOTACONF, "<$DevelConf::config_pfad/quota.txt") {
		flock QUOTACONF, 1;

		while (<QUOTACONF>) {
			chomp;
			s/\s+//g;
			next if (not $_ or /^#/);

			my ($user, $quota) = /^(standard-$group)\s*:\s*(\d.*)$/;

			if ($user) {
				$re = split_diskquotas_to_hash($quota);
				last;
			}
		}

		close QUOTACONF;


	} else {
		print STDERR "Cannot open $DevelConf::config_pfad/quota.txt\n";
	}

	return $re;
}




=head3 C<standard_mailquota($group)>

Get the standard mail quota of a group

=head4 Parameters

=over

=item C<$group>

A group name

=back

=head4 Return value

The standard mail quota

=head4 Description

Reads the standard mail quota of the group C<$group> from C<mailquota.txt>.

=cut

sub standard_mailquota {
    my $group = shift;
    my $re;


    if (open QUOTACONF, "<$DevelConf::config_pfad/mailquota.txt") {
        flock QUOTACONF, 1;

        while (<QUOTACONF>) {
            chomp;
            s/\s+//g;
            next if (not $_ or /^#/);

            my ($user, $mailquota) = /^(standard-$group)\s*:\s*(\d.*)$/;

            if ($user) {
                $re = $mailquota;
                last;
            }
        }

        close QUOTACONF;


    } else {
        print STDERR "Cannot open $DevelConf::config_pfad/mailquota.txt\n";
    }

    return $re;
}



=head3 C<read_quota_log_file($id, $password)>

Read last of quota log files

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the log file

=head4 Description

Reads the last file of the sorted list of
sophomorix-quota.txt.* log files, i.e. the newest.

=cut

sub read_quota_log_file {
	return Schulkonsole::Sophomorix::read_file(@_, 12);
}


=head3 C<process_quota($id, $password, $scope)>

Processes the changes in quota

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$scope>

bitwise or: 1 = set quota,
2 = set quota for teachers,
4 = set quota for students

=back

=head4 Description

This wraps the command
C<sophomorix-quota [--set] [--teachers] [--students]> and uses the options
corresponding to C<$scope>

=cut

sub process_quota {
	my $id = shift;
	my $password = shift;
	my $scope = shift;

	return unless $scope;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETQUOTAAPP,
		$id, $password,
		"$scope\n");
}

=head3 C<class_set_quota($id, $password, $gid, $diskquota, $mailquota)>

Set quotas for class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

name of the class

=item C<diskquota>

diskquotas separated with '+' or undef

=item C<mailquota>

mailquota or undef

=back

=head4 Description

This wraps the commands
C<sophomorix-class --class name --quota diskquota --mailquota mailquota>,
where name is C<$class>, diskquota is C<$diskquota> and mailquota is
C<mailquota>.

=cut

sub class_set_quota {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $diskquota = shift;
	my $mailquota = shift;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETQUOTAAPP,
		$id, $password,
		"16\n$class\n$diskquota\n$mailquota\n");
}




=head3 C<project_set_quota($id, $password, $gid, $diskquota, $mailquota)>

Set quotas for project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

name of the project

=item C<diskquota>

diskquotas separated with '+' or undef

=item C<mailquota>

mailquota or undef

=back

=head4 Description

This wraps the commands
C<sophomorix-project --caller caller --project name --quota diskquota --mailquota mailquota>,
where
caller is the UID of the user with the ID C<$id>,
name is C<$project>, diskquota is C<$diskquota> and mailquota is
C<mailquota>.

=cut

sub project_set_quota {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $diskquota = shift;
	my $mailquota = shift;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETQUOTAAPP,
		$id, $password,
		"17\n$project\n$diskquota\n$mailquota\n");
}


=head3 C<write_quota_conf($id, $password, $lines)>

Write new quota.txt

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

Writes the file /etc/sophomorix/user/quota.txt and backups the old
file

=cut

sub write_quota_conf {
	Schulkonsole::Sophomorix::write_file(@_, 3);
}




=head3 C<write_mailquota_conf($id, $password, $lines)>

Write new mailquota.txt

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

Writes the file /etc/sophomorix/user/mailquota.txt and backups the old
file

=cut

sub write_mailquota_conf {
	Schulkonsole::Sophomorix::write_file(@_, 4);
}



sub read_quota_conf {
	my %re;


	if (open QUOTACONF, '<',
	         Schulkonsole::Encode::to_fs("$DevelConf::config_pfad/quota.txt")) {
		flock QUOTACONF, 1;

		while (<QUOTACONF>) {
			chomp;
			s/\s+//g;
			next if (not $_ or /^#/);

			my ($user, $quota) = /^(\S+)\s*:\s*(\d.*)$/;

			next if (not $user or $user =~ /^standard-/);


			$re{$user}{diskquotas} =
				Schulkonsole::SophomorixQuotas::split_diskquotas_to_hash(
					$quota);
		}

		close QUOTACONF;


	} else {
		print STDERR "Cannot open $DevelConf::config_pfad/quota.txt\n";
	}


	if (open MAILQUOTACONF, '<',
	         Schulkonsole::Encode::to_fs(
	         	"$DevelConf::config_pfad/mailquota.txt")) {
		flock MAILQUOTACONF, 1;

		while (<MAILQUOTACONF>) {
			chomp;
			s/\s+//g;
			next if (not $_ or /^#/);

			my ($user, $mailquota) = /^(\S+)\s*:\s*(\d.*)$/;

			next if (not $user or $user =~ /^standard-/);


			$re{$user}{mailquota} = $mailquota;
		}

		close QUOTACONF;

	} else {
		print STDERR "Cannot open $DevelConf::config_pfad/mailquota.txt\n";
	}


	return \%re;
}




sub new_quota_lines {
	my $new = shift;


	my %new;
	foreach my $key (keys %$new) {
		$new{$key} = Schulkonsole::SophomorixQuotas::hash_to_quotastring(
				$$new{$key}{diskquotas})
			if $$new{$key}{diskquotas};
	}

	my @lines;
	if (open QUOTACONF, '<',
	         Schulkonsole::Encode::to_fs("$DevelConf::config_pfad/quota.txt")) {

		while (my $line = <QUOTACONF>) {
			foreach my $key (keys %new) {
				if ($line =~ /^\s*#?\s*$key\s*:/) {
					if ($new{$key} eq $Schulkonsole::SophomorixQuotas::diskquota_undefined) {
						$line = "#$line";
					} else {
						$line = "$key: $new{$key}\n";
					}
					delete $new{$key};

					last;
				}
			}
			push @lines, $line;
		}
	}

	if (%new) {
		#push @lines, "# schulkonsole\n";

		my $line;
		foreach my $key (keys %new) {
			push @lines, "$key: $new{$key}\n";
		}
	}


	return \@lines;
}




sub new_mailquota_lines {
	my $new = shift;


	my %new;
	foreach my $key (keys %$new) {
		$new{$key} = $$new{$key}{mailquota}
			if $$new{$key}{mailquota};
	}

	my @lines;
	if (open QUOTACONF, '<',
	         Schulkonsole::Encode::to_fs(
	         	"$DevelConf::config_pfad/mailquota.txt")) {

		while (my $line = <QUOTACONF>) {
			foreach my $key (keys %new) {
				if ($line =~ /^\s*#?\s*$key\s*:/) {
					if (   $new{$key} == -1
					    or $new{$key} eq $Schulkonsole::SophomorixQuotas::mailquota_undefined) {
						$line = "#$line";
					} else {
						$line = "$key: $new{$key}\n";
					}
					delete $new{$key};

					last;
				}
			}
			push @lines, $line;
		}
	}

	if (%new) {
		my $line;
		foreach my $key (keys %new) {
			push @lines, "$key: $new{$key}\n" unless $new{$key} == -1
		}
	}


	return \@lines;
}




sub is_passwd_user {
	my $login = shift;

	open PASSWD, '<', '/etc/passwd' or return 0;
	while (<PASSWD>) {
		my ($name) = split ':';

		return 1 if $name eq $login;
	}
	close PASSWD;


	return 0;
}

1;
