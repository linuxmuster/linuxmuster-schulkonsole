use strict;
use utf8;
use Schulkonsole::Error::Error;
use Schulkonsole::Config;
use Schulkonsole::DB;

package Schulkonsole::Wrapper;

=head1 NAME

Schulkonsole::Wrapper - interface to system commands

=head1 SYNOPSIS

 use Schulkonsole::Wrapper;

 my $in = Schulkonsole::Wrapper::wrap(
 		$wrapcmd,  - _cmd_... from Schulkonsole::Config
 		$errorclass, - string error class
		$app_id, - constant from Schulkonsole::Config
		$id, - invoking user id
		$password, - invoking user password
		$args, - additional args passed through input stream
	    $mode); - stream mode

 my $in = Schulkonsole::Wrapper::wrap(
		Schulkonsole::Config::_cmd_sophomorix,
		'Schulkonsole::Error::SophomorixError',
		Schulkonsole::Config::SHARESTATESAPP,
		$id, $password,
	    join("\n", @login_ids)."\n\n",
	    Schulkonsole::Wrapper::MODE_LINES);

=head1 DESCRIPTION

Schulkonsole::Wrapper is used to execute commands with root premissions

If a wrapper command fails, it usually dies with a subclass of Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error subclass.

=cut

require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA=qw(Exporter);
@EXPORT_OK=qw(
	MODE_LINES
	MODE_FILE
	MODE_RAW
	
	wrapcommand
	wrap
	wrapper_authenticate
	wrapper_authorize
);

=head2 stream modes

=over

=head3 MODE_LINES

The return value is returned line by line.

=head3 MODE_FILE

The return value is returned in an array containing the output lines.

=head3 MODE_RAW

The return value is returned in a raw stream.

=back

=cut
use constant {
	MODE_LINES => 0,
	MODE_FILE  => 1,
	MODE_RAW   => 2,
};

=head3 wrapcommand($wrapcmd,$errorclass,$app_id,$id,$password,$args,$mode)

Execute a command with root access.

=over

=<$wrapcmd> string

command from Schulkonsole::Config::_cmd...

=<$errorclass> string

subclass from Schulkonsole::Error that is created on error

=<$app_id>

valid app id from Schulkonsole::Config

=<$id>

invoking users id

=<$password>

invoking users password

=<$args> string

string containing additional arguments, which is fed to process STDIN

=<$mode>

stream mode for the subprocess

=back

Execute a command with root access.

=cut
sub wrapcommand {
	my $wrapcmd = shift;
	my $errorclass = shift;
	my $app_id = shift;
	my $id = shift;
	my $password = shift;
	my $args = shift;
	my $mode = shift;
	
	my $wrapper = new Schulkonsole::Wrapper($wrapcmd,$errorclass,$app_id,$id, $password, $mode);

	$wrapper->writefinal($args);
	
	$wrapper->readfinal();
}

=head3 wrap($wrapcmd,$errorclass,$app_id,$id,$password,$args,$mode)

Execute a function with root access and return it's result value

=over

=<$wrapcmd> string

command from Schulkonsole::Config::_cmd...

=<$errorclass> string

subclass from Schulkonsole::Error that is created on error

=<$app_id>

valid app id from Schulkonsole::Config

=<$id>

invoking users id

=<$password>

invoking users password

=<$args> string

string containing additional arguments, which is fed to process STDIN

=<$mode>

stream mode for the subprocess

=output

return the functions value either as subsequent lines or as an array of strings
or as a raw stream.

=back

Execute a function with root access and return it's result value.

=cut

sub wrap {
	my $wrapcmd = shift;
	my $errorclass = shift;
	my $app_id = shift;
	my $id = shift;
	my $password = shift;
	my $args = shift;
	my $mode = shift;
	
	my $wrapper = new Schulkonsole::Wrapper($wrapcmd,$errorclass,$app_id,$id, $password, $mode);

	$wrapper->writefinal($args);
	
	my $in = $wrapper->readfinal();
	return $in;
	
}

=head3 wrapper_authenticate()

used in wrapper

Reads $id and $password from *STDIN and return userdata

=over

=Input parameters from *STDIN

command from Schulkonsole::Config::_cmd...

=<$id> number

id number of invoking user

=<$password>

<password> of invoking user

=output

return hash containing userdata

=back

=cut

sub wrapper_authenticate {
	my $id = <>;
	$id = int($id);
	
	my $password = <>;
	chomp $password;
	
	my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
	exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHENTICATED_ID  )
		unless $userdata;

	return $userdata;
	
}

=head3 wrapper_authorize($userdata,$appnames)

used in wrapper

Reads <app_id> from *STDIN and authorizes wrapper use otherwise extis with error condition

=over

=parameters

=<$userdata>

userdata of invoking user as returned from <wrapper_authenticate>

=<$appnames>

Hash that maps the numerical ID of an application in the permissions 
configuration file to its name

=Input parameters from *STDIN

=<$app_id>

number of invoked app

=output

=<$app_id>

number of invoked app

=back

=cut

