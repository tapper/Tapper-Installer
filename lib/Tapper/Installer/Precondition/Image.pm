package Tapper::Installer::Precondition::Image;

use strict;
use warnings;

use Method::Signatures;
use Moose;
extends 'Tapper::Installer::Precondition';

has images => ( isa => 'ArrayRef',
                is  => 'rw',
                default => sub {[]},
              );


=head1 NAME

Tapper::Installer::Precondition::Package - Install a package to a given location

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Image;

=head1 FUNCTIONS

=cut


=head2 get_device

Return device name (i.e. /dev/$device) for a given device-id, partition label
or $device name (with or without preceding /dev/).
Doesn't work with dev-mapper.

@param string - device or reference to array with device ids
@param string - base dir prepended to all paths (testing purpose) 

@returnlist success - ( 0, device name string)
@returnlist error   - ( 1, error string)

=cut

sub get_device
{
        my ($self, $devices, $basedir) = @_;
        $basedir ||= '/';           # basedir is only supposed for unit testing
        my @device_alternatives;
        if (ref($devices) eq 'ARRAY') {
                @device_alternatives = @$devices;
        } else {
                @device_alternatives = ($devices);
        }

        my $dev_symlink;
 ALTERNATIVE:
        foreach my $device_id (@device_alternatives) {
                if (-e "$basedir/dev/disk/by-label/".$device_id) {
                        $dev_symlink=readlink("$basedir/dev/disk/by-label/$device_id");
                        last ALTERNATIVE;
                } elsif (-e "$basedir/dev/disk/by-uuid/".$device_id) {
                        $dev_symlink = readlink("$basedir/dev/disk/by-uuid/$device_id");
                        last ALTERNATIVE;
                } elsif (-e "$basedir/dev/".$device_id or -e "$basedir/$device_id") {
                        $dev_symlink = $device_id;
                        last ALTERNATIVE;
                }

        }
        my $error_string = "No device named ";
        $error_string   .= join ", ", @device_alternatives;
        $error_string   .= " could be found";
        return(1, $error_string) if not $dev_symlink;

        my @linkpath=split("/", $dev_symlink); # split link to avoid /dev/disk/by-xyz/../../hda1, is way faster than regexp
        my $partition = $linkpath[-1];
        return (0,"/dev/$partition");
}



=head2 get_partition_label

Get the label of a partition to be able to set it again at mkfs.

@param string - device file

@returnlist success - (    0, partition label string)
@returnlist error   - ( != 0, error string)


=cut

method get_partition_label($device_file)
{
        return $self->log_and_exec("e2label $device_file");
};


=head2 configure_fstab

Write fstab on installed system based upon the installed images and
partitions.

@return success - 0
@return error   - error string

=cut

method configure_fstab()
{
	# Creates fstab-entry for the final partition

        print STDERR "Tapper::Installer::Precondition::Image.configure_fstab()\n";

        # ss5 sschwigo 2008-09-30 ">" to ">>", real append (does this fix the "missing /var" warnings?)
        open (my $FSTAB, ">>", $self->cfg->{paths}{base_dir}."/etc/fstab") or return "Can't open fstab for appending: $!";

        # write defaults for fstab
        print $FSTAB "proc\t/proc\tproc\tdefaults\t0 0\n","sysfs\t/sys\tsysfs\tnoauto\t0 0\n";

        foreach my $image (@{$self->cfg->{images}}) {
                print $FSTAB $image->{partition},"\t",$image->{mount},"\text3\tdefaults\t1 1\n";
        }

        close $FSTAB or return "Can't write fstab: $!"; # well, cases when close fails are rare but still exist
        return 0;
};

=head2 generate_pxe_grub

Generate a simple PXE grub config that forwards to local grub.

@return success - 0
@return error   - error string

=cut

sub generate_pxe_grub
{
        my ($self) = @_;

        my $partition = $self->cfg->{preconditions}->[0]->{partition};
        my $hostname = $self->gethostname();
	my $partition_number = $self->get_partition_number( $partition );
	my ($error, $grub_device) = $self->get_grub_device( $partition );
        return $grub_device if $error;

        

        my $filename = $self->cfg->{paths}{grubpath}."/$hostname.lst";
        open my $fh, ">", $filename or return "Can not open PXE grub file $filename: $!";
        print $fh
          "serial --unit=0 --speed=115200\n",
            "terminal serial\n",
              "timeout 2\n\n",
                "title Boot from first hard disc\n",
                  "chainloader (hd$grub_device,$partition_number)+1";
        close $fh or return "Closing PXE grub file $filename of NFS failed: $!";
        return 0;
};



