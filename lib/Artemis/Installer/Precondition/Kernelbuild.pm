package Artemis::Installer::Precondition::Kernelbuild;


use Moose;
use IO::Handle; # needed to set pipe nonblocking
extends 'Artemis::Installer::Precondition';

use strict;
use warnings;

=head1 NAME

Artemis::Installer::Precondition::Kernelbuild - Build and install a kernel from git

=head1 SYNOPSIS

 my $kernel_precondition = '
precondition_type: kernelbuild
git_url: git://osrc.amd.com/linux-2.6.git
changeset: HEAD
patchdir: /patches
';

 use Artemis::Installer::Precondition::Kernelbuild;
 $kernel = Artemis::Installer::Precondition::Kernelbuild->new($config);
 $kernel->install(YAML::Load($kernel_precondition));


=head1 FUNCTIONS

=cut

=head2 git_get

This function encapsulates getting a kernel source directory out of a git
repository. It changes the current directory into the the repository.

@param string - repository URL
@param string - revision in this repository


@return success - 0
@return error   - error string

=cut

sub git_get
{
	my ($self, $git_url, $git_rev)=@_;
        
        # git may generate more output than log_and_exec can handle, thus keep the system()
        chdir $self->cfg->{paths}{base_dir};
	system("git","clone","-q",$git_url,"linux") == 0 
          or return("unable to clone git repository $git_url");
	chdir ("linux");
        system("git","checkout",$git_rev) == 0 
          or return("unable to check out $git_rev from git repository $git_url");
	return(0);
}

=head2 make_kernel

Build and install a kernel and write all log messages to STDOUT/STDERR.

@return success - 0
@return error   - error string

=cut

sub make_kernel
{
        my ($self) = @_;
        chdir('linux');
        system("make","mrproper") == 0
          or return("Making mrproper failed: $!");
        
        system('yes ""|make oldconfig') == 0
          or return("Making oldconfig failed: $!");

        system('make','-j8') == 0
          or return("Build the kernel failed: $!");

        system('make','install') == 0 
          or return("Installing the kernel failed: $!");

        system('make','modules_install') == 0 
          or return("Installing the kernel failed: $!");

        return 0;
}

=head2 make_initrd

Build and install an initrd and write all log messages to STDOUT/STDERR.

@return success - 0
@return error   - error string

=cut

sub make_initrd
{
        my ($self) = @_;
        my ($error, $kernelversion) = $self->log_and_exec("make","kernelversion");
        return $kernelversion if $error;
        return "Can not get kernel version" unless $kernelversion;

        if (not -e "/boot/vmlinuz-$kernelversion") {
                $kernelversion .='+'; # handle broken release strings in current kernels
                return "kernel installed failed, /boot/vmlinuz-$kernelversion does not exist" 
                  if not -e "/boot/vmlinuz-$kernelversion";
        }
        
        system('mkinitrd -k /boot/vmlinuz-$kernelversion -i /boot/initrd-$kernelversion') == 0
          or return("Can not create initrd file, see log file");

        # prepare_boot called at the end of the install process will generate 
        # a grub entry for vmlinuz/initrd with no version string attached
        $error = $self->log_and_exec("ln -sf","/boot/vmlinuz-$kernelversion", "/boot/vmlinuz");
        return $error if $error;
        $error = $self->log_and_exec("ln -sf","/boot/initrd-$kernelversion", "/boot/initrd");
        return $error if $error;

        return 0;
}



=head2 install

Get the source if needed, prepare the config, build and install the
kernel and initrd file.

@param hash reference - contains all information about the kernel

@return success - 0
@return error   - error string

=cut

sub install
{
        my ($self, $build) = @_;
        my $git_url  = $build->{git_url} or return 'No git url given';
        my $git_rev  = $build->{git_changeset} || 'HEAD';

	$self->log->debug("Installing kernel from $git_url $git_rev");


	pipe (my $read, my $write);
	return ("Can't open pipe:$!") if not (defined $read and defined $write);


	# we need to fork for chroot
	my $pid = fork();
	return "fork failed: $!" if not defined $pid;

	# hello child
	if ($pid == 0) {
                close $read;
                my ($error, $output);

                # TODO: handle error
                ($error, $output) = $self->log_and_exec("mount -o bind /dev/ ".$self->cfg->{paths}{base_dir}."/dev");
                ($error, $output) = $self->log_and_exec("mount -t sysfs sys ".$self->cfg->{paths}{base_dir}."/sys");

                my $filename = $git_url.$git_rev;
                $filename =~ s/[^A-Za-z_-]+/_/g;

                my $testrun_id  = $self->cfg->{test_run};
                my $output_dir  = $self->cfg->{paths}{output_dir}."/$testrun_id/install/";
                $self->makedir($output_dir);


                my $output_file = $output_dir."/$filename";
                # dup output to file before git_get and chroot but inside child
                # so we don't need to care how to get rid of it at the end
                open (STDOUT, ">>$output_file.stdout") or print($write "Can't open output file $output_file.stdout: $!\n"),exit 1;
                open (STDERR, ">>$output_file.stderr") or print($write "Can't open output file $output_file.stderr: $!\n"),exit 1;

                $error = $self->git_get($git_url, $git_rev);
                if ($error) {
                        print(write $error,"\n");
                        exit $?;
                }


                $ENV{ARTEMIS_TESTRUN}         = $self->cfg->{test_run};
                $ENV{ARTEMIS_SERVER}          = $self->cfg->{mcp_host};
                $ENV{ARTEMIS_REPORT_SERVER}   = $self->cfg->{report_server};
                $ENV{ARTEMIS_REPORT_API_PORT} = $self->cfg->{report_api_port};
                $ENV{ARTEMIS_REPORT_PORT}     = $self->cfg->{report_port};
                $ENV{ARTEMIS_HOSTNAME}        = $self->cfg->{hostname};
                $ENV{ARTEMIS_OUTPUT_PATH}     = $output_dir;


		# chroot to execute script inside the future root file system
		chroot $self->cfg->{paths}{base_dir};
		chdir ("/");
                $error = $self->make_kernel();
                if ($error) {
                        print( $write $error, "\n");
                        exit 1;
                }

                $error = $self->make_initrd();
                if ($error) {
                        print( $write $error, "\n");
                        exit 1;
                }

                close $write;
                exit 0;
	} else {
                close $write;
                my $select = IO::Select->new( $read );
                my ($error, $output);
        MSG_FROM_CHILD:
                while (my @ready = $select->can_read()){
                        my $tmpout = <$read>;   # only $read can be in @ready, since no other FH is in $select
                        last MSG_FROM_CHILD if not $tmpout;
                        $output.=$tmpout;
                }
                $self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/dev");
                $self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/sys");
                waitpid($pid,0);
                if ($?) {
                        return("Building kernel from $git_url $git_rev failed: $output");
                }
		return(0);
	}
}
;


1;

=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Artemis


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 OSRC SysInt Team, all rights reserved.

This program is released under the following license: restrictive
