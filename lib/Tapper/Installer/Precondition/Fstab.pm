package Tapper::Installer::Precondition::Fstab;

use strict;
use warnings;

use Method::Signatures;
use Moose;
use YAML;
use File::Basename;
extends 'Tapper::Installer::Precondition';


=head1 NAME

Tapper::Installer::Precondition::Fstab - Insert a line into /etc/fstab

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Fstab;

=head1 FUNCTIONS

=cut

=head2 install

Install a file from an nfs share.

@param hash reference - contains all precondition information

@return success - 0
@return error   - error string

=cut

method install($precond)
{
	my ($filename, $path, $retval);

        my $basedir = $self->cfg->{paths}{base_dir};
        my $line = $precond->{line};

        my $cmd = '(echo "" ; echo "# precond::fstab" ; echo "'.$line.'" ) >> '.$basedir.'/etc/fstab';

        $self->log->debug($cmd);

        system($cmd) == 0 or return ("Could not patch /etc/fstab: $!");
        return 0;
};

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
