use strict;
use Schulkonsole::Config;
use Schulkonsole::Sophomorix;
use Data::Dumper;
use Safe;
use FileHandle;

package Schulkonsole::TeachIn;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.05;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
);




=head1 DESCRIPTION

=head2 Public Methods

=head3 C<new TeachIn($room)>

=cut

sub new {
	my $class = shift;

	my $this = {
	};

	bless $this, $class;

	$this->read_session_data();

	return $this;
}




sub read {
	my $this = shift;
	my $id = shift;
	my $password = shift;

	if (Schulkonsole::Sophomorix::teachin_check($id, $password)) {
		my $backup = $this->{_DATA}{users};
		$this->{_DATA}{users} = Schulkonsole::Sophomorix::teachin_list(
			$id, $password);

		my $users = $this->{_DATA}{users};
		foreach my $user (keys %$users) {
			if (exists $$backup{$user}) {
				my $selected = $$backup{$user}{selected};
				$$users{$user}{selected} = $selected if exists
					$$users{$user}{alt}{$selected};
			}
		}
	} else {
		$this->{_DATA}{users} = {};
	}
}



sub is_read {
	my $this = shift;

	return (    defined $this->{_DATA}
	        and defined $this->{_DATA}{users});
}



sub users {
	my $this = shift;

	if ($this->is_read()) {
		return $this->{_DATA}{users};
	} else {
		return {};
	}
}



sub user_select_alt {
	my $this = shift;
	my $username = shift;
	my $alt = shift;

	$this->{_DATA}{users}{$username}{selected} = $alt;
}



sub user_delete {
	my $this = shift;
	my $username = shift;
	my $alt = shift;

	undef $this->{_DATA}{users}{$username}{selected};
}



sub read_session_data {
	my $this = shift;

	my $filename = "$Schulkonsole::Config::_runtimedir/teachin";

	$this->{filename} = $filename;

	   open SESSION, "+<$filename"
	or open SESSION, "+>$filename"
	or die "$0: Cannot open $filename: $!\n";

	SESSION->autoflush(1);
	$this->{fh} = *SESSION;

	$this->lock();
}




sub write_session_data {
	my $this = shift;

	my $fh = $this->{fh};
	seek $fh, 0, 0;
	truncate $fh, tell($fh);

	if (defined $this->{_DATA}) {
		my $data = Data::Dumper->new([ $this->{_DATA} ]);
		$data->Terse(1);
		$data->Indent(0);

		print $fh $data->Dump;

	} else {
		$this->delete();
	}

}




sub lock {
	my $this = shift;

	my $fh = $this->{fh};

	flock $fh, 2;

	seek $fh, 0, 0;

	my $in;
	{
		local $/ = undef;
		$in = <$fh>;
	}

	if ($< != $>) {
		($in) = $in =~ /(.*)/;
	}
	my $compartment = new Safe;
	$this->{_DATA} = $compartment->reval($in);
}




sub unlock {
	my $this = shift;

	my $fh = $this->{fh};

	$this->write_session_data();

	flock $fh, 8;
}




sub delete {
	my $this = shift;

	unlink $this->{filename} if -e $this->{filename};
	close $this->{fh};

	$this->{_DATA} = {};
	$this->{deleted} = 1;
}




sub DESTROY {
	my $this = shift;

	if (not $this->{deleted}) {
		$this->write_session_data();

#		$this->unlock();
		close $this->{fh};
	}
}






1;
