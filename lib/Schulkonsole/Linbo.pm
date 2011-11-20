use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Config;
use File::Basename;


package Schulkonsole::Linbo;

=head1 NAME

Schulkonsole::Linbo - interface to read and write files

=head1 SYNOPSIS

 use Schulkonsole::Linbo;
 use Schulkonsole::Session;

 my $session = new Schulkonsole::Session('file.cgi');
 my $id = $session->userdata('id');
 my $password = $session->get_password();

 my $lines = Schulkonsole::Linbo::read_start_conf('start.conf');

 Schulkonsole::Linbo::write_start_conf($id, $password,
 	'start.conf', $lines);

=head1 DESCRIPTION

Schulkonsole::Linbo is an interface to manipulate configuration files of
linbo.

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.0917;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	groups
	regpatches
	example_regpatches
	pxestarts
	images

	update_linbofs
	read_start_conf
	get_conf_from_query
	write_start_conf
	copy_start_conf
	copy_regpatch
	create_start_conf_from_template
	check_and_prepare_start_conf
	handle_start_conf_errors
	write_file
	delete_file
	delete_image
	move_image
	copy_image

	is_boolean

	get_templates_os

	%_allowed_keys
);
use vars qw(%_allowed_keys);



%_allowed_keys = (
	1 => {	# [Partition]
		dev => 1,
		size => 2,
		id => 3,
		fstype => 1,
		bootable => 4,
	},
	2 => {	# [OS]
		name => 1,
		version => 1,
		description => 1,
		image => 1,
		baseimage => 1,
		boot => 1,
		root => 1,
		kernel => 1,
		initrd => 1,
		append => 1,
		startenabled => 4,
		syncenabled => 4,
		newenabled => 4,
		hidden => 4,
		autostart => 4,
	},
	3 => {	# [LINBO]
		group => 1,
		cache => 1,
		server => 1,
		downloadtype => 1,
		roottimeout => 2,
		autopartition => 4,
		autoformat => 4,
		autoinitcache => 4,
		backgroundfontcolor => 1,
		consolefontcolorstdout => 1,
		consolefontcolorstderr => 1,
	},
);






my $input_buffer;
sub buffer_input {
	my $in = shift;

	while (<$in>) {
		$input_buffer .= $_;
	}
}




sub start_wrapper {
	my $app_id = shift;
	my $id = shift;
	my $password = shift;
	my $out = shift;
	my $in = shift;
	my $err = shift;

	my $pid = IPC::Open3::open3 $out, $in, $err,
		$Schulkonsole::Config::_wrapper_linbo
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_linbo, $!);

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_wrapper_linbo, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_LINBO_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_linbo);
		}
	}

	print $out "$id\n$password\n$app_id\n";





	return $pid;
}




sub stop_wrapper {
	my $pid = shift;
	my $out = shift;
	my $in = shift;
	my $err = shift;

	my $re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::Config::_wrapper_linbo, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_LINBO_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_linbo);
		}
	}

	if ($out) {
		close $out
			or die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
				$Schulkonsole::Config::_wrapper_linbo, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
	}

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_linbo, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	undef $input_buffer;
}




=head2 Functions

=cut





=head2 groups()

Get all groups that have a start.conf.*

=head3 Return value

A reference to a hash with the group names as keys

=head3 Description

Extracts the groupname from the filenames /var/linbo/start.conf.<GROUP>
and returns them in a hash.

=cut

sub groups {
	my @files = glob($Schulkonsole::Config::_linbo_start_conf_prefix . '*');

	my %re;
	# this will take all files, that start with _linbo_start_conf_prefix
	# plus a valid group name and optionally an arbitrary suffix (except it
	# ends with '~')
	foreach my $file (@files) {
		next if $file =~ /~$/;	# skip editor backup files
		my ($group) = $file =~ /^\Q${Schulkonsole::Config::_linbo_start_conf_prefix}\E([a-z\d_]+.*)/;
		next unless $group;

		$re{$group} = 1;
	}

	return \%re;
}




=head2 regpatches()

Get all regpatches

=head3 Return value

A reference to a hash with the regpatches as keys

=head3 Description

Gets the regpatches in /var/linbo/
and returns them in a hash.

=cut

sub regpatches {
	my %re;

	foreach my $file ((
			glob("$Schulkonsole::Config::_linbo_dir/*.cloop.reg"),
			glob("$Schulkonsole::Config::_linbo_dir/*.rsync.reg")
		)) {
		my ($filename) = File::Basename::fileparse($file);
		$re{$filename} = $file;
	}

	return \%re;
}




=head2 example_regpatches()

Get all example regpatches

=head3 Return value

A reference to a hash with the regpatches as keys

=head3 Description

Gets the regpatches in /var/linbo/examples/
and returns them in a hash.

=cut

sub example_regpatches {
	my %re;

	foreach my $file ((
			glob("$Schulkonsole::Config::_linbo_dir/examples/*.reg"),
		)) {
		my ($filename) = File::Basename::fileparse($file);
		$re{$filename} = $file;
	}

	return \%re;
}




=head2 images()

Get all images

=head3 Return value

A reference to a hash with the images as keys

=head3 Description

Gets the images in /var/linbo/
and returns them in a hash.

=cut

sub images {
	my %re;

	foreach my $file ((
			glob("$Schulkonsole::Config::_linbo_dir/*.cloop"),
			glob("$Schulkonsole::Config::_linbo_dir/*.rsync")
		)) {
		my ($filename) = File::Basename::fileparse($file);
		$re{$filename} = $file;
	}

	return \%re;
}






=head2 pxestarts()

Get all PXE start files

=head3 Return value

A reference to a hash with the filenames as keys

=head3 Description

Gets the PXE start files in /var/linbo/
and returns them in a hash.

=cut

sub pxestarts {
	my %re;

	foreach my $file ((
			glob("$Schulkonsole::Config::_linbo_dir/pxegrub.lst.*")
		)) {
		my ($filename) = File::Basename::fileparse($file);
		$re{$filename} = $file if $filename =~ /^pxegrub\.lst\.(?:[a-z\d_]+)$/;
	}

	return \%re;
}




=head2 update_linbofs($id, $password)

Updates LINBO stuff

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head4 Return value

True if active, false otherwise

=head3 Description

This wraps the command C<update-linbofs.sh>.

=cut

sub update_linbofs {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::UPDATELINBOFSAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}




