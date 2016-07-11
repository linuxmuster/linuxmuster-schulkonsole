#! /usr/bin/perl

=head1 NAME

wrapper-horde.pl - wrapper for configuration of horde

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::MAILFORWARD;

 my $linbo_username = 'testuser';

 open SCRIPT, "| $Schulkonsole::Config::_wrapper_horde";
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id

 INPUT

=head1 DESCRIPTION

=cut

use strict;
use utf8;
use lib '/usr/share/schulkonsole';
use open ':utf8';
use open ':std';
use Schulkonsole::Wrapper;
use Schulkonsole::Config;
use POSIX;



my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

my $opts;
SWITCH: {

	$app_id == Schulkonsole::Config::GETMAILFORWARDS and do {
		get_mailforwards();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::SETMAILFORWARDS and do {
		set_mailforwards();
		last SWITCH;
	};

}		

exit -2;	# program error

=head3 get_mailforwards

numeric constant: C<Schulkonsole::Config::GETMAILFORWARDS>

=head4 Description

invokes C<horde-mail.php>

=cut

sub get_mailforwards {

	my $cmd = Schulkonsole::Encode::to_cli($Schulkonsole::Config::_cmd_horde_mail);
	$cmd .= " --user=" . $$userdata{uid} . " --password=" . $$userdata{password};
	$cmd .= " --get-forwards |";

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open(CMDIN, $cmd) 
	    or exit (	Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);
	while(<CMDIN>) {
		print $_;
	}
	close(CMDIN)
	    or exit (	Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);

	exit 0;
}

=head3 set_mailforwards

numeric constant: C<Schulkonsole::Config::SETMAILFORWARDS>

=head4 Description

invokes C<horde-mail.php>

=cut

sub set_mailforwards {
	my $forwards = <>;
	($forwards) = $forwards =~ /^(\w*)$/;
	
	my $keep;
	if ($forwards) {
	    $keep = <>;
	    ($keep) = $keep =~ /^[01]$/;
	    exit (Schulkonsole::Error::HordeError::WRAPPER_INVALID_ADDRESSES)
		unless $keep;
	}
	
	my $cmd = Schulkonsole::Encode::to_cli($Schulkonsole::Config::_cmd_horde_mail);
	$cmd .= " --user=" . $$userdata{uid} . " --password=" . $$userdata{password};
	if (not $forwards) {
	    $cmd .= " --remove-forwards";
	} else {
	    $cmd .= " --set-forwards=$forwards";
	}
	if ($keep) {
	    $cmd .= " --keep";

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	system $cmd
	    or exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED);
	
	exit 0;
}

exit -2;	# program error