=head2 copy_menu_lst

Copy menu.lst to NFS. We need the grub config file menu.lst on NFS because
thats where PXE grub expects it. Still we create the file on the local hard
drive because it's faster and allows users to boot with this config without
using PXE grub.

@return success - 0
@return error   - error string

=cut

method copy_menu_lst()
{
        my $hostname      = $self->gethostname();
        my $menu_lst_file = $self->cfg->{paths}{base_dir}."/boot/grub/menu.lst";

        my $tapper_conf  = $self->cfg->{paths}{grubpath};

        return $self->log_and_exec("cp $menu_lst_file $tapper_conf/$hostname.lst");
};

=head2 get_grub_device

Get the disc part of grub notation of a given device file eg. /dev/hda1.

@param string - device file name

@return success - (0, grub device notation)
@return eror    - (1, error string)

=cut

method get_grub_device($device_file)
{
        (my $grub_search_string = $device_file) =~ s/[0-9]//g;
        my $mount_point=$self->cfg->{paths}{base_dir};               # root partition will always be mounted there
        my ($error,$grub_device) = $self->log_and_exec("/usr/sbin/grub-install","--recheck",
                                                       "--root-directory=$mount_point --no-floppy $device_file | grep $grub_search_string");
        return ($error,$grub_device) if $error;
        $grub_device =~ s/[a-z()\/ \s]//g;
	if ($grub_device eq "") {
                $self->log->warn( "Grub device not found, took '0'");
                $grub_device = 0;
  	}
	return (0,$grub_device);
};


=head2 get_partition_number

Get the partition part of grub notation of a given device file eg. /dev/hda1.

@param string - partition number

@return int - grub device notation

=cut

method get_partition_number($device_file)
{
	(my $partition_number = $device_file) =~ s/[a-z\/]//g;
	$partition_number--;
	return $partition_number;
};

=head2 generate_grub_menu_lst

Create a grub config file (menu.lst) based on the options in the configuration
hash. The function is mainly a wrapper for create_menu_lst_entry and
create_new_menu_lst.

@return success - 0
@return error   - error string

=cut

method generate_grub_menu_lst()
{
        my $retval;

        return("First precondition is not the root image")
          if not $self->cfg->{preconditions}->[0]->{precondition_type} eq 'image'
            and $self->cfg->{preconditions}->[0]->{mount} eq '/';

        # XXX: use $self->images->[0] and check whether this is correct
        my $partition = $self->cfg->{preconditions}->[0]->{partition};

        if ($self->cfg->{grub}) {
                return $retval if $retval = $self->generate_user_grub_conf($partition);
        } else {
                return $retval if $retval = $self->create_new_menu_lst();
                return $retval if $retval = $self->create_menu_lst_entry($partition);
        }
	return 0;
};

=head2 create_menu_lst_entry

Create and entry for the installed kernel in menu.lst. The kernel must be
named /boot/vmlinuz.

@param string - name of the root partition

@return success - 0
@return error   - error string

=cut

method create_menu_lst_entry($device_file)
{
	my $partition_number     = $self->get_partition_number($device_file);
	my ($error,$grub_device) = $self->get_grub_device( $device_file);
        return $grub_device if $error;
        my $id                   = $self->cfg->{testrun};
        $id ||="unknown";
        my $entry                = "title Test run $id\n".
          "root (hd$grub_device,$partition_number)\n".
            "kernel /boot/vmlinuz root=$device_file earlyprintk=serial,ttyS0,115200 ".
              "console=ttyS0,115200 ip=dhcp noapic tapper_host=".$self->cfg->{server}."\n";
        $entry .= "initrd /boot/initrd\n\n" if -e $self->cfg->{paths}{base_dir}."/boot/initrd";


        return $self->write_menu_lst($entry,0);
};


=head2 create_new_menu_lst

Create a new menu.lst with default header information. Existing grub configs
are silently overwritten.

@return success - 0
@return error   - error string

=cut

method create_new_menu_lst()
{
        my $base = "serial --unit=0 --speed=115200\n".
          "terminal serial\n".
            "timeout 3\n".
              "default 0\n\n\n";
        return $self->write_menu_lst($base,"truncate");
};


=head2 write_menu_lst

Write content to grub file. This encapsulates writing to improve readability
and testability.

@param string - what to write
@param bool   - true = truncate ('>'), false = append ('>>') (append is default)

@return success - 0
@return error   - error string

=cut