=head2 read_start_conf($group)

Read a start.conf.*

=head3 Parameteres

=over

=item C<$group>

The name of a group

=back

=head3 Return value

A reference to a hash with the following keys and values:

=head3 Description

Reads /var/linbo/start.conf.<group>, where group is C<$group> and returns
the contents in a hash.

=cut

sub read_start_conf {
	my $group = shift;

	my $filename = $Schulkonsole::Config::_linbo_start_conf_prefix . $group;

	open CONF, "<$filename" or die new Schulkonsole::Error(
			Schulkonsole::Error::CANNOT_OPEN_FILE, $filename, $!);
	flock CONF, 1;
	seek CONF, 0, 0;


	my %partitions;
	my @oss;
	my %linbo;
	my $partition = {};
	my $os = {};
	my $section;
	my $unnamed_partitions_cnt = 0;
	while (<CONF>) {
		next if /^\s*#/ || /^\s*$/;
		s/#.*//;
		s/\s+$//;

		if (my ($section_str) = /^\[(Partition|OS|LINBO)\]$/i) {
			if (%$os) {
				push @oss, $os;
				$os = {};
			} elsif (%$partition) {
				if (not $$partition{dev}) {
					$partitions{"? $unnamed_partitions_cnt"} = $partition;
					$unnamed_partitions_cnt++;
				} else {
					$partitions{$$partition{dev}} = $partition;
				}
				$partition = {};
			}

			if ($section_str =~ /^P/i) {
				$section = 1;
			} elsif ($section_str =~ /^L/i) {
				$section = 3;
			} elsif ($section_str =~ /^O/i) {
				$section = 2;
			}
		} elsif (my ($key, $value) = /^(\S+)\s*=\s*(.*)$/) {
			$key = lc $key;
			if (my $type = $_allowed_keys{$section}{$key}) {
				SWITCHTYPE: {
				$type == 1 and do {	# string
					last SWITCHTYPE;
				};
				$type == 2 and do {	# decimal number
					last SWITCHTYPE;
				};
				$type == 3 and do {	# hex number
					$value = hex $value;
					last SWITCHTYPE;
				};
				$type == 4 and do {	# boolean yes/no
					$value = ($value =~ /yes/i ? 1 : 0);
					last SWITCHTYPE;
				};
				}
				if ($section == 1) {
					$$partition{$key} = $value;
				} elsif ($section == 2) {
					$$os{$key} = $value;
				} elsif ($section == 3) {
					$linbo{$key} = $value;
				}
			} else {
				die new Schulkonsole::Error(
					Schulkonsole::Error::FILE_FORMAT_ERROR, $filename, $.);
			}
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::FILE_FORMAT_ERROR, $filename, $.);
		}
	}
	close CONF;

	if (%$os) {
		push @oss, $os;
		$os = {};
	} elsif (%$partition) {
		if (not $$partition{dev}) {
			$partitions{"? $unnamed_partitions_cnt"} = $partition;
			$unnamed_partitions_cnt++;
		} else {
			$partitions{$$partition{dev}} = $partition;
		}
		$partition = {};
	}



	foreach my $os (@oss) {
		my $partition = $$os{root};

		if (not exists $partitions{$partition}) {
			$partitions{$partition} = {
					dev => $partition,
					id => ($$os{kernel} eq ('grub.exe' || 'reboot') ? 0x07 : 0x83),
				};
		}

		if (not $$os{baseimage}) {
			# '/' not allowed on ext2, ext3 and ntfs
			my $imagename = "$$os{name}-$group";
			$imagename =~ tr,/,-,;
			($$os{baseimage}) = $imagename;
		} else {
			$$os{baseimage} =~ s/\.cloop$//;
		}

		$$os{image} =~ s/\.rsync$//;

		push @{ $partitions{$partition}{oss} }, $os;
	}


	return {
		partitions => \%partitions,
		linbo => \%linbo,
	};
}




=head2 check_and_prepare_start_conf($conf)

Check a configuration hash

=head3 Parameteres

=over

=item C<$conf>

Reference to a hash with the configuration

=back

=head3 Description

Checks if the semantic structure of C<%$conf> is valid. Dies with a
Schulkonsole::Error if not.

=cut

