package Tapper::Installer::Precondition;

use strict;
use warnings;

use Hash::Merge::Simple 'merge';
use File::Type;
use File::Basename;
use Moose;
use Socket;
use Sys::Hostname;
use YAML;


extends 'Tapper::Installer';

=head1 NAME

Tapper::Installer::Precondition - Base class with common functions
for Tapper::Installer::Precondition modules

=head1 SYNOPSIS

 use Tapper::Installer::Precondition;

=head1 FUNCTIONS

=cut


=head2 get_file_type

Return the file type of a given file. "rpm, "deb", "tar", "gzip", "bz2" and
"iso" 9660 cd images are recognised at the moment. If file does not exists at
the given file name, only suffix analysis will be available. To enforce any of
the above mentioned types, just set the suffix of the file accordingly.

@param string - file name

@returnlist success - (0, rpm|deb|iso|tar|gzip|bzip2)
@returnlist error   - (1, error string)

=cut

sub get_file_type
{
        my ($self, $file) = @_;
        my @file_split=split(/\./,$file);
        my $type=$file_split[-1];
        if ($type eq "iso") {
                return (0,"iso");
        } elsif ($type eq "gz" or $type eq "tgz") {
                return (0,"gzip");
        } elsif ($type eq "tar") {
                return (0,"tar");
        } elsif ($type eq "bz" or $type eq "bz2") {
                return (0,"bz2");
        } elsif ($type eq "rpm") {
                return(0,"rpm");
        } elsif ($type eq "deb") {
                return(0,"deb");
        }

        if (not -e $file) {
                return (0,"$file does not exist. Can't check file type");
        }
        my $ft = File::Type->new();
        $type = $ft->mime_type("$file");
        if ($type eq "application/octet-stream") {
                my ($error, $output)=$self->log_and_exec("file $file");
                return (0, "Getting file type of $file failed: $output") if $error;
                return (0,"iso") if $output =~m/ISO 9660/i;
                return (0,"rpm") if $output =~m/$file: RPM/i;
                return (0,"deb") if $output =~m/$file: Debian/i;
        } elsif ($type eq "application/x-dpkg") {
                return (0,"deb");
        } elsif ($type eq "application/x-gzip") {
                return (0,"gzip");
        } elsif ($type eq "application/x-gtar") {
                return (0,"tar");
        } elsif ($type eq "application/x-bzip2") {
                return (0,"bz2");
        } else {
                return(1, "$file is of unrecognised file type \"$type\"");
        }
}




=head2 gethostname

This function returns the host name of the machine. When NFS root is
used together with DHCP the hostname set in the kernel usually equals
the IP address received from DHCP as a string. In this case the kernel
hostname is set to the DNS hostname associated to this IP address.

@return hostname of the machine as set in the kernel

=cut

sub gethostname
{
        my ($self) = @_;
	my $hostname = Sys::Hostname::hostname();
	if ($hostname   =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                ($hostname) = gethostbyaddr(inet_aton($hostname), AF_INET) or ( print("Can't get hostname: $!") and exit 1);
                $hostname   =~ s/^(\w+?)\..+$/$1/;
                system("hostname", "$hostname");
        }
	return $hostname;
}


=head2 log_and_exec

Execute a given command. Make sure the command is logged if requested and none
of its output pollutes the console. In scalar context the function returns 0
for success and the output of the command on error. In array context the
function always return a list containing the return value of the command and
the output of the command.

@param string - command

@return success - 0
@return error   - error string
@returnlist success - (0, output)
@returnlist error   - (return value of command, output)

=cut

sub log_and_exec
{
        my ($self, @cmd) = @_;
        my $cmd = join " ",@cmd;
	$self->log->debug( $cmd );
        my $output=`$cmd 2>&1`;
        my $retval=$?;
        if (not defined($output)) {
                $output = "Executing $cmd failed";
                $retval = 1;
        }
        chomp $output if $output;
        if ($retval) {
                return ($retval >> 8, $output) if wantarray;
                return $output;
        }
        return (0, $output) if wantarray;
        return 0;
}