sub wrapper_authorize {
	my $userdata = shift;
	my $appnames = shift;
	$appnames = \%Schulkonsole::Config::_id_root_app_names
					unless $appnames;
	
	my $app_id = <>;
	($app_id) = $app_id =~ /^(\d+)$/;
	exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST )
		unless defined $app_id;
	
	my $app_name = $$appnames{$app_id};
	exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST )
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
	exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHORIZED_ID  )
		unless $is_permission_found;

	return $app_id;
}


sub new {
	my $class = shift;
	my $wrapcmd = shift;
    
	my $this = {
		wrapper_command => undef,
		errorclass => shift,
		app_id => shift,
		id => shift,
		password => shift,
		mode => shift,
		in => undef,
		out => undef,
		err => undef,
		pid => undef,
		input_buffer => undef,
	};
	
	bless $this, $class;

	$this->init($wrapcmd);
	
	return $this;
}

sub buffer_input {
	my $this = shift;
    my $in = $this->{in};
    
	local $/ = undef if $this->{mode} == MODE_FILE;
	binmode $in, ':raw' if $this->{mode} == MODE_RAW;
	
	while (<$in>) {
		$this->{input_buffer} .= $_ ;
	}

}

sub init {
	my $this = shift;
	my $wrapcmd = shift;
	
	die $this->trigger_errror(Schulkonsole::Error::Error::WRAPPER_WRONG, $wrapcmd, 1)
		unless $wrapcmd =~ /^\/usr\/lib\/schulkonsole\/bin\/wrapper-[a-z]{1,30}$/;
		
	$this->{wrapper_command} = $wrapcmd;
	die $this->trigger_errror(Schulkonsole::Error::Error::WRAPPER_UNKNOWN, $wrapcmd, 1)
		unless $this->{wrapper_command};
	
	$this->start();
}

sub trigger_errror {
	my $this = shift;
	my $temp = $this->{errorclass};
	my $filename = $this->{errorclass} . '.pm';
	$filename =~ s/::/\//g;
	require $filename;

	return $temp->new(@_);
}

sub start {
	my $this = shift;
	use Symbol 'gensym';
	$this->{err} = gensym;
	$this->{in} = $this->{err};
	
	$this->{pid} = IPC::Open3::open3 $this->{out}, $this->{in}, $this->{err}, $this->{wrapper_command}
		or die $this->trigger_errror(Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED,
			$this->{wrapper_command}, $!);

	binmode $this->{out}, ':utf8';
	binmode $this->{in}, ':utf8';
	binmode $this->{err}, ':utf8';

	my $re = waitpid $this->{pid}, POSIX::WNOHANG;
	if (   $re == $this->{pid}
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		die $this->trigger_errror($error, $this->{wrapper_command},$!);
	}

	print {$this->{out}} "$this->{id}\n$this->{password}\n$this->{app_id}\n";
}




sub stop {
	my $this = shift;
	
	my $re = waitpid $this->{pid}, 0;
	my $reply = $?;
	if (    ($re == $this->{pid} or $re == -1)
	    and $?) {
		my $error = ($? >> 8);
		if ($error < Schulkonsole::Error::Error::EXTERNAL_ERROR) {
			die $this->trigger_errror(Schulkonsole::Error::Error::EXTERNAL_ERROR + $error,
				$this->{wrapper_command}, $!,
				($this->{input_buffer} ? "Output: $this->{input_buffer}" : 'No Output'));
		} else {
			$error -= 256;
			die $this->trigger_errror($error, $this->{wrapper_command} . '[' . $this->{input_buffer} . ']');
		}
	}

	if ($this->{out}) {
		close $this->{out}
			or die $this->trigger_errror(
				Schulkonsole::Error::Error::WRAPPER_BROKEN_PIPE_OUT,
				$this->{wrapper_command}, $!,
				($this->{input_buffer} ? "Output: $this->{input_buffer}" : 'No Output'));
	}

	close $this->{in}
		or die $this->trigger_errror(
			Schulkonsole::Error::Error::WRAPPER_BROKEN_PIPE_IN,
			$this->{wrapper_command}, $!,
			($this->{input_buffer} ? "Output: $this->{input_buffer}" : 'No Output'));

	undef $this->{input_buffer};
}

sub write {
	my $this = shift;
	my $string = shift;

	print {$this->{out}} $string;
	
}

sub writefinal {
	my $this = shift;
	my $string = shift;
	
	$this->write($string);
	
	$this->closeout();
}

sub read {
	my $this = shift;
	$this->buffer_input();
	return $this->{input_buffer};
}

sub readfinal {
	my $this = shift;
	
	my $ret = $this->read();
	$this->stop();
	
	return $ret;
}

sub closeout {
	my $this = shift;
	
	close $this->{out}
				or die $this->trigger_errror(Schulkonsole::Error::Error::WRAPPER_BROKEN_PIPE_OUT,
				$this->{wrapper_command}, $!,
				($this->{input_buffer} ? "Output: $this->{input_buffer}" : 'No Output'));
	undef $this->{out};
}




1;