sub check_and_prepare_start_conf {
	my $conf = shift;
	my %re;
	my %errors;


	my %windows_ignore = (
		'boot' => 1,
		'initrd' => 1,
		'append' => 1,
	);
	my %not_empty = (
		'baseimage' => 1,
		'boot' => 1,
		'kernel' => 1,
	);


	## [LINBO]
	foreach my $key (keys %{ $_allowed_keys{3} }) {
		my $value = string_to_type($_allowed_keys{3}{$key},
		                           $$conf{linbo}{$key});
		if (not defined $value) {
			$errors{linbo}{$key} = 2;
			next;
		}

		$re{linbo}{$key} = $value;
	}
	$errors{linbo}{cache} = 3 unless $$conf{linbo}{cache};


	## [Partition]s

	my %has_extended;
	my %max_primary_partition;
	my %max_logical_partition;

	# sort, so that we know if for a logical partition an extended partition
	# exists
	foreach my $partition (sort {
			my ($name_a, $number_a) = $$conf{partitions}{$a}{dev} =~ /^(.*?)(\d*)$/;
			my ($name_b, $number_b) = $$conf{partitions}{$b}{dev} =~ /^(.*?)(\d*)$/;

			return (   $name_a cmp $name_b
			        or $number_a <=> $number_b);
		} keys %{ $$conf{partitions} }) {
		my $dev = $$conf{partitions}{$partition}{dev};

		# check for non-empty dev
		if (not $dev) {
			$errors{partitions}{$partition}{partition}
				= $$conf{partitions}{$partition};
			$errors{partitions}{$partition}{errors}{dev} = 1;
			next;
		}


		# check for doubly defined partition
		if (exists $re{partitions}{$dev}) {
			$errors{partitions}{$partition}{partition}
				= $$conf{partitions}{$partition};
			$errors{partitions}{$partition}{errors}{dev} = 3;
			next;
		}

		# check for valid primary/logical structure
		my ($dev_name, $dev_number) = $dev =~ /^(.*?)(\d*)$/;
		if ($dev_number > 4) {
		    if (not $has_extended{$dev_name}) {
				$errors{partitions}{$partition}{partition}
					= $$conf{partitions}{$partition};
				$errors{partitions}{$partition}{errors}{dev} = 4;
				next;
			}
			$max_logical_partition{$dev_name} = $dev_number;
		} else {
			$max_primary_partition{$dev_name} = $dev_number;
		}


		# check for valid cache partition
		if ($dev eq $$conf{linbo}{cache}) {
			if (exists $$conf{partitions}{$partition}{oss}) {
				$errors{partitions}{$partition}{partition}
					= $$conf{partitions}{$partition};
				$errors{partitions}{$partition}{errors}{oss} = 8;
				next;
			} elsif ($$conf{partitions}{$partition}{id} != 0x83) {
				$errors{partitions}{$partition}{partition}
					= $$conf{partitions}{$partition};
				$errors{partitions}{$partition}{errors}{id} = 9;
				next;
			}
		}



		foreach my $key (keys %{ $_allowed_keys{1} }) {
			my $value = string_to_type($_allowed_keys{1}{$key},
			                           $$conf{partitions}{$partition}{$key});
			if (not defined $value) {
				$errors{partitions}{$partition}{errors}{$key} = 2;
				next;
			}


			$re{partitions}{$dev}{$key} = $value;
		}
		if (    exists $errors{partitions}
		    and exists $errors{partitions}{$partition}) {
			$errors{partitions}{$partition}{partition}
				= $$conf{partitions}{$partition};
		}






		if ($$conf{partitions}{$partition}{id} == 0x05) { # extended
			my ($disk, $number)
				= $$conf{partitions}{$partition}{dev} =~ /^(.*?)(\d*)$/;
			if ($has_extended{$disk}) {
				$errors{partitions}{$partition}{partition}
					= $$conf{partitions}{$partition};
				$errors{partitions}{$partition}{errors}{dev} = 5;
				next;
			} elsif ($number > 4) {
				$errors{partitions}{$partition}{partition}
					= $$conf{partitions}{$partition};
				$errors{partitions}{$partition}{errors}{dev} = 6;
			} else {
				$has_extended{$disk} = 1;
			}
			$re{partitions}{$dev}{fstype} = '';
		} elsif (exists $$conf{partitions}{$partition}{oss}) {
	## [OS]s
			my $id = $$conf{partitions}{$partition}{id};
			my $is_windows = ($id != 0x83);


			my $dev_n = $$conf{partitions}{$partition}{n};
			foreach my $os (@{ $$conf{partitions}{$partition}{oss} }) {
				my $name = $$os{name};
				my $n = "$dev_n.$$os{n}";

				# check for empty name
				if (not $name) {
					$errors{oss}{$n}{partition}
						= $$conf{partitions}{$partition};
					$errors{oss}{$n}{os} = $os;
					$errors{oss}{$n}{errors}{name} = 1;
					next;
				}
				my $version = $$os{version};

				# check if host + version is unique
				if (exists $re{oss}{$name}{$version}) {
					$errors{oss}{$n}{partition}
						= $$conf{partitions}{$partition};
					$errors{oss}{$n}{os} = $os;
					$errors{oss}{$n}{errors}{version} = 10;
					next;
				}


				if (    $$os{baseimage}
				    and $$os{baseimage} !~ /\.cloop$/) {
					$$os{baseimage} .= '.cloop';
				}
				if (    $$os{image}
				    and $$os{image} !~ /\.rsync$/) {
					$$os{image} .= '.rsync';
				}


				foreach my $key (keys %{ $_allowed_keys{2} }) {
					next if ($is_windows and $windows_ignore{$key});

					my $value
						= string_to_type($_allowed_keys{2}{$key}, $$os{$key});
					if (not defined $value) {
						$errors{oss}{$n}{errors}{$key} = 2;
						next;
					} elsif (    not $value
					         and $not_empty{$key}) {
						$errors{oss}{$n}{errors}{$key} = 1;
					}

					$re{oss}{$name}{$version}{$key} = $value;
				}


				# if there were errors, add some information
				if (    exists $errors{oss}
				    and exists $errors{oss}{$n}) {
					$errors{oss}{$n}{partition}
						= $$conf{partitions}{$partition};
					$errors{oss}{$n}{os} = $os;
				}

				$re{oss}{$name}{$version}{root} = $dev;
				if ($is_windows) {
					$re{oss}{$name}{$version}{boot}
						= $re{oss}{$name}{$version}{root};
					$re{oss}{$name}{$version}{initrd} = '';
				}
			}



		# end if (exists $$conf{partitions}{$partition}{oss})
		} elsif ($$conf{partitions}{$partition}{id} == 0x82) {	# Swap
			$re{partitions}{$dev}{fstype} = 'swap';
		}

	}


	# check if size is set (if it has to be set)
	foreach my $partition (keys %{ $$conf{partitions} }) {
		my $dev = $$conf{partitions}{$partition}{dev};

		my ($name, $number) = $dev =~ /^(.*?)(\d*)$/;
		if (    exists $re{partitions}{$dev}{size}
		    and not $re{partitions}{$dev}{size}) {
			if ($number > 4) {
				if ($number < $max_logical_partition{$name}) {
					$errors{partitions}{$partition}{partition}
						= $$conf{partitions}{$partition};
					$errors{partitions}{$partition}{errors}{size} = 7;
				}
			} elsif ($number < $max_primary_partition{$name}) {
				$errors{partitions}{$partition}{partition}
					= $$conf{partitions}{$partition};
				$errors{partitions}{$partition}{errors}{size} = 7;
			}
		}
	}


	die new Schulkonsole::Error(Schulkonsole::Error::LINBO_START_CONF_ERROR,
	                            \%errors)
		if %errors;

	return \%re;
}




=head2 handle_start_conf_errors($errors, $session)

Set error-fields in Schulkonsole::Session object

=head3 Parameteres

=over

=item C<$errors>

Reference to a hash with the errors in the sections

 'linbo' => {
	<key> => 1	# value empty
	         2	# value contains invalid characters
 	'cache' => 3	# no cache partition
 },
 'partitions' => {
 	<dev> => {
		'partition' => <ref>,	# reference to partition hash
		'errors' => {
			<key> => 1	# value empty
			         2	# value contains invalid characters

			'dev' => 3	# device name not unique
			         4	# logical partition without extended partition
			         5	# disk already has extended partition
			         6	# extended partition must be <= 4
			'size' => 7	# empty size on non-last partiton
			'oss' => 8	# oss defined on cache partition
			'id' => 9	# invalid partition id for cache
		}
	}
 },
 'oss' => {
 	<os> => {
		'partition' => <ref>,	# reference to partition hash
		'os' => <ref>,	# reference to os hash
		'errors' => {
			<key> => 1	# name empty
			         2	# name contains invalid characters
			'version' => 10	# name + version is not unique
		}
	}
 }

