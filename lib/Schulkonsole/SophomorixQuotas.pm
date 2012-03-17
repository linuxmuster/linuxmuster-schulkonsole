use strict;
use Schulkonsole::Error;
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
);



our $diskquota_undefined = 'quota';
our $mailquota_undefined = 'mailquota';

my @mountpoints;


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
				push @mountpoints, $path;
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

	die new Schulkonsole::Error(Schulkonsole::Error::QUOTA_NOT_ALL_MOUNTPOINTS)
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








1;
