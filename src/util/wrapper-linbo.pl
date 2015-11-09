#! /usr/bin/perl

=head1 NAME

wrapper-linbo.pl - wrapper for configuration of linbo

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::INTERNETONOFFAPP;

 my $linbo_username = 'testuser';

 open SCRIPT, "| $Schulkonsole::Config::_wrapper_linbo";
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id
 $linbo_username

 INPUT

=head1 DESCRIPTION

=cut

use strict;
use utf8;
use lib '/usr/share/schulkonsole';
use open ':utf8';
use open ':std';
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Linbo;
use POSIX;



my $id = <>;
$id = int($id);
my $password = <>;
chomp $password;

my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
exit (  Schulkonsole::Error::Linbo::WRAPPER_UNAUTHENTICATED_ID
      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
	unless $userdata;

my $app_id = <>;
($app_id) = $app_id =~ /^(\d+)$/;
exit (  Schulkonsole::Error::Linbo::WRAPPER_APP_ID_DOES_NOT_EXIST
      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
	unless defined $app_id;

my $app_name = $Schulkonsole::Config::_id_root_app_names{$app_id};
exit (  Schulkonsole::Error::Linbo::WRAPPER_APP_ID_DOES_NOT_EXIST
      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
	unless defined $app_name;



my $permissions = Schulkonsole::Config::permissions_apps();
my $groups = Schulkonsole::DB::user_groups(
	$$userdata{uidnumber}, $$userdata{gidnumber}, $$userdata{gid});

my $is_permission_found = 0;
foreach my $group (('ALL', keys %$groups)) {
	if ($$permissions{$group}{$app_name}) {
		$is_permission_found = 1;
		last;
	}
}
exit (  Schulkonsole::Error::Linbo::WRAPPER_UNAUTHORIZED_ID
      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
	unless $is_permission_found;


my $opts;
SWITCH: {

	$app_id == Schulkonsole::Config::LINBOREMOTESTATUSAPP and do {
		linbo_remote_status();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::LINBOREMOTEWINDOWAPP and do {
		linbo_remote_window();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::LINBOREMOTEAPP and do {
		linbo_remote();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::UPDATELINBOFSAPP and do {
		update_linbofs();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::LINBOWRITESTARTCONFAPP and do {
		write_start_conf();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::LINBOCOPYSTARTCONFAPP and do {
		copy_start_conf();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::LINBOCOPYREGPATCHAPP and do {
		copy_regpatch();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::LINBODELETEAPP and do {
		linbo_delete();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::LINBOIMAGEAPP and do {
		linbo_manage_images();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::LINBOWRITEAPP and do {
		linbo_write();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::LINBOWRITEGRUBCFGAPP and do {
		linbo_write_grub_cfg();
		last SWITCH;
	};

}		

exit -2;	# program error

=head3 update_linbofs

numeric constant: C<Schulkonsole::Config::UPDATELINBOFSAPP>

=head4 Description

invokes C<update-linbofs.sh>

=cut

sub update_linbofs {
	# set ruid, so that ssh searches for .ssh/ in /root
	local $< = $>;
	exec Schulkonsole::Encode::to_cli(
	     	$Schulkonsole::Config::_cmd_update_linbofs);
}

=head3 write_start_conf

numeric constant: C<Schulkonsole::Config::LINBOWRITESTARTCONFAPP>

=head4 Description

Writes lines into a start.conf.<group>

=head4 Parameters from standard input

=over

=item C<group>

=item C<lines>

=cut

sub write_start_conf {
	my $group = <>;
	($group) = $group =~ /^([a-z\d_]+)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_GROUP
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $group;

	my $filename = Schulkonsole::Encode::to_fs(
	   	$Schulkonsole::Config::_linbo_start_conf_prefix . $group);
	if (-e $filename) {
		# backup old file
		my $time = POSIX::strftime("%Y-%m-%d-%H%M", localtime($^T));
		my $fileprefix;
		($fileprefix) = $filename =~ /^.*\/([^\/]+)$/;
		my $old_filename = Schulkonsole::Encode::to_fs(
                    $Schulkonsole::Config::_linbo_log_dir . '/'
                    . $fileprefix . '-' . $time);
		my $cnt = 0;
		while (-e $old_filename) {
			$cnt++;
			$old_filename = Schulkonsole::Encode::to_fs(
                            $Schulkonsole::Config::_linbo_log_dir . '/' 
                            . $fileprefix . '-' . $time . '-' . $cnt);
		}

		rename $filename, $old_filename;
	}


	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open FILE, '>', $filename
		or exit (  Schulkonsole::Error::Linbo::WRAPPER_CANNOT_OPEN_FILE
		         - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	flock FILE, 2;
	seek FILE, 0, 0;

	while (<>) {
		print FILE;
	}

	close FILE;

	exit 0;
}


=head3 copy_start_conf

numeric constant: C<Schulkonsole::Config::LINBOCOPYSTARTCONFAPP>

=head4 Description

Writes lines into a start.conf.<group>

=head4 Parameters from standard input

=over

=item C<group>

=item C<lines>

=cut

sub copy_start_conf {
	my $src = <>;
	chomp $src;
	($src) = $src =~ /^([a-z\d_]+[^\/]*)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_GROUP
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $src;

	my $dest = <>;
	chomp $dest;
	($dest) = $dest =~ /^([a-z\d_]+)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_GROUP
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $dest;


	my $src_filename = Schulkonsole::Encode::to_fs(
		$Schulkonsole::Config::_linbo_start_conf_prefix . $src);
	my $dest_filename = Schulkonsole::Encode::to_fs(
		$Schulkonsole::Config::_linbo_start_conf_prefix . $dest);
	if (-e $dest_filename) {
		# backup old file
		my $time = POSIX::strftime("%Y-%m-%d-%H%M", localtime($^T));
		my $old_filename = Schulkonsole::Encode::to_fs(
		                   	$dest_filename . '-' . $time);
		my $cnt = 0;
		while (-e $old_filename) {
			$cnt++;
			$old_filename = Schulkonsole::Encode::to_fs(
			                	$dest_filename . '-' . $time . '-' . $cnt);
		}

		rename $dest_filename, $old_filename;
	}


	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open SRC, '<', $src_filename
		or exit (  Schulkonsole::Error::Linbo::WRAPPER_CANNOT_OPEN_FILE
		         - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	flock SRC, 1;
	seek SRC, 0, 0;

	open DEST, '>', $dest_filename
		or exit (  Schulkonsole::Error::Linbo::WRAPPER_CANNOT_OPEN_FILE
		         - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	flock DEST, 2;
	seek DEST, 0, 0;

	while (<SRC>) {
		s/^Group\s*=.*?(\s*#.*)?$/Group = $dest$1/;
		print DEST;
	}

	close DEST;
	close SRC;


	exit 0;
}



=head3 copy_regpatch

numeric constant: C<Schulkonsole::Config::LINBOCOPYREGPATCHAPP>

=head4 Description

Copies a template to <image>.reg

=head4 Parameters from standard input

=over

=item C<template>

=item C<is_example>

=item C<image>

=cut

sub copy_regpatch {
	my $regpatch = <>;
	($regpatch) = $regpatch =~ /^([^\/]+\.reg)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_FILENAME
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $regpatch;

	my $is_example = <>;
	($is_example) = $is_example =~ /^([01])$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_IS_EXAMPLE
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $is_example;

	my $image = <>;
	($image) = $image =~ /^([^\/]+\.(?:cloop|rsync))$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_IMAGE
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $image;

	my $src_filename = Schulkonsole::Encode::to_fs(($is_example ?
		  "$Schulkonsole::Config::_linbo_dir/examples"
		: $Schulkonsole::Config::_linbo_dir)
		. "/$regpatch");
	my $dest_filename = Schulkonsole::Encode::to_fs(
	                    	"$Schulkonsole::Config::_linbo_dir/$image.reg");

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open SRC, '<', $src_filename
		or exit (  Schulkonsole::Error::Linbo::WRAPPER_CANNOT_OPEN_FILE
		         - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	flock SRC, 1;
	seek SRC, 0, 0;

	open DEST, '>', $dest_filename
		or exit (  Schulkonsole::Error::Linbo::WRAPPER_CANNOT_OPEN_FILE
		         - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	flock DEST, 2;
	seek DEST, 0, 0;

	{
	local $/ = undef;
	while (<SRC>) {
		print DEST;
	}
	}

	close DEST;
	close SRC;


	exit 0;
}

=head3 linbo_delete

numeric constant: C<Schulkonsole::Config::LINBODELETEAPP>

=head4 Description

Deletes a LINBO file

=head4 Parameters from standard input

=over

=item C<filename>

=back

=head3 Description

Deletes C<$filename> in C<Config::_linbo_dir> rsp. C<Config::_grub_config_dir>.
Filename has to match C<*.cloop.reg>, C<*.rsync.reg>, C<*.cloop.postsync>, C<*.rsync.postsync>, 
C<(?:[a-z\d_]+)\.cfg>, C<start.conf.(?:[a-z\d_]+)>.

=cut

sub linbo_delete {
	my $filename = <>;
	my $tmpfilename;
	($tmpfilename) = $filename =~ /^([^\/]+\.(?:cloop|rsync)\.(?:reg|postsync))$/;
    ($tmpfilename) = $filename =~ /^([a-z\d_]+\.cfg)$/ unless defined $tmpfilename;
    ($tmpfilename) = $filename =~ /^(start\.conf\.[a-z\d_]+)$/ unless defined $tmpfilename;
    $filename = $tmpfilename;
    exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_FILENAME
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $filename;

    my $path = "$Schulkonsole::Config::_linbo_dir";
    $path = "$Schulkonsole::Config::_grub_config_dir" if $filename =~ /^[a-z\d_]+\.cfg/;
        
	my $file = Schulkonsole::Encode::to_fs("$path/$filename");

	unlink $file;

	exit 0;
}

=head3 linbo_manage_images

numeric constant: C<Schulkonsole::Config::LINBOIMAGEAPP>

=head4 Description

Copy, rename, delete LINBO images.

=head4 Parameters from standard input

=over

=item C<action>

0 (= delete), 1 (= move), or 2 (= copy)

=item C<filename>

Image name with C<.cloop> or C<.rsync> suffix

=item C<new_image> (if C<action> not delete)

New image name without C<.cloop> and C<.rsync> suffix

=cut

sub linbo_manage_images {
	my $action = <>;
	($action) = $action =~ /^([012])$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_ACTION
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $action;

	my $filename = <>;
	my ($image, $image_suffix) = $filename =~ /^([^\/]+)\.(cloop|rsync)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_IMAGE
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $image;

	my $file = "$Schulkonsole::Config::_linbo_dir/$image.$image_suffix";
	my @suffixes = ('.desc', '.info', '.macct', '.opsi', '.postsync', '.reg', '.torrent','');

	my @errors;
	if ($action) {
		my $new_image = <>;
		($new_image) = $new_image =~ /^([^\/]+?)$/;
		exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_IMAGE
		      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
			unless defined $new_image;

		my $new_file
			= "$Schulkonsole::Config::_linbo_dir/$new_image.$image_suffix";

		$) = 0;
		$( = $);
		umask(022);

		if ($action == 1) {
                        system Schulkonsole::Encode::to_cli("service linbo-bittorrent stop \Q$file\E force");
                        system Schulkonsole::Encode::to_cli("service linbo-multicast stop \Q$file\E force");
			foreach my $suffix (@suffixes) {
				rename Schulkonsole::Encode::to_fs("$file$suffix"),
				       Schulkonsole::Encode::to_fs("$new_file$suffix");
			}
		} else {
			foreach my $suffix (@suffixes) {
				system Schulkonsole::Encode::to_cli(
				       	"cp -p \Q$file$suffix\E \Q$new_file$suffix\E");
			}
		}
                system Schulkonsole::Encode::to_cli("service linbo-bittorrent restart \Q$new_file\E force");
                system Schulkonsole::Encode::to_cli("service linbo-multicast restart \Q$new_file\E force");
	} else {
		foreach my $suffix (@suffixes) {
			unlink Schulkonsole::Encode::to_fs("$file$suffix");
		}
                system Schulkonsole::Encode::to_cli("service linbo-bittorrent stop \Q$file\E");
                system Schulkonsole::Encode::to_cli("service linbo-multicast stop \Q$file\E");
	}

	exit 0;
}

=head3 linbo_write

numeric constant: C<Schulkonsole::Config::LINBOWRITEAPP>

=head4 Description

Writes a LINBO text file

=head4 Parameters from standard input

=over

=item C<filename>

The filename, which belongs to a cloop or rsync file,
which is one of a reg file, a desc (description) file or a 
postsync file

=item C<lines>

The text lines of the file to write

=cut

sub linbo_write {
	my $filename = <>;
	($filename) = $filename =~ /^([^\/]+\.(?:cloop|rsync)\.(?:reg|desc|postsync))$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_FILENAME
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $filename;

	my $file = Schulkonsole::Encode::to_fs("$Schulkonsole::Config::_linbo_dir/$filename");

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open FILE, '>', $file or exit -106;
	flock FILE, 2;
	seek FILE, 0, 0;

	while (<>) {
		print FILE;
	}

	close FILE;

	exit 0;
}

=head3 linbo_write_grub_cfg

numeric constant: C<Schulkonsole::Config::LINBOWRITEGRUBCFGAPP>

=head4 Description

Writes a LINBO grub cfg start file

=head4 Parameters from standard input

=over

=item C<filename>

=item C<lines>

=cut

sub linbo_write_grub_cfg {
	my $filename = <>;
	($filename) = $filename =~ /^([a-z\d_]+\.cfg)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_FILENAME
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $filename;

	my $file = Schulkonsole::Encode::to_fs(
	           	"$Schulkonsole::Config::_grub_config_dir/$filename");

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open FILE, '>', $file or exit -106;
	flock FILE, 2;
	seek FILE, 0, 0;

	while (<>) {
		print FILE;
	}

	close FILE;

	exit 0;
}

=head3 linbo_remote_status

numeric constant: C<Schulkonsole::Config::LINBOREMOTESTATUSAPP>

=head4 Description

Reads the running linbo-remote screens status.

=cut

sub linbo_remote_status() {
	my $cmd = Schulkonsole::Encode::to_cli($Schulkonsole::Config::_cmd_linbo_remote) . " -l |";

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	open(CMDIN,$cmd) || 
		exit (	Schulkonsole::Error::Linbo::WRAPPER_CANNOT_RUN_COMMAND
				- Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	while(<CMDIN>) {
		print $_;
	}

	exit 0;
}

=head3 linbo_remote_window

numeric constant: C<Schulkonsole::Config::LINBOREMOTEWINDOWAPP>

=head4 Description

Reads the running linbo-remote screen lines.

=head4 Parameters from standard input

=over

=item C<session>

Screen session name.

=cut

sub linbo_remote_window() {
	my $session = <>;
	($session) = $session =~ /^(.+)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_SESSION_NAME
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
	      unless $session;
	
	my $tmpfile = "$Schulkonsole::Config::_runtimedir/screen_hardcopy_" . $$userdata{uidnumber} . '_' . time;
 	my $cmd = Schulkonsole::Encode::to_cli("screen -S $session -p 0 -X hardcopy $tmpfile");

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	system $cmd || 
		exit (	Schulkonsole::Error::Linbo::WRAPPER_CANNOT_RUN_COMMAND
				- Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	sleep 1;
	open(FILEIN, '<:encoding(UTF-8)', Schulkonsole::Encode::to_cli($tmpfile)) ||
		exit (  Schulkonsole::Error::Linbo::WRAPPER_CANNOT_OPEN_FILE
		      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	
	while(<FILEIN>) {
		print $_;
	}
	close(FILEIN);

	system Schulkonsole::Encode::to_cli("rm -f $tmpfile");

	exit 0;
}



=head3 linbo_remote

numeric constant: C<Schulkonsole::Config::LINBOREMOTEAPP>

=head4 Description

Starts a new linbo-remote screen process.

=head4 Parameters from standard input

=over

=item C<type>

Either i|g|r

=item C<target>

Hosts (hostname with i/group with g)/room with r

=item C<run>

Run immediately(c) or on next boot(p).

=item C<commands>

Comma separated list of commands to be run.

=item C<nr1>

delay time after each wakeup(run=c), -1 disable wakeup/disable buttons(run=p)

=item C<nr2>

delay time before commands(run=c)/bypass auto functions(run=p)

=cut

sub linbo_remote() {
	my $target = <>;
	my $type;
	($type, $target) = $target =~ /^(group|host|room)_(.+)$/;
	my %ttype = ('group' => 'g', 'host' => 'i', 'room' => 'r');
	$type = $ttype{$type};
	
	($type) = $type =~ /^(i|g|r)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_TYPE
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $type;

	($target) = $target =~ /^([a-zA-Z\d_-]+)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_TARGET
	      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		unless defined $target;
	
	if($type eq 'i') {
		my $hosts = Schulkonsole::Config::hosts();
		exit (  Schulkonsole::Error::Linbo::WRAPPER_NO_SUCH_HOST
			  - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
			  unless $$hosts{$target};
	} elsif($type eq 'g') {
		my $groups = Schulkonsole::Linbo::groups();
		exit (  Schulkonsole::Error::Linbo::WRAPPER_NO_SUCH_GROUP
		      - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		      unless $$groups{$target};
	} else { # $type eq 'r'
		my $rooms = Schulkonsole::Config::rooms();
		exit (  Schulkonsole::Error::Linbo::WRAPPER_NO_SUCH_ROOM
			  - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
			  unless $$rooms{$target};
	}
	
	my $now = <>;
	($now) = $now =~ /^(0|1)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_RUN
		  - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		  unless defined $now;
	
	my $commands = <>;
	($commands) = $commands =~ /^(.+)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_COMMANDS
		  - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		  unless defined $commands;
	
	my $nr1 = <>;
	($nr1) = $nr1 =~ /^(-?\d+)$/;
	
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_ARG
		  - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		  unless defined $nr1;
	
	my $nr2 = <>;
	($nr2) = $nr2 =~ /^(\d+)$/;
	exit (  Schulkonsole::Error::Linbo::WRAPPER_INVALID_ARG
		  - Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE)
		  unless defined $nr2;
		
	my $cmd = $Schulkonsole::Config::_cmd_linbo_remote;
	$cmd .= " -$type $target".($now?' -c':' -p')." $commands";
	if($now) {
		$cmd .= ($nr1>0?" -w $nr1":($nr1==0?" -w":"")) . ($nr2>0?" -b $nr2":""); 
	} else { # run == 'p'
		$cmd .= ($nr1? " -d": "") . ($nr2? " -n": "");
	}
	$cmd = Schulkonsole::Encode::to_cli($cmd);
	
	$< = $>;
	$) = 0;
	$( = $);
	umask(022);
	
	exec($cmd) || 
		exit (	Schulkonsole::Error::Linbo::WRAPPER_CANNOT_RUN_COMMAND
				- Schulkonsole::Error::Linbo::WRAPPER_ERROR_BASE);
	
	exit 0;
}


exit -2;	# program error



