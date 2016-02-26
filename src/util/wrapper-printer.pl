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
use Data::Dumper;
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::PrinterError;



my $id = <>;
$id = int($id);
my $password = <>;
chomp $password;

my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHENTICATED_ID  )
	unless $userdata;

my $app_id = <>;
($app_id) = $app_id =~ /^(\d+)$/;
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST  )
	unless defined $app_id;

my $app_name = $Schulkonsole::Config::_id_root_app_names{$app_id};
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST  )
	unless defined $app_name;



my $permissions = Schulkonsole::Config::permissions_apps();
my $groups = Schulkonsole::DB::user_groups(
	$$userdata{uidnumber}, $$userdata{gidnumber}, $$userdata{gid});
# FIXME: workaround for non existing students group!
if(! (defined $$groups{teachers} or defined $$groups{domadmins})) {
	$$groups{'students'} = 1;
}

my $is_permission_found = 0;
foreach my $group (('ALL', keys %$groups)) {
	if ($$permissions{$group}{$app_name}) {
		$is_permission_found = 1;
		last;
	}
}
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHORIZED_ID   )
	unless $is_permission_found;


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

    $app_id == Schulkonsole::Config::PRINTERGETOWNQUOTAAPP and do {
	own_print_quota();
	last SWITCH;
    };

    $app_id == Schulkonsole::Config::PRINTERGETQUOTAAPP and do {
	print_quota();
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

=head3 own_print_quota

numeric constant: C<Schulkonsole::Config::PRINTERGETOWNQUOTAAPP>

=head4 Description

Get users own print quota

=head4 Parameters from standard input

None

=cut

sub own_print_quota {
	my $opt_user = "--user=\Q$$userdata{uid}\E";


	my $pages_cmd = Schulkonsole::Encode::to_cli(
	          	"$Schulkonsole::Config::_cmd_linuxmuster_pk $opt_user -t");
	my $pages = `$pages_cmd` or 
	exit ( Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED );

	($pages) = $pages =~ /^(\d+)$/;
	exit (  Schulkonsole::Error::PrinterError::WRAPPER_INVALID_PAGES   )
		unless defined $pages;



	my $max_cmd = Schulkonsole::Encode::to_cli(
	              	"$Schulkonsole::Config::_cmd_linuxmuster_pk $opt_user -m");
	my $max = `$max_cmd` or 
	exit ( Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED );

	($max) = $max =~ /^(\d+)$/;
	exit (  Schulkonsole::Error::PrinterError::WRAPPER_INVALID_MAX_PAGES  )
		unless defined $max;



	print "$pages\t$max\n";


	exit 0;
}

=head3 print_quota

numeric constant: C<Schulkonsole::Config::PRINTERGETQUOTAAPP>

=head4 Description

Get users print quota

=head4 Parameters from standard input

=over

=item users

UIDs one per line.
End users list with empty line.

=back

=cut

sub print_quota {
	my @users;

	while (my $user = <>) {
		last if $user =~ /^$/;
		($user) = $user =~ /^(.+)$/;
		exit (  Schulkonsole::Error::PrinterError::WRAPPER_INVALID_USER )
			unless $user;

		push @users, "\Q$user";
	}

	exit (  Schulkonsole::Error::PrinterError::WRAPPER_NO_USERS )
		unless @users;


	my $pages_cmd = Schulkonsole::Encode::to_cli(
	                	"$Schulkonsole::Config::_cmd_linuxmuster_pk -t ");
	my $max_cmd = Schulkonsole::Encode::to_cli(
	                	"$Schulkonsole::Config::_cmd_linuxmuster_pk -m ");
	foreach my $user (@users) {
		my $opt_user = Schulkonsole::Encode::to_cli("--user=\Q$$userdata{uid}");


		my $pages = `$pages_cmd $opt_user ` or 
		exit ( Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED );

		($pages) = $pages =~ /^(\d+)$/;
		exit ( Schulkonsole::Error::PrinterError::WRAPPER_INVALID_PAGES )
			unless defined $pages;


		my $max = `$max_cmd $opt_user` or 
		exit ( Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED );

		($max) = $max =~ /^(\d+)$/;
		exit (  Schulkonsole::Error::PrinterError::WRAPPER_INVALID_MAX_PAGES
		      )
			unless defined $max;


		print "$user\t$pages\t$max\n";
	}


	exit 0;
}