method write_menu_lst($content, $truncate)
{
	my $menu_lst_file = $self->cfg->{paths}{base_dir}."/boot/grub/menu.lst";
        my $mode = '>>';
        if ($truncate) {
                $mode = '>';
        }

        open (my $FILE, $mode,$menu_lst_file) or return "Can't open $menu_lst_file for writing: $!";
        print $FILE $content;
        close $FILE or return "Can't write $menu_lst_file: $!"; # well, cases when close fails are rare but still exist;
        return 0;
}
;

=head2 install

Install a given image. This function is a wrapper for image
installer functions so the caller doesn't need to care for preparations.

@param hash reference - containing image name (image), mount point (mount) and
                        partition name (partition)

@return success - 0
@return error   - error string

=cut

method install($image)
{
        my $retval;

        # set partition name to the normalized value /dev/*
        my $partition=$image->{partition};
        my $error;
        ($error, $partition) = $self->get_device($partition);
        if ($error) {
                return $partition;
        }

        $image->{partition}=$partition;
        $self->log->debug("partition = $partition");

        # moint points are set relative to test system root but installation
        # needs it relative to current root
        my $mount_point=$image->{mount};
        $mount_point = $self->cfg->{paths}{base_dir}.$mount_point;
	$self->create_mount_point($mount_point);

        if ($image->{image}) {
                return $retval if $retval=$self->copy_image( $partition, $image->{image}, $mount_point);
        } else {
                $self->log->debug("No image to install on $partition, mounting old image to $mount_point");
                if ($retval=$self->log_and_exec("mount $partition $mount_point")) {
                        $self->images([ @{$self->images}, $mount_point ]);
                        return $retval;
                }
        }
        push (@{$self->cfg->{images}},$image);

        $self->log->debug("Image copied successfully");

        return 0;
};


=head2 generate_user_grub_conf

Generate grub config file menu.lst based upon user provided precondition.

@param string - name of the root partition

@return success - 0
@return error   - error string

=cut

method generate_user_grub_conf($device_file)
{
        my $mount_point=$self->cfg->{paths}{base_dir};
        my $conf_string=$self->cfg->{grub};

	my $partition_number = $self->get_partition_number($device_file);
	my ($error, $grub_device) = $self->get_grub_device( $device_file);
        return $grub_device if $error;

        $conf_string =~ s/\$root/$device_file/g;
        $conf_string =~ s/\$grubroot/(hd$grub_device,$partition_number)/g;

        return $self->write_menu_lst($conf_string, "truncate");
};



=head2 prepare_boot

Make installed system ready for boot from hard disk.

@return success - 0
@return error   - error string

=cut

method prepare_boot()
{
        my $retval = 0;
        return $retval if $retval = $self->configure_fstab();
        return $retval if $retval = $self->generate_grub_menu_lst( );
	return $retval if $retval = $self->generate_pxe_grub();
# 	return $retval if $retval = $self->copy_menu_lst();
        return 0;
};


=head2 create_mount_point

Create the mount point if its not an existing directory.

@param string - mount point path

@return success - 0
@return error   - error string


=cut

method create_mount_point($mount_point)
{
	# Creates mount_point if not exists
        if (not -d $mount_point) {
                unlink $mount_point;
                system("mkdir","-p","$mount_point") and return ("Can't create mount point $mount_point");
        }
        return 0;
};

=head2 install_image

Install an image on a given device and mount it to a given mount point. Make
sure to set partition label reasonably.

@param string - image file name
@param string - device file name
@param string - mount point relative to future test system

@return success - 0
@return error   - error string

=cut

method install_image($image_file, $device_file, $mount_point)
{
 	my ($error, $partition_size)=$self->log_and_exec("/sbin/blockdev --getsize64 $device_file");
        if ($error) {
                $self->log->warn("Can't get size of partition $device_file: $partition_size. Won't check if images fits.");
                $partition_size = 0;
        }

        my ($partition_label, $image_type);
        ($error, $image_type)=$self->get_file_type($image_file);

	($error, $partition_label) = $self->get_partition_label($device_file);
        if ($error) {
                $self->log->info("Can't get partition label of $device_file: $partition_label");
                $partition_label='';
        }
	$partition_label ||= "testing";

	if ($image_type eq "iso") {
                # ISO images are preformatted and thus bring their own
                # partition label
		return $self->install_image_iso($image_file, $partition_size, $device_file, $mount_point);
        } elsif ($image_type eq "tar") {
		return $self->install_image_tar($image_file, $partition_size, $device_file, $mount_point, $partition_label);
        } elsif ($image_type eq "gzip"){
		return $self->install_image_gz($image_file, $partition_size, $device_file, $mount_point, $partition_label);
        } elsif ($image_type eq "bz2") {
		return $self->install_image_bz2($image_file, $partition_size, $device_file, $mount_point, $partition_label);
        } else {
                return("Imagetype could not be detected");
	}
        return 0;
};