=head2 guest_install

Install a precondition inside a virtualisation guest. A guest can be
given as image, partition or directory. This function makes the
necessary preparations, calls the right precondition install function
and cleans up afterwards. An image can be given as file name and
partition or file name only. The later is supposed to be an image file
containing just one partition.

@param sub      - execute this function with base dir set to mounted image file
@param hash ref - define where to run the command

@return success - 0
@return error   - error string

=cut

sub guest_install
{
        my ($self, $sub, $partition, $image) = @_;
        return "can only be called from an object" if not ref($self);

        $image = $self->cfg->{paths}{base_dir}.$image;
        my ($error, $loop);
        $self->makedir($self->cfg->{paths}{guest_mount_dir}) if not -d $self->cfg->{paths}{guest_mount_dir};

        my $retval;
        if ($image and $partition) {
                # make sure loop device is free
                # don't use losetup -f, until it is available on installer NFS root
                $self->log_and_exec("losetup -d /dev/loop0"); # ignore error since most of the time device won't be already bound
                return $retval if $retval = $self->log_and_exec("losetup /dev/loop0 $image");
                return $retval if $retval = $self->log_and_exec("kpartx -a /dev/loop0");
                return $retval if $retval = $self->log_and_exec("mount /dev/mapper/loop0$partition ".$self->cfg->{paths}{guest_mount_dir});
        }
        elsif ($image and not $partition) {
                return $retval if $retval = $self->log_and_exec("mount -o loop $image ".$self->cfg->{paths}{guest_mount_dir});

        }
        else
        {
                return $retval if $retval = $self->get_device($partition);
                $partition = $retval;
                return $retval if $retval = $self->log_and_exec("mount $partition ".$self->cfg->{paths}{guest_mount_dir});
        }

        my $config = merge($self->cfg, {paths=> {base_dir=> $self->cfg->{paths}{guest_mount_dir}}});
        my $object = ref($self)->new($config);
        return $retval if $retval=$sub->($object);

        if ($image and $partition) {
                return $retval if $retval = $self->log_and_exec("umount /dev/mapper/loop0$partition");
                return $retval if $retval = $self->log_and_exec("kpartx -d /dev/loop0");
                if ($retval = $self->log_and_exec("losetup -d /dev/loop0")) {
                        sleep (2);
                        return $retval if $retval = $self->log_and_exec("kpartx -d /dev/loop0");
                        return $retval if $retval = $self->log_and_exec("losetup -d /dev/loop0");
                }
        }
        else
        {
                $retval = $self->log_and_exec("umount ".$self->cfg->{paths}{guest_mount_dir});
                $self->log->error("Can not unmount ".$self->cfg->{paths}{guest_mount_dir}.": $retval") if $retval;
        }

        # seems like mount -o loop uses a loop device that is not freed at umount
        if ($image) {
                $self->log_and_exec("kpartx -d /dev/loop0");
                $self->log_and_exec("losetup -d /dev/loop0");
        }

        return 0;
}


=head2 file_save

Save output as file for MCP to find it and upload it to reports receiver.

@param string - output to be written to file
@param string - basename of the file to write output to

@return success - 0
@return errorr  - error string

=cut

sub file_save
{
        my ($self, $output, $filename) = @_;
        my $testrun_id = $self->cfg->{test_run};
        my $destdir = $self->cfg->{paths}{output_dir}."/$testrun_id/install/";
        my $destfile = $destdir."/$filename";
        if (not -d $destdir) {
                system("mkdir","-p",$destdir) == 0 or return ("Can't create $destdir:$!");
        }
        open(my $FH,">",$destfile)
          or return ("Can't open $destfile:$!");
        print $FH $output;
        close $FH;
}



1;

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Tapper


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd
