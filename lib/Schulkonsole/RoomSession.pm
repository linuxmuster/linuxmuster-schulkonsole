use strict;
use POSIX qw(strftime);
use Digest::MD5;
use Schulkonsole::Config;
use Data::Dumper;
use Safe;
use FileHandle;

=head1 NAME

Schulkonsole::RoomSession - Store session information of a room

=cut

package Schulkonsole::RoomSession;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
);




=head1 DESCRIPTION

=head2 Public Methods

=head3 C<new RoomSession($room)>

=cut

sub new {
	my $class = shift;
	my $room = shift;

	my $this = {
		room => $room,
	};

	bless $this, $class;

	$this->read_session_data();

	return $this;
}




sub param {
	my $this = shift;
	my $param_name = shift;
	my $param_value = shift;

	if ($param_value) {
		$this->{_DATA}{$param_name} = $param_value;
	} else {
		return $this->{_DATA}{$param_name};
	}
}




sub clear {
	my $this = shift;
	my $param_name = shift;

	delete $this->{_DATA}{$param_name}
}




sub read_session_data {
	my $this = shift;

	my $filename = "$Schulkonsole::Config::_runtimedir/room_"
		. Digest::MD5::md5_hex($this->{room});

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


	my $data = Data::Dumper->new([ $this->{_DATA} ]);
	$data->Terse(1);
	$data->Indent(0);

	seek $fh, 0, 0;
	print $fh $data->Dump;

	truncate $fh, tell($fh);

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

#	$this->unlock();
		close $this->{fh};
	}
}






1;
