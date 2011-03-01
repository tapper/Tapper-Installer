package Tapper::Installer::Precondition::Package;

use strict;
use warnings;

use Method::Signatures;
use Moose;
extends 'Tapper::Installer::Precondition';


=head1 NAME

Tapper::Installer::Precondition::Package - Install a package to a given location

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Package;

=head1 FUNCTIONS

=cut


=head2 install

This function encapsulates installing one single package. At the moment, .tar,
.tar.gz, .tar.bz2, rpm and deb are recognised.

@param hash reference - contains all information about the package

@return success - 0
@return error   - error string

=cut

method install ($package)
{
        my $filename = $package->{filename};
	$self->log->debug("installing $filename");

        my $basedir     = $self->cfg->{paths}{base_dir};
        my $package_dir = '';
        $package_dir    = $self->cfg->{paths}{package_dir} unless $filename =~m(^/);
        my $pkg         = "$package_dir/$filename";
          
        my ($error, $type) = $self->get_file_type("$pkg");
        return("Can't get file type of $filename: $type") if $error;


        my $output;
        $self->log->debug("type is $type");
        if ($type eq "gzip") {
                ($error, $output) = $self->log_and_exec("tar --no-same-owner -C $basedir -xzf $pkg");
                return("can't unpack package $filename: $output\n") if $error;
        } elsif ($type eq "tar") {
                ($error, $output) = $self->log_and_exec("tar --no-same-owner -C $basedir -xf $pkg");
                return("can't unpack package $filename: $output\n") if $error;
        } elsif ($type eq "bz2") {
                ($error, $output) = $self->log_and_exec("tar --no-same-owner -C $basedir -xjf $pkg");
                return("can't unpack package $filename: $output\n") if $error;
        } elsif ($type eq "deb") {
                ($error, $output) = $self->log_and_exec("dpkg --root $basedir -i $pkg");
                return("can't install package $filename: $output\n") if $error;
        } elsif ($type eq "rpm") {
                # use -U to overwrite possibly existing	older package
                ($error, $output) = $self->log_and_exec("rpm -U --root $basedir $pkg"); 
                return("can't install package $filename: $output\n") if $error;
        } else {
                # has to be print, because we return our error message
                # through the pipe
                $self->log->warn("$pkg is of unrecognised file type \"$type\"");
                return("$pkg is of unrecognised file type \"$type\"");
        }
        return(0);
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
