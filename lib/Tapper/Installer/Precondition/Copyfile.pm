package Tapper::Installer::Precondition::Copyfile;

use strict;
use warnings;

use Method::Signatures;
use Moose;
use YAML;
use File::Basename;
extends 'Tapper::Installer::Precondition';


=head1 NAME

Tapper::Installer::Precondition::Copyfile - Install a file to a given location

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Copyfile;

=head1 FUNCTIONS

=cut

=head2 install

This function encapsulates installing one single file. scp, nfs and
local are supported protocols.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=cut

method install($file)
{
        return ('no filename given to copyfile::install') if not $file->{name};
        return ('no destination given for '.$file->{name}) if not $file->{dest};

        $file->{dest} = $self->cfg->{paths}{base_dir}.$file->{dest};

        $self->log->warn("no protocol given, try to use 'local'") and $file->{protocol}='local' if not $file->{protocol};

        my $retval;
        if ($file->{protocol} eq 'nfs') {
                $retval = $self->install_nfs($file)
        } elsif ($file->{protocol} eq 'rsync') {
                $retval = $self->install_rsync($file)
        } elsif ($file->{protocol} eq 'local') {
                $retval = $self->install_local($file)
        } elsif ($file->{protocol} eq 'scp') {
                $retval = $self->install_scp($file)
        } else {
                return 'File '.$file->{name}.' has unknown protocol type '.$file->{protocol};
        }

        $retval = $self->copy_prc($file) if $file->{copy_prc};
        return $retval;
};



=head2 install_local

Install a file from a local source.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=cut

method install_local($file) {
	my $dest_filename = '';   # get rid of the "uninitialised" warning
        my ($dest_path, $retval);

        if ($file->{dest} =~ m(/$)) {
                $dest_path =  $file->{dest};
        } else {
                ($dest_filename, $dest_path, undef) = fileparse($file->{dest});
                $dest_path .= '/' if $dest_path !~ m(/$);
        }
        return $retval if $retval = $self->makedir($dest_path);

        $self->log->debug("Copying ".$file->{name}." to $dest_path$dest_filename");
        system("cp","--sparse=always","-r","-L",$file->{name},$dest_path.$dest_filename) == 0 
          or return "Can't copy ".$file->{name}." to $dest_path$dest_filename:$!";

	return(0);
};


=head2 install_nfs

Install a file from an nfs share.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=cut

method install_nfs($file)
{
	my ($filename, $path, $retval, $error);
        my $nfs_dir='/mnt/nfs';

        if ( $file->{name} =~ m,/$, ) {
                return 'File name is a directory. Installing directory preconditions is not yet supported';
        } else        {
                ($filename, $path, undef) = fileparse($file->{name});
                $path .= '/' if $path !~ m,/$,;
        }

        $self->makedir($nfs_dir) if not -d $nfs_dir;
        
        $self->log->debug("mount -a $path $nfs_dir");

        ($error, $retval) = $self->log_and_exec("mount $path $nfs_dir");
        return ("Can't mount nfs share $path to $nfs_dir: $retval") if $error;
        $file->{name} = "$nfs_dir/$filename";
        $retval =  $self->install_local($file);


        $self->log_and_exec("umount $nfs_dir");
        return $retval;
};


=head2 install_scp

Install a file using scp.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=cut

method install_scp($file)
{
        my $dest = $self->cfg->{paths}{base_dir}.$file->{dest};

        #(XXX) Bad solution, find a better one
        system("scp","-r",$file->{name},$dest);
        return $self->install_local($file);
};




=head2 install_rsync

Install a file using rsync.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=cut

method install_rsync($file)
{
        return "Not implemented yet.";
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
