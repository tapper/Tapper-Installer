package Tapper::Installer::Precondition::Fstab;

use strict;
use warnings;

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

sub install {
        my ($self, $precond) = @_;

        my ($filename, $path, $retval);

        my $basedir = $self->cfg->{paths}{base_dir};
        my $line = $precond->{line};

        my $cmd = '(echo "" ; echo "# precond::fstab" ; echo "'.$line.'" ) >> '.$basedir.'/etc/fstab';

        $self->log->debug($cmd);

        system($cmd) == 0 or return ("Could not patch /etc/fstab: $!");
        return 0;
}

1;
