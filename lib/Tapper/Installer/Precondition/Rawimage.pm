package Tapper::Installer::Precondition::Rawimage;

use strict;
use warnings;

use File::Path;
use Method::Signatures;
use Moose;
extends 'Tapper::Installer::Precondition';


=head1 NAME

Tapper::Installer::Precondition::Rawimage - Create a raw image to be used as guest root for virtualisation

This precondition should only be created when parsing "virt" preconditions. It's not useful for kernel developers.

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Rawimage;

=head1 FUNCTIONS

=cut

=head2 install

Create the raw image.

@param hash ref - contains all information about the image to be created

@return success - 0
@return error   - return value of system or error string

=cut

method install($img)
{
        return "not filename given for rawimage" if not $img->{name};

        my $img_size = 2048*1024; # 2GByte - size of standard rawimage in kbyte 

        my $filename = $img->{name};
        my $path     = $self->cfg->{paths}{base_dir}.$img->{path};
        my $size     = $img->{size} || $img_size;
        my ($error, $retval);

        if (not -d $path) {
                mkpath($path, {error => \$error});
                foreach my $diag (@$error) {
                        my ($file, $message) = each %$diag;
                        return "general error: $message\n" if $file eq '';
                        return "Can't create $file: $message";
                }
        }
        
        $filename = $path."/".$filename;

        ($error, $retval) = $self->log_and_exec("dd if=/dev/zero of=$filename bs=1024 count=$size");
        return $retval if $error;

        ($error, $retval) = $self->log_and_exec("/sbin/mkfs.ext3 -F -L tapper $filename");
        return $retval if $error;
        
        $self->makedir($self->cfg->{paths}{guest_mount_dir}) if not -d $self->cfg->{paths}{guest_mount_dir};
        ($error, $retval) = $self->log_and_exec("mount -o loop $filename ".$self->cfg->{paths}{guest_mount_dir});
        return $retval if $error;
        my $mountdir = $self->cfg->{paths}{guest_mount_dir};
        
        mkdir ("$mountdir/etc") or return ("Can't create /etc in raw image $filename: $!");
        open(my $FH,">","$mountdir/etc/tapper-release") or return "Can't open /etc/tapper-release in raw image $filename: $!";
        print $FH "Tapper";
        close $FH;

        ($error, $retval) = $self->log_and_exec("umount $mountdir");
        return $retval if $error;
        return 0;
}
;

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