=item C<$session>

The Schulkonsole::Session object

=back

=head3 Description

Reads errors from C<%$errors> and marks input fields and sets status in
C<$session>.

=cut

sub handle_start_conf_errors {
	my $errors = shift;
	my $session = shift;


	my %key_descr = (
        'baseimage' => $session->d()->get('Dateiname des Basis-Image'),
		'boot' => $session->d()->get('Partition, die Kernel und initrd enthält'),
		'kernel' => $session->d()->get('Pfad zum Kernel'),
	);

	my @errors;
	foreach my $section (keys %$errors) {
		if ($section eq 'oss') {
			foreach my $n (keys %{ $$errors{oss} }) {
				my $os = $$errors{oss}{$n}{os};

				my $os_name = ($$os{version} ? $$os{name} . $$os{version} : $$os{name});
				my $dev = $$errors{oss}{$n}{partition}{dev};

				foreach my $key (keys %{ $$errors{oss}{$n}{errors} }) {
					$session->mark_input_error("${n}_$key");
					my $code = $$errors{oss}{$n}{errors}{$key};
					my $key_descr = ($key_descr{$key} || "\u$key");
					if ($code == 1) {
						push @errors, sprintf($session->d()->get('Leerer Wert f&uuml;r &#8222;%s&#8220; bei %s auf %s'),
									$key_descr, $os_name, $dev);
					} elsif ($code == 2) {
						push @errors, sprintf($session->d()->get('Ung&uuml;ltige Zeichen f&uuml;r &#8222;%s&#8220; bei %s auf %s'),
									$key_descr, $os_name, $dev);
					} elsif ($code == 10) {
						push @errors, sprintf($session->d()->get('Name mit Version (&#8222;%s&#8220;) muss bei Betriebssystemen eindeutig sein.'), $os_name);
					} else {
						push @errors, sprintf($session->d()->get(
						                      'Unbekannter Fehler f&uuml;r %s bei %s auf %s'),
											  $key,
						                      $os_name, $dev);
					}
				}
			}
		} elsif ($section eq 'partitions') {
			foreach my $partition (keys %{ $$errors{partitions} }) {
				my $n = $$errors{partitions}{$partition}{partition}{n};
				my $dev =    $$errors{partitions}{$partition}{partition}{dev}
				          || $session->d()->get('unbenannt');

				foreach my $key (keys %{ $$errors{partitions}{$partition}{errors} }) {
					$session->mark_input_error("${n}_$key");

					my $code = $$errors{partitions}{$partition}{errors}{$key};
					if ($code == 1) {
						if ($key eq 'dev') {
							push @errors, $session->d()->get('leerer Devicename');
						} else {
							push @errors, $session->d()->get('leerer Wert');
						}
					} elsif ($code == 2) {
						if ($key eq 'dev') {
							push @errors, sprintf($session->d()->get(
							                      '%s ist kein g&uuml;ltiger Devicename'), $dev);
						} else {
							push @errors, $session->d()->get('ung&uuml;ltige Zeichen');
						}
					} elsif ($code == 3) {
						push @errors, sprintf($session->d()->get(
						                      '%s wird mehrmals verwendet'), $dev);
					} elsif ($code == 4) {
						push @errors, sprintf($session->d()->get(
						                      'F&uuml;r die Partition %s existiert keine erweiterte Partition'), $dev);
					} elsif ($code == 5) {
						my ($disk) = $dev =~ /^(.+?)\d*$/;
						push @errors, sprintf($session->d()->get(
						                      'F&uuml;r %s existieren mehrere erweiterte Partitionen'), $disk);
					} elsif ($code == 6) {
						push @errors, sprintf($session->d()->get(
						                      'Die erweiterte Partition %s ist nicht erlaubt'), $dev);
					} elsif ($code == 7) {
						push @errors, sprintf($session->d()->get(
						                      'Bei %s muss eine Gr&ouml;&szlig;e angegeben werden'), $dev);
					} elsif ($code == 8) {
						push @errors, sprintf($session->d()->get(
						                      'Auf der Cachepartition %s darf kein Betriebssystem installiert sein'), $dev);
					} elsif ($code == 10) {
						push @errors, sprintf($session->d()->get(
						                      'Die Cachepartition %s ben&ouml;tigt ein GNU/Linux-Dateisystem'), $dev);
					} else {
						push @errors, sprintf($session->d()->get(
						                      'Unbekannter Fehler bei %s/%s'),
						                      $dev, $key);
					}
				}
			}
		} elsif ($section eq 'linbo') {
			foreach my $key (keys %{ $$errors{$section} }) {
				$session->mark_input_error("linbo_$key");
				if ($$errors{$section}{$key} == 1) {
					push @errors, $session->d()->get('leerer Wert');
				} elsif ($$errors{$section}{$key} == 2) {
					push @errors, $session->d()->get('ung&uuml;ltige Zeichen');
				} else {	# short cut (error code is 3 => cache)
					push @errors, $session->d()->get('keine Cachepartition');
				}
			}
		}
	}

	my $last;
	my @unique_errors = grep($_ ne $last && (($last) = $_), sort @errors);
	$session->set_status(join(', ', @unique_errors), 1);
}




=head2 write_start_conf($id, $password, $group, $conf)

Write a start.conf.*

=head3 Parameteres

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$group>

The name of a group

=item C<$conf>

The configuration

=back

=head3 Description

Writes /var/linbo/start.conf.<group>, where group is C<$group>, using
the values of C<$conf>

=cut

