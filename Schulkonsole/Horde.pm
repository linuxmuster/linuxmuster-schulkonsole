use strict;
use open ':utf8';
use IPC::Open3;
use POSIX 'sys_wait_h';
use Net::IMAP::Simple;
use Schulkonsole::Config;
use Schulkonsole::Wrapper;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::HordeError;
use Schulkonsole::DB;

=head1 NAME

Schulkonsole::Horde - get/set mail forwards

=cut

package Schulkonsole::Horde;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.05;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	get_mailforwards
	set_mailforwards
	remove_mailforwards
);


my $wrapcmd = $Schulkonsole::Config::_wrapper_horde;
my $errorclass = "Schulkonsole::Error::HordeError";

=head3 C<get_mailforwards($user,$password)>

=cut

sub get_mailforwards {
	my $id = shift;
        my $password = shift;


        my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::GETMAILFORWARDS,
							$id, $password, "\n\n");
        my $userdata = Schulkonsole::DB::get_userdata_by_id($id);
        my $uid = $$userdata{uid};
        
	my $mailforwards;
        my $mailkeep;
        foreach (split("\n",$in)) {
	        chomp;
		next unless $_ =~ m/^$uid;.*/;
		my @line = split ";";
		$mailforwards = $line[1];
                if( defined $line[2]) {
                    $mailkeep = 1;
                } else {
                    $mailkeep = 0;
                }
	}

	return ($mailforwards,$mailkeep);
}











=head3 C<set_mailforwards($user,$password,$mailforwards,$mailkeep)>

=cut

sub set_mailforwards {
	my $id = shift;
        my $password = shift;
        my $mailforwards = shift;
        my $mailkeep = shift;
        
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETMAILFORWARDS,
							$id, $password, "$mailforwards\n$mailkeep\n\n");

	return 0;
}










=head3 C<remove_mailforwards($user,$password)>

=cut

sub remove_mailforwards {
	my $id = shift;
        my $password = shift;
        
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::REMOVEMAILFORWARDS,
							$id, $password, "\n\n");


	return 0;
}










1;
