#! /usr/bin/perl

=head1 NAME

wrapper-printer.pl - wrapper for printer access

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::PRINTERINFOAPP;

 open SCRIPT, "| $Schulkonsole::Config::_wrapper_printer";
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id

 INPUT

=head1 DESCRIPTION

=cut

use strict;
use lib '/usr/share/schulkonsole';
use open ':utf8';
use open ':std';
use Schulkonsole::Wrapper;
use Data::Dumper;
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::PrinterError;



my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

my $opts;
SWITCH: {
    $app_id == Schulkonsole::Config::PRINTERINFOAPP and do {
	printer_info();
	last SWITCH;
    };

    $app_id == Schulkonsole::Config::PRINTERONOFFAPP and do {
	printer_on_off();
	last SWITCH;
    };

    $app_id == Schulkonsole::Config::PRINTERALLOWDENYAPP and do {
	printer_allow_deny();
	last SWITCH;
    };

};

exit -2;	# program error


=head3 printer_info

numeric constant: C<Schulkonsole::Config::PRINTERINFOAPP>

=head4 Description

Dumps code to be C<eval>ed to a hash with the printer names as keys an
as value a hash with configuration variable names as keys an their values
as values.

=head4 Parameters from standard input

none

=cut

sub printer_info {
	$< = $>;
	system Schulkonsole::Encode::to_cli(
	       	"$Schulkonsole::Config::_cmd_printer_info -l -p");

	exit 0;
}

=head3 printer_on_off

numeric constant: C<Schulkonsole::Config::PRINTERONOFFAPP>

=head4 Description

Set printers to accept/reject jobs.

=head4 Parameters from standard input

=over

=item on

C<1> (accept) or C<0> (reject)

=item printers

Printer names, one per line, end with empty line

=back

=cut

sub printer_on_off {
	my $on = <>;
	($on) = $on =~ /^(\d)$/;

	my @printers;
	while (my $printer = <>) {
		last if $printer =~ /^$/;

		($printer) = $printer =~ /^(\S{0,127})$/;
		exit (  Schulkonsole::Error::PrinterError::WRAPPER_INVALID_PRINTER_NAME
		      )
			unless $printer;

		push @printers, $printer
	}
	exit (  Schulkonsole::Error::PrinterError::WRAPPER_NO_PRINTERS
	      )
		unless @printers;

	$< = $>;
	if ($on) {
		foreach my $printer (@printers) {
			system Schulkonsole::Encode::to_cli(
			       	"$Schulkonsole::Config::_cmd_printer_accept \Q$printer\E");
		}
	} else {
		foreach my $printer (@printers) {
			system Schulkonsole::Encode::to_cli(
			       	"$Schulkonsole::Config::_cmd_printer_reject \Q$printer\E");
		}
	}


	exit 0;
}

=head3 printer_allow_deny

numeric constant: C<Schulkonsole::Config::PRINTERALLOWDENYAPP>

=head4 Description

Set printers to deny user access to specified users

=head4 Parameters from standard input

=over

=item printer + users

Printer name followed by UIDs one per line.
End users list with empty line.

Continue with next printer name followed by UIDs.

Finish with additional empty line.

=back

=cut

sub printer_allow_deny {
	my %printer_users;

	while (my $printer = <>) {
		last if $printer =~ /^$/;
		($printer) = $printer =~ /^(\S{0,127})$/;
		exit (  Schulkonsole::Error::PrinterError::WRAPPER_INVALID_PRINTER_NAME
		      )
			unless $printer;

		$printer_users{$printer} = [];
		while (my $user = <>) {
			last if $user =~ /^$/;
			($user) = $user =~ /^(.+)$/;
			exit (  Schulkonsole::Error::PrinterError::WRAPPER_INVALID_USER
			      )
				unless $user;

			push @{ $printer_users{$printer} }, "\Q$user";
		}
	}
	exit (  Schulkonsole::Error::PrinterError::WRAPPER_NO_PRINTERS
	      )
		unless %printer_users;

	$< = $>;
	foreach my $printer (keys %printer_users) {
		if ( @{ $printer_users{$printer} } ) {
			system Schulkonsole::Encode::to_cli(
				  "$Schulkonsole::Config::_cmd_printer_lpadmin -p\Q$printer\E -u deny:"
				. join(',', @{ $printer_users{$printer} }));
		} else {
			system Schulkonsole::Encode::to_cli(
				"$Schulkonsole::Config::_cmd_printer_lpadmin -p\Q$printer\E -u deny:none");
		}
	}

	exit 0;
}