=head2 install_image_iso

Install an image of type iso.

@param string - image file name
@param int    - size of the target partition
@param string - device name of the target partition
@param string - directory to mount the installed image to

@return success - 0
@return error   - error string


=cut

method install_image_iso($image_file, $partition_size, $device_file, $mount_point)

{
        # -s return the size in byte
        if ( $partition_size and (-s $image_file) > $partition_size) {
                return("Image $image_file is to big for device $device_file");
        }
        $self->log->info( "Using image type iso" );
        my $retval;
        return $retval if $retval=$self->log_and_exec("dd if=$image_file of=$device_file");
        return $retval if $retval=$self->log_and_exec("mount $device_file $mount_point");
        $self->images([ @{$self->images}, $mount_point ]);

        return(0);
};


=head2 install_image_tar


Install an image of type tar.

@param string - image file name
@param int    - size of the target partition
@param string - device name of the target partition
@param string - directory to mount the installed image to
@param string - partition label

@return success - 0
@return error   - error string

=cut

method install_image_tar($image_file, $partition_size, $device_file, $mount_point, $partition_label)
{
        # -s return the size in byte
        if ( $partition_size and (-s $image_file) > $partition_size) {
                return("Image $image_file is to big for device $device_file");
        }
        $self->log->info( "Using image type tar" );
        my $retval;
        return $retval if $retval=$self->log_and_exec("mkfs.ext3 -q -L $partition_label $device_file");
        return $retval if $retval=$self->log_and_exec("mount $device_file $mount_point");
        $self->images([ @{$self->images}, $mount_point ]);

        return $retval if $retval=$self->log_and_exec("tar xf $image_file -C $mount_point");
        return 0;
};

=head2 install_image_gz

Install an image of type tar.gz.

@param string - image file name
@param int    - size of the target partition
@param string - device name of the target partition
@param string - directory to mount the installed image to
@param string - partition labeö

@return success - 0
@return error   - error string

=cut

method install_image_gz($image_file, $partition_size, $device_file, $mount_point, $partition_label)
{
        my $gz_factor=3.82;
        if ( $partition_size and (-s $image_file)*$gz_factor > $partition_size) {
                return("Image $image_file is to big for device $device_file");
        }
        $self->log->info( "Using image type gzip" );
        my $retval;
        return $retval if $retval=$self->log_and_exec("mkfs.ext3 -q -L $partition_label $device_file");
        return $retval if $retval=$self->log_and_exec("mount $device_file $mount_point");
        $self->images([ @{$self->images}, $mount_point ]);

        return $retval if $retval=$self->log_and_exec("tar xfz $image_file -C $mount_point");
        return 0;
};

=head2 install_image_bz2

Install an image of type tar.bz2.

@param string - image file name
@param int    - size of the target partition
@param string - device name of the target partition
@param string - directory to mount the installed image to
@param string - partition labeö

@return success - 0
@return error   - error string

=cut

method install_image_bz2($image_file, $partition_size, $device_file, $mount_point, $partition_label)
{
        my $bz2_factor=4.30;
        if ( $partition_size and (-s $image_file)*$bz2_factor > $partition_size) {
                return("Image $image_file is to big for device $device_file");
        }
        $self->log->info( "Using image type bzip2" );
        my $retval;
        return $retval if $retval=$self->log_and_exec("mkfs.ext3 -q -L $partition_label $device_file");
        return $retval if $retval=$self->log_and_exec("mount $device_file $mount_point");
        $self->images([ @{$self->images}, $mount_point ]);

        return $retval if $retval=$self->log_and_exec("tar xfj $image_file -C $mount_point");
        return 0;
};


=head2 copy_image

Install an image to a given partition and mount it to a given mount point.

@param string - device name
@param string - image file
@param string - mount point

@return success - 0
@return error   - error string

=cut

method copy_image($device_file, $image_file, $mount_point)
{
        $image_file = $self->cfg->{paths}{image_dir}.$image_file if not -e $image_file;

	# Image exists?
        if (not -e $image_file) {
                return("Image $image_file could not be found");
        }
	return $self->install_image($image_file, $device_file, $mount_point);
};

=head2 unmount

Umounts all images that were mounted during installation in reverse
order.

@return success - 0
@return error   - error string

=cut

sub unmount
{
        my ($self) = @_;
        foreach my $image (reverse @{$self->images}) {
                $self->log_and_exec('umount', $image);
        }
        return 0;
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
