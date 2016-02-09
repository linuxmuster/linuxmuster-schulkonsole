use strict;
use utf8;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::ExternalError;

use Sophomorix::SophomorixAPI;

package Schulkonsole::Wrapper;

sub wrapcommand {
	my $wrapcmd = shift;
	my $errorclass = shift;
	my $app_id = shift;
	my $id = shift;
	my $password = shift;
	my $args = shift;
	my $binaer = shift;
	
	my $wrapper = new Wrapper($wrapcmd,$errorclass,$app_id,$id, $password, $binaer);

	$wrapper->writefinal($args);
	
	$wrapper->readfinal();
}

sub wrap {
	my $wrapcmd = shift;
	my $errorclass = shift;
	my $app_id = shift;
	my $id = shift;
	my $password = shift;
	my $args = shift;
	my $binaer = shift;
	
	my $wrapper = new Schulkonsole::Wrapper($wrapcmd,$errorclass,$app_id,$id, $password, $binaer);

	$wrapper->writefinal($args);
	
	my $in = $wrapper->readfinal();

	return $in;
	
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
		binaer => shift,
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
    
	local $/ = undef if $this->{binaer};
	while (<$in>) {
		$this->{input_buffer} .= readline($in);
	}
}

sub init {
	my $this = shift;
	my $wrapcmd = shift;
	
	die new $this->{errorclass}(
		Schulkonsole::Error::Error::WRAPPER_WRONG,
		$wrapcmd, 1)
		unless $wrapcmd =~ /^\/usr\/lib\/schulkonsole\/bin\/wrapper-[a-z]{1,30}$/;
		
	$this->{wrapper_command} = $wrapcmd;
	die new $this->{errorclass}(
		Schulkonsole::Error::Error::WRAPPER_UNKNOWN,
		$wrapcmd, 1)
		unless $this->{wrapper_command};
	
	$this->start();
}


sub start {
	my $this = shift;
	$this->{out} = \*SCRIPTOUT;
	$this->{in} = \*SCRIPTIN;
	$this->{err} = \*SCRIPTIN;
	
	$this->{pid} = IPC::Open3::open3 $this->{out}, $this->{in}, $this->{err}, $this->{wrapper_command}
		or die new $this->{errorclass}(
			Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED,
			$this->{wrapper_command}, $!);

	binmode $this->{out}, ':utf8';
	binmode $this->{in}, ':utf8';
	binmode $this->{err}, ':utf8';

	my $re = waitpid $this->{pid}, POSIX::WNOHANG;
	if (   $re == $this->{pid}
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new $this->{errorclass}(
				Schulkonsole::Error::Error::WRAPPER_EXEC_FAILED,
				$this->{wrapper_command}, $!);
		} else {
			die new $this->{errorclass}(
				$error,
				$this->{wrapper_command});
		}
	}
	
	print {$this->{out}} "$this->{id}\n$this->{password}\n$this->{app_id}\n";

}




sub stop {
	my $this = shift;

	my $re = waitpid $this->{pid}, 0;
	if (    ($re == $this->{pid} or $re == -1)
	    and $?) {
		my $error = ($? >> 8);
		if ($error <= 128) {
			die new Schulkonsole::Error::ExternalError(
				Sophomorix::SophomorixAPI::fetch_error_string($error), 0,
				$this->{wrapper_command}, $!,
				($this->{input_buffer} ? "Output: $this->{input_buffer}" : 'No Output'));
		} else {
			$error -= 256;
			die new $this->{errorclass}(
				$error,
				$this->{wrapper_command});
		}
	}

	if ($this->{out}) {
		close $this->{out}
			or die new $this->{errorclass}(
				Schulkonsole::Error::Error::WRAPPER_BROKEN_PIPE_OUT,
				$this->{wrapper_command}, $!,
				($this->{input_buffer} ? "Output: $this->{input_buffer}" : 'No Output'));
	}

	close $this->{in}
		or die new $this->{errorclass}(
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
	
	$this->read();
	
	$this->stop();
	
	return $this->{input_buffer};
}

sub closeout {
	my $this = shift;
	
	close $this->{out}
				or die new $this->{errorclass}(
				Schulkonsole::Error::Error::WRAPPER_BROKEN_PIPE_OUT,
				$this->{wrapper_command}, $!,
				($this->{input_buffer} ? "Output: $this->{input_buffer}" : 'No Output'));
	undef $this->{out};
}




1;