sub write_start_conf {
	my $id = shift;
	my $password = shift;

	my $group = shift;
	my $conf = shift;

	$$conf{linbo}{group} = $group;
	my $start_conf = check_and_prepare_start_conf($conf);


	my $filename = $Schulkonsole::Config::_linbo_start_conf_prefix . $group;

	open CONF, "<$filename" or die new Schulkonsole::Error(
			Schulkonsole::Error::CANNOT_OPEN_FILE, $filename, $!);


	my $initial_comments;
	my $end_comments;
	my @sections;

	my $linbo;
	my %partitions;	# key: device name
	my %oss;	# key: name . # . version

	my $line;
	# collect comments at start of file
	while ($line = <CONF>) {
		if ($line =~ /^\s*#/) {
			$initial_comments .= $line;
		} else {
			last;
		}
	}

	if (defined $line) {
		my $pre_comments;
		my $section;
		my $keys;
		my $key;
		do {
			if ($line =~ /^\s*#/) {	# comments
				if ($key) {
					$$keys{$key}{Post} .= $line;
				} else {
					$pre_comments .= $line;
				}
			} elsif ($line =~ /^\s*$/) {	# empty lines
				$key = undef if $key;
				$pre_comments .= $line;
			} elsif ($line =~ /^\[(.+)\]/) {	# sections
				if ($section) {
					if ($$section{Name} =~ /^OS$/i) {
						my $name = $$section{Keys}{name}{Value};
						if ($name) {
							my $version = $$section{Keys}{version}{Value};
							my $name_version = "$name#$version";

							if (   exists $$start_conf{oss}{$name}{$version}
							    or (    exists $$start_conf{oss}{$name}
								    and keys %{ $$start_conf{oss}{$name} } == 1)) {
								$oss{$name_version} = $section;
								foreach my $key (keys %{ $$start_conf{oss}{$name}{$version} }) {
									$oss{$name_version}{Keys}{$key}{Value} = $$start_conf{oss}{$name}{$version}{$key};
								}
								delete $$start_conf{oss}{$name}{$version};
							}
						}

					} elsif ($$section{Name} =~ /^Pa/i) {
						my $dev = $$section{Keys}{dev}{Value};

						if (    $dev
						    and exists $$start_conf{partitions}{$dev}) {
							$partitions{$dev} = $section;
							foreach my $key (keys %{ $$start_conf{partitions}{$dev} }) {
								$partitions{$dev}{Keys}{$key}{Value} = $$start_conf{partitions}{$dev}{$key};
							}
							delete $$start_conf{partitions}{$dev};
						}

					} elsif ($$section{Name} =~ /^L/) {
						$linbo = $section;
						foreach my $key (keys %{ $$start_conf{linbo} }) {
							$$linbo{Keys}{$key}{Value} = $$start_conf{linbo}{$key};
						}
						delete $$start_conf{linbo};
					} else {
						die;
					}
				}
				$section = {
					Name => $1,
					Pre => $pre_comments,
					Keys => {},
					Line => $line,
				};
				$pre_comments = '';
				$keys = $$section{Keys};
			} elsif ($line =~ /^(\S+)\s*=\s*?(\S.*?)?\s*(#.*)?$/) {	# key/value
				$key = lc $1;
				$$keys{$key} = {
					Key => $1,
					Value => $2,
					Pre => $pre_comments,
					Line => $line,
				};
				$pre_comments = '';
			} else {
				die;
			}
		} while ($line = <CONF>);

		if ($section) {
			if ($$section{Name} =~ /^OS$/i) {
				my $name = $$section{Keys}{name}{Value};

				if ($name) {
					my $version = $$section{Keys}{version}{Value};
					my $name_version = "$name#$version";

					if (   exists $$start_conf{oss}{$name}{$version}
					    or (    exists $$start_conf{oss}{$name}
						    and keys %{ $$start_conf{oss}{$name} } == 1)) {
						$oss{$name_version} = $section;
						foreach my $key (keys %{ $$start_conf{oss}{$name}{$version} }) {
							$oss{$name_version}{Keys}{$key}{Value} = $$start_conf{oss}{$name}{$version}{$key};
						}
						delete $$start_conf{oss}{$name}{$version};
					}
				}

			} elsif ($$section{Name} =~ /^Pa/i) {
				my $dev = $$section{Keys}{dev}{Value};

				if (    $dev
				    and exists $$start_conf{partitions}{$dev}) {
					$partitions{$dev} = $section;
					foreach my $key (keys %{ $$start_conf{partitions}{$dev} }) {
						$partitions{$dev}{Keys}{$key}{Value} = $$start_conf{partitions}{$dev}{$key};
					}
					delete $$start_conf{partitions}{$dev};
				}

			} elsif ($$section{Name} =~ /^L/) {
				$linbo = $section;
				foreach my $key (keys %{ $$start_conf{linbo} }) {
					$$linbo{Keys}{$key}{Value} = $$start_conf{linbo}{$key};
				}
				delete $$start_conf{linbo};
			} else {
				die "unknown section $$section{Name}\n";
			}
		}
		$end_comments = $pre_comments;
	}

	close CONF;



	foreach my $name (keys %{ $$start_conf{oss} }) {
		foreach my $version (keys %{ $$start_conf{oss}{$name} }) {
			my $name_version = "$name#$version";
			$oss{$name_version}{Pre} = "\n\n\n";
			foreach my $key (keys %{ $$start_conf{oss}{$name}{$version} }) {
				$oss{$name_version}{Keys}{$key}{Value} = $$start_conf{oss}{$name}{$version}{$key};
			}
		}
	}

	foreach my $dev (keys %{ $$start_conf{partitions} }) {
		$partitions{$dev}{Pre} = "\n\n\n";
		foreach my $key (keys %{ $$start_conf{partitions}{$dev} }) {
			$partitions{$dev}{Keys}{$key}{Value} = $$start_conf{partitions}{$dev}{$key};
		}
	}

	if ($$start_conf{linbo}) {
		foreach my $key (keys %{ $$start_conf{linbo} }) {
			$$linbo{Keys}{$key}{Value} = $$start_conf{linbo}{$key};
		}
	}


	## Create conf

	my $lines = $initial_comments;


	# [LINBO]
	$lines .= $$linbo{Pre} if $$linbo{Pre};
	if ($$linbo{Line}) {
		if ($$linbo{Name} ne 'LINBO') {
			$$linbo{Line} =~ s/\[$$linbo{Name}\]/[LINBO]/;
		}
		$lines .= $$linbo{Line};
	} else {
		$lines .= "[LINBO]\n";
	}
	foreach my $key (('Cache', 'Server', 'Group', 'RootTimeout',
	                  'Autopartition', 'AutoFormat', 'AutoInitCache',
	                  'DownloadType', 'BackgroundFontColor',
                          'ConsoleFontColorStdout', 'ConsoleFontColorStderr')) {
		my $key_data = $$linbo{Keys}{lc $key};
		next unless $key_data;

		$lines .= $$key_data{Pre} if $$key_data{Pre};
		$lines .= line_with_new_value($key, $$key_data{Value}, $$key_data{Line});
		$lines .= $$key_data{Post} if $$key_data{Post};
	}


	# [Partition]s
	foreach my $dev (sort {
			my ($name_a, $number_a) = $a =~ /^(.*?)(\d*)$/;
			my ($name_b, $number_b) = $b =~ /^(.*?)(\d*)$/;

			return (   $name_a cmp $name_b
			        or $number_a <=> $number_b);
		} keys %partitions) {
		$lines .= $partitions{$dev}{Pre};
		if ($partitions{$dev}{Line}) {
			if ($partitions{$dev}{Name} ne 'Partition') {
				$partitions{$dev}{Line} =~ s/\[$partitions{$dev}{Name}\]/[Partition]/;
			}
			$lines .= $partitions{$dev}{Line};
		} else {
			$lines .= "[Partition]\n";
		}

		foreach my $key (('Dev', 'Size', 'Id', 'FSType', 'Bootable', )) {
			my $key_data = $partitions{$dev}{Keys}{lc $key};
			next unless $key_data;

			$lines .= $$key_data{Pre} if $$key_data{Pre};
			$lines .= line_with_new_value($key, $$key_data{Value}, $$key_data{Line});
			$lines .= $$key_data{Post} if $$key_data{Post};
		}
	}


	# [OS]s
	foreach my $name_version (sort {
			# device name
			my ($dev_name_a, $dev_number_a) = $oss{$a}{Keys}{root}{Value} =~ /^(.*?)(\d*)$/;
			my ($dev_name_b, $dev_number_b) = $oss{$b}{Keys}{root}{Value} =~ /^(.*?)(\d*)$/;

			my $re = (   $dev_name_a cmp $dev_name_b
			          or $dev_number_a <=> $dev_number_b);
			return $re if $re;

			# name
			$re = lc $oss{$a}{Keys}{name}{Value} cmp lc $oss{$b}{Keys}{name}{Value};
			return $re if $re;

			# no diff image < with diff image
			if (not $oss{$a}{Keys}{image}{Value}) {
				if ($oss{$b}{Keys}{image}{Value}) {
					return -1;
				}
			} elsif (not $oss{$b}{Keys}{image}{Value}) {
				return 1;
			}


			# version
			return lc $oss{$a}{Keys}{version}{Value} cmp lc $oss{$b}{Keys}{version}{Value};
		} keys %oss) {
		$lines .= $oss{$name_version}{Pre};
		if ($oss{$name_version}{Line}) {
			if ($oss{$name_version}{Name} ne 'OS') {
				$oss{$name_version}{Line}
					=~ s/\[$oss{$name_version}{Name}\]/[OS]/;
			}
			$lines .= $oss{$name_version}{Line},
		} else {
			$lines .= "[OS]\n";
		}
		foreach my $key (('Name', 'Version', 'Description', 'Image',
		                  'BaseImage', 'Boot', 'Root', 'Kernel', 'Initrd',
		                  'Append', 'StartEnabled', 'SyncEnabled',
		                  'NewEnabled', 'Hidden', 'Autostart',)) {
			my $key_data = $oss{$name_version}{Keys}{lc $key};
			next unless $key_data;

			$lines .= $$key_data{Pre} if $$key_data{Pre};
			$lines .= line_with_new_value($key, $$key_data{Value}, $$key_data{Line});
			$lines .= $$key_data{Post} if $$key_data{Post};
		}
	}


	# write file

	my $pid = start_wrapper(Schulkonsole::Config::LINBOWRITESTARTCONFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$group\n$lines";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);

	# update linbofs
	update_linbofs($id, $password);
}




=head2 copy_start_conf($id, $password, $src, $dest)

Copy a start.conf.*

=head3 Parameteres

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$src>

The name of the source group

=item C<$dest>

The name of the destination group

=back

=head3 Description

Copies /var/linbo/start.conf.C<$src> to /var/linbo/start.conf.C<$dest>, and
there sets the value of C<Group> in section [LINBO] to C<$dest>.

=cut

sub copy_start_conf {
	my $id = shift;
	my $password = shift;

	my $src = shift;
	my $dest = shift;


	my $pid = start_wrapper(Schulkonsole::Config::LINBOCOPYSTARTCONFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$src\n$dest\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}




=head2 copy_regpatch($id, $password, $regpatch, $image)

Create a regpatch from template

=head3 Parameteres

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$regpatch>

The name of the template file

=item C<$is_example>

True if the regpatch is in the examples directory

=item C<$image>

The name of the image file of the new regpatch

=back

=head3 Description

Copies /var/linbo/start.conf.C<$src> to /var/linbo/start.conf.C<$dest>, and
there sets the value of C<Group> in section [LINBO] to C<$dest>.

=cut

sub copy_regpatch {
	my $id = shift;
	my $password = shift;

	my $regpatch = shift;
	my $is_example = shift;
	my $image = shift;


	my $pid = start_wrapper(Schulkonsole::Config::LINBOCOPYREGPATCHAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$regpatch\n", ($is_example ? 1 : 0), "\n$image\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}




=head2 create_start_conf_from_template($id, $password, $group, $server,
                                       $device,
                                       $os_template_1, $os_size_1,
                                       $os_template_2, $os_size_2,
                                       $os_template_3, $os_size_3,
                                       $os_template_4, $os_size_4))

Create start.conf.* from templates

=head3 Parameteres

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$group>

The name of the workstation group

=item C<$server>

The server IP address

=item C<$device>

The disk device

=item C<$os_template_1>

Template for first OS

=item C<$os_size_1>

Size of partition of first OS in KiB

=item C<$os_template_2>

Template for second OS

=item C<$os_size_2>

Size of partition of second OS in KiB

=item C<$os_template_3>

Template for third OS

=item C<$os_size_3>

Size of partition of third OS in KiB

=item C<$os_template_4>

Template for fourth OS

=item C<$os_size_4>

Size of partition of fourth OS in KiB

=back

=head3 Description

Creates /var/linbo/start.conf.C<$group> from templates in
C</usr/share/schulkonsole/linbo/templates/os> and
C</usr/share/schulkonsole/linbo/templates/part/start.conf.partition>.

=cut

sub create_start_conf_from_template {
	my $id = shift;
	my $password = shift;

	my $group = shift;
	my $server = shift;
	my $device = shift;

	my @os_templates;
	my @os_sizes;
	my @ids;
	my @fss;
	my $total_size;
	for (my $i = 0; $i < 4; $i++) {
		push @os_templates, shift;
		push @os_sizes, shift;
		$total_size += $os_sizes[-1];
		if ($os_templates[-1]) {
			if ($i < 2) {
				push @ids, 'c';
				push @fss, 'vfat';
			} else {
				push @ids, '83';
				push @fss, 'ext3';
			}
		} else {
			push @ids, '83';
			push @fss, 'ext2';
		}
	}


	my $cache_size = int($total_size / 2 + .5);




	my @lines;

	open PART, "<$Schulkonsole::Config::_linbo_template_partition"
		or die new Schulkonsole::Error(
			Schulkonsole::Error::CANNOT_OPEN_FILE,
			$Schulkonsole::Config::_linbo_template_partition, $!);

	while (<PART>) {
		s/\$RECHNERGRUPPE/$group/g;
		s/\$DEVICE/$device/g;
		s/\$SERVER-IP/$server/g;
		s/\$PART1/$os_sizes[0]/g;
		s/\$ID1/$ids[0]/g;
		s/\$FS1/$fss[0]/g;
		s/\$PART2/$os_sizes[1]/g;
		s/\$ID2/$ids[1]/g;
		s/\$FS2/$fss[1]/g;
		s/\$PART5/$os_sizes[2]/g;
		s/\$ID5/$ids[2]/g;
		s/\$FS5/$fss[2]/g;
		s/\$PART6/$os_sizes[3]/g;
		s/\$ID6/$ids[3]/g;
		s/\$FS6/$fss[3]/g;
		s/\$CACHE/$cache_size/g;


		push @lines, $_;
	}

	close PART;



	foreach my $part ((1, 2, 5, 6)) {
		my $template = shift @os_templates;
		next unless $template;

		my $template_file
			= "$Schulkonsole::Config::_linbo_templates_os_dir/$template";
		open TEMPLATE, "<$template_file"
			or die new Schulkonsole::Error(
				Schulkonsole::Error::CANNOT_OPEN_FILE, $template_file, $!);

		while (<TEMPLATE>) {
			s/\$PART/$part/g;
			s/\$RECHNERGRUPPE/$group/g;
			s/\$DEVICE/$device/g;

			push @lines, $_;
		}

		close TEMPLATE;
	}



	# write file

	my $pid = start_wrapper(Schulkonsole::Config::LINBOWRITESTARTCONFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$group\n", join('', @lines);
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}




=head2 get_conf_from_query($q)

Read configuration values from CGI-object

=head3 Parameteres

=over

=item C<$q>

A CGI-object

=back

=head3 Return value

A reference to a hash with the following keys and values:

=head3 Description

Gets parameters from a CGI-query and builds a conf-structure like
C<read_start_conf()>.

=cut

sub get_conf_from_query {
	my $q = shift;

	my $submit;
	my $submit_dev_n;
	my $submit_os_n;
	my $submit_partition;
	my $submit_os;

	my @partition_params;
	my @os_params;
	my %linbo_params;
	my $cache_hd;
	foreach my $param ($q->param) {
		if (my ($dev_n, $os_n, $key) = $param =~ /^(\d+)\.(\d+)_(.+)$/) {
			if ($_allowed_keys{2}{$key}) {
				$os_params[$dev_n][$os_n]{$key} = $q->param($param);
			} elsif ($key eq 'deleteos') {
				$submit = $key;
				$submit_dev_n = $dev_n;
				$submit_os_n = $os_n;
			}
		} elsif (($dev_n, $key) = $param =~ /^(\d+)_(.+)$/) {
			if ($_allowed_keys{1}{$key}) {
				$partition_params[$dev_n]{$key} = $q->param($param)
			} elsif ($key eq 'iscache') {
				$cache_hd = $dev_n;
			} elsif (   $key eq 'addos'
			         or $key eq 'modify'
			         or $key eq 'delete') {
				$submit = $key;
				$submit_dev_n = $dev_n;
			}
		} elsif (($key) = $param =~ /^linbo_(.+)$/) {
			$linbo_params{$key} = $q->param($param)
				if $_allowed_keys{3}{$key};
		} elsif (   $param eq 'accept'
		         or $param eq 'adddevtop'
		         or $param eq 'adddevbottom') {
			$submit = $param;
		}
	}

	return undef unless $submit;


	my %partitions;
	for (my $dev_n = 0; $dev_n < @partition_params; $dev_n++) {
		next unless $partition_params[$dev_n];

		$partitions{$dev_n}{n} = $dev_n;
		foreach my $key (keys %{ $_allowed_keys{1} }) {
			$partitions{$dev_n}{$key} = $partition_params[$dev_n]{$key};
		}

		my $fstype = $partitions{$dev_n}{fstype};
		my $id;
		   ((   $fstype eq 'ext2'
		     or $fstype eq 'ext3'
		     or $fstype eq 'reiserfs') and $id = 0x83)
		or ($fstype eq 'swap' and $id = 0x82)
		or ($fstype eq 'vfat' and $id = 0x0c)
		or ($fstype eq 'ntfs' and $id = 0x07)
		or (not $fstype and $id = 0x05)
		or ($fstype = 'ext3' and $id = 0x83);	# fallback

		$partitions{$dev_n}{id} = $id;
	}


	my $autostart = $q->param('autostart');

	for (my $dev_n = 0; $dev_n < @os_params; $dev_n++) {
		if ($os_params[$dev_n]) {
			for (my $os_n = 0; $os_n < @{ $os_params[$dev_n] }; $os_n++) {
				my $os = $os_params[$dev_n][$os_n];

				$$os{root} = $partition_params[$dev_n]{dev};
				$$os{n} = $os_n;
				$$os{autostart} = ($autostart eq "$dev_n.$os_n" ? 1 : 0);

				push @{ $partitions{$dev_n}{oss} }, $os;
			}

			$partitions{$dev_n}{oss_cnt} = @{ $os_params[$dev_n] };
		}
	}

	if (defined $cache_hd) {
	    if (my $dev = $partition_params[$cache_hd]{dev}) {	# true for valid forms
			# param "${dev_n}_iscache" takes precedence over "linbo_cache"
			if ($linbo_params{cache} ne $dev) {
				$q->param('linbo_cache', $dev);
				$linbo_params{cache} = $partition_params[$cache_hd]{dev};
			}
		} else {
			$linbo_params{cache} = '';
		}
	}


	if (defined $submit_dev_n) {
		if (defined $partitions{$submit_dev_n}) {
			$submit_partition
				= $partitions{$submit_dev_n};

			if (defined $submit_os_n) {
				if (defined $os_params[$submit_dev_n][$submit_os_n]) {
					$submit_os = $os_params[$submit_dev_n][$submit_os_n];
				} else {
					return undef;
				}
			}
		} else {
			return undef;
		}
	}



	return {
		partitions => \%partitions,
		linbo => \%linbo_params,
		partitions_cnt => scalar(@partition_params),
		action => $submit,
		action_partition => $submit_partition,
		action_os => $submit_os,
	};
}




=head2 delete_file($id, $password, $filename)

Deletes a LINBO file

=head3 Parameters

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The basename of the file

=head3 Description

Deletes C<$filename> in C</var/linbo/>. Filename has to match C<*.cloop.reg>,
C<*.rsync.reg>, or C<pxegrub\.lst\.(?:[a-z\d_]+)>.

=cut

sub delete_file {
	my $id = shift;
	my $password = shift;
	my $filename = shift;


	my $pid = start_wrapper(Schulkonsole::Config::LINBODELETEAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$filename\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}





=head2 write_file($id, $password, $filename, $lines)

Writes a LINBO file

=head3 Parameters

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The basename of the file

=item C<$lines>

The lines to be written

=head3 Description

Writes C<$lines> into C<$filename> in C</var/linbo/>. Filename has to
match C<*.cloop.reg>, C<*.rsync.reg>, or C<pxegrub\.lst\.(?:[a-z\d_]+)>.

=cut

sub write_file {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $lines = shift;


	my $pid = start_wrapper(Schulkonsole::Config::LINBOWRITEAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$filename\n$lines";
	close \*SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}




=head2 delete_image($id, $password, $image)

Deletes a LINBO image

=head3 Parameters

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$image>

The filename of the image

=head3 Description

Deletes C<$image> in C</var/linbo/> and corresponding C<*.desc>, C<*.info>,
C<*.list>, and C<*.reg> files.

=cut

sub delete_image {
	my $id = shift;
	my $password = shift;
	my $image = shift;


	my $pid = start_wrapper(Schulkonsole::Config::LINBOIMAGEAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "0\n$image\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# update linbofs
	update_linbofs($id, $password);
}






=head2 move_image($id, $password, $image, $new_image)

Rename a LINBO image

=head3 Parameters

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$image>

The filename of the image

=item C<$new_image>

The filename of the image without C<*.cloop> or C<*.rsync> suffix

=head3 Description

Renames C<$image> in C</var/linbo/> and corresponding C<*.desc>, C<*.info>,
C<*.list>, and C<*.reg> files, using C<$new_image> as the new image name,
but keeping the suffix of the original name.

=cut

sub move_image {
	my $id = shift;
	my $password = shift;
	my $image = shift;
	my $new_image = shift;


	my $pid = start_wrapper(Schulkonsole::Config::LINBOIMAGEAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n$image\n$new_image\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# update linbofs
	update_linbofs($id, $password);
}





=head2 copy_image($id, $password, $image, $new_image)

Rename a LINBO image

=head3 Parameters

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$image>

The filename of the image

=item C<$new_image>

The filename of the image without C<*.cloop> or C<*.rsync> suffix

=head3 Description

Copies C<$image> in C</var/linbo/> and corresponding C<*.desc>, C<*.info>,
C<*.list>, and C<*.reg> files, using C<$new_image> as the new image name,
but keeping the suffix of the original name.

=cut

sub copy_image {
	my $id = shift;
	my $password = shift;
	my $image = shift;
	my $new_image = shift;


	my $pid = start_wrapper(Schulkonsole::Config::LINBOIMAGEAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "2\n$image\n$new_image\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# update linbofs
	update_linbofs($id, $password);
}






=head2 is_boolean($section, $key)

Check if a key corresponds to a boolean value

=head3 Parameters

=item C<$section>

The section of the key:
1 = C<[Partition], 2 = C<[OS], 3 = C<[LINBO]>

=item C<$key>

The key

=head3 Return value

True if key corresponds to a boolean value

=head3 Description

Check if a key C<$key> in a section C<$section> corresponds to a
boolean value.

=cut

sub is_boolean {
	my $section = shift;
	my $key = shift;

	return ($_allowed_keys{$section}{$key} == 4);
}






=head2 get_templates_os()

Get OS templates

=head3 Return value

A reference to a hash with the template name as key and the filename as
value.

=head3 Description

Returns the list of templates in C</usr/share/schulkonsole/linbo/templates/os>
as a hash.

=cut

sub get_templates_os {
	my %re;

	foreach my $file (glob("$Schulkonsole::Config::_linbo_templates_os_dir/*"))
	{
		my ($filename) = File::Basename::fileparse($file);
		$re{$filename} = $file;
	}


	return \%re;
}






sub string_to_type {
	my $type = shift;
	my $value = shift;

	SWITCHTYPE: {
	$type == 1 and do {	# string
		return undef if ($value =~ /#/);
		last SWITCHTYPE;
	};
	$type == 2 and do {	# decimal number
		return undef if ($value !~ /^\d*$/);
		last SWITCHTYPE;
	};
	$type == 3 and do {	# hex number
		$value = sprintf("%x", $value);
		return undef if (not $value);	# only for partition IDs
		last SWITCHTYPE;
	};
	$type == 4 and do {	# boolean
		$value = ($value ? 'yes' : 'no');
		last SWITCHTYPE;
	};
	}

	return $value;
}





sub line_with_new_value {
	my $key = shift;
	my $value = shift;
	my $line = shift;

	return "$key = $value\n" unless $line;

	my ($old_value, $rem) = $line =~ /^\S+\s*=\s*?(\S.*?)?(\s*#.*)$/;
	chomp $rem;
	$rem = substr $rem, 1 unless $old_value;

	return "$key = $value$rem\n";
}



1;



