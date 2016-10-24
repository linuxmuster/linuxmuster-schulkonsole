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
use Schulkonsole::Error::Error;
use Schulkonsole::Error::HordeError;
use POSIX;



my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

SWITCH: {

	$app_id == Schulkonsole::Config::GETMAILFORWARDS and do {
		get_mailforwards();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::SETMAILFORWARDS and do {
		set_mailforwards();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::REMOVEMAILFORWARDS and do {
		remove_mailforwards();
		last SWITCH;
	};

};	

exit -2;	# program error

=head3 get_mailforwards

numeric constant: C<Schulkonsole::Config::GETMAILFORWARDS>

=head4 Description

invokes C<horde-mail.php>

=cut

sub get_mailforwards {

	my ($uid) = $$userdata{uid} =~ /^(\w+)$/;
	exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED)
	    unless $uid;
	    
	my ($password) = $$userdata{password} =~ /^(\w+)$/;
	exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED)
	    unless $password;
	
	my $cmd = Schulkonsole::Encode::to_cli($Schulkonsole::Config::_cmd_horde_mail);
	$cmd .= " --user=" . $uid . " --password=" . $password;
	$cmd .= " --get-forwards |";

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open(CMDIN, $cmd) 
	    or exit (Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);
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
	($forwards) = $forwards =~ /^([a-zA-Z0-9._%,@+-]+)$/;
	exit (Schulkonsole::Error::HordeError::WRAPPER_INVALID_ADDRESSES)
	    unless $forwards;

	my @mailforwards = ();
        foreach my $mailaddress (split(',',$forwards)) {
            $mailaddress =~ s/^\s+|\s+$//g;
            if($mailaddress !~ /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/) {
		    exit (Schulkonsole::Error::HordeError::WRAPPER_INVALID_ADDRESSES);
            }
            push @mailforwards, $mailaddress;
	}
	$forwards = join(",", @mailforwards);
	
	exit (Schulkonsole::Error::HordeError::WRAPPER_NO_ADDRESSES)
	    unless $forwards;
	
	my $keep;
	$keep = <>;
	($keep) = $keep =~ /^([01])$/;
	exit (Schulkonsole::Error::HordeError::WRAPPER_INVALID_ADDRESSES)
	    unless defined $keep;
	
	my ($uid) = $$userdata{uid} =~ /^(\w+)$/;
	exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED)
	    unless $uid;
	    
	my ($password) = $$userdata{password} =~ /^(\w+)$/;
	exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED)
	    unless $password;
	
	my $cmd = Schulkonsole::Encode::to_cli($Schulkonsole::Config::_cmd_horde_mail);
	$cmd .= " --user=" . $uid . " --password=" . $password;
	$cmd .= " --set-forwards=$forwards";
	if ($keep) {
	    $cmd .= " --keep";
	}
	
	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	system($cmd) == 0
	    or exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED);
	
	exit 0;
}

=head3 remove_mailforwards

numeric constant: C<Schulkonsole::Config::REMOVEMAILFORWARDS>

=head4 Description

invokes C<horde-mail.php>

=cut

sub remove_mailforwards {
	my ($uid) = $$userdata{uid} =~ /^(\w+)$/;
	exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED)
	    unless $uid;
	    
	my ($password) = $$userdata{password} =~ /^(\w+)$/;
	exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED)
	    unless $password;
	
	my $cmd = Schulkonsole::Encode::to_cli($Schulkonsole::Config::_cmd_horde_mail);
	$cmd .= " --user=" . $uid . " --password=" . $password;
	$cmd .= " --remove-forwards";
	
	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	system($cmd) == 0
	    or exit (Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED);
	
	exit 0;
}

exit -2;	# program error



