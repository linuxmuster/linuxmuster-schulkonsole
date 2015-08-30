use strict;
use utf8;
use Encode;

=head1 NAME

Schulkonsole::Encode - encoding/decoding of strings

=head1 SYNOPSIS

 system Schulkonsole::Encode::to_cli($cmd);
 unlink Schulkonsole::Encode::to_fs($cmd);

=head1 DESCRIPTION

Provides commands to encode strings from internal Perl encoding to proper 
encoding used by command line programs and filesystem.

=head2 Functions

=cut

package Schulkonsole::Encode;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.09;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	to_cli
	to_fs
	from_fs
);




=head3 C<to_cli($str)>

Encodes string for command line interface.

=head4 Parameters

=over

=item C<$str>

String to encode

=back

=head4 Description

Uses the standard encoding to encode string for use with e.g. C<system()> 
or C<exec()> (i.e. UTF-8).

Note that you have to encode file names separately if file system encoding 
differs from this encoding.

=cut

sub to_cli {
	return Encode::encode('utf8', shift);
}




=head3 C<to_fs($str)>

Encodes string for filesystem.

=head4 Parameters

=over

=item C<$str>

String to encode

=back

=head4 Description

Uses the standard encoding to encode string to encoding used in filesystem 
(i.e. UTF-8).

=cut

sub to_fs {
	return Encode::encode('utf8', shift);
}



=head3 C<from_fs($str)>

Decodes string from filesystem.

=head4 Parameters

=over

=item C<$str>

String to decode

=back

=head4 Description

Uses the standard encoding to decode string from encoding used in filesystem 
(i.e. UTF-8).

=cut

sub from_fs {
	return Encode::decode('utf8', shift);
}






1;
