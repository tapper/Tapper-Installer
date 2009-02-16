package Artemis::Installer::Base;

use strict;
use warnings;

use Method::Signatures;
use Moose;

use Artemis::Installer::Config;
use Artemis::Installer::Precondition::Image;
use Artemis::Installer::Precondition::Package;
use Artemis::Installer::Precondition::Copyfile;
use Artemis::Installer::Precondition::Fstab;
use Artemis::Installer::Precondition::PRC;
use Artemis::Installer::Precondition::Rawimage;
use Artemis::Installer::Precondition::Repository;
use Artemis::Installer::Precondition::Exec;

extends 'Artemis::Installer';

=head1 NAME

Artemis::Installer::Base - Install everything needed for a test.

=head1 SYNOPSIS

 use Artemis::Installer::Base;

=head1 FUNCTIONS

=cut


=head2 precondition_install

Encapsulate choosing where to install a precondition. Makes system_install
function smaller and thus more readable.

@param hash ref - describes precondition to be installed
@param object   - object of precondition type, used to install

@return success - 0
@return error   - error string

=cut

method precondition_install($precondition, $inst_obj)
{
        # guest in given partition, can be a /dev/partition or a partition in a rawimage file
        if ($precondition->{mountpartition}) {
                my $mountfile;
                $mountfile = $precondition->{mountfile} if $precondition->{mountfile};
                # $obj is given to the anonymous sub when the sub is called inside guest_install. 
                # This is the way to get an appropriate object with correctly set base directory.
                # $precondition on the other hand is set in here and the sub carries it to guest_install.
                return $inst_obj->guest_install(sub{
                                                        my ($obj) = @_; 
                                                        $obj->install($precondition);
                                                },
                                                $precondition->{mountpartition},
                                                $mountfile);
        } 
        # guest in given raw image file without partitions
        elsif ($precondition->{mountfile}) {
                return $inst_obj->guest_install(sub{
                                                        my ($obj) = @_; 
                                                        $obj->install($precondition);
                                                },undef, $precondition->{mountfile});
        } else {
                return $inst_obj->install($precondition);
        }
        return 0;
}
;

=head2 system_install

Install whatever has to be installed. This function is a wrapper around all
other system installer functions and calls them appropriately. Note that the
function will not return in case of an error. Instead it throws an exception with
should be send to the server by Log4perl.

=cut

method system_install()
{
        my $retval;
        # fetch configurations from the server
        my $consumer = Artemis::Installer::Config->new;
        
        # try to get host for error reporting as soon as possible
        my $host = $consumer->get_artemis_host();
        $self->cfg->{mcp_server}=$host if $host;

        my $config=$consumer->get_local_data('install');
        $self->logdie($config) if not ref($config) eq 'HASH';

        $self->{cfg}=$config;
        $self->logdie("can't get local data: $config") if ref $config ne "HASH";

        # Just mount everything in the fstab. This isn't perfect but enough for now.
        system("mount","-a");
        
        $self->log->info("Starting installation of test machine");
        $self->mcp_inform("start-install");

        $self->logdie("First precondition is not the root image") 
          if not $config->{preconditions}->[0]->{precondition_type} eq 'image' 
            and $config->{preconditions}->[0]->{mount} eq '/';

        foreach my $precondition (@{$config->{preconditions}}) {
                if ($precondition->{precondition_type} eq 'image')
                {
                        my $image=Artemis::Installer::Precondition::Image->new($config);
                        $self->logdie($retval) if $retval = $self->precondition_install($precondition, $image);
                }
                elsif ($precondition->{precondition_type} eq 'package')
                {
                        my $package=Artemis::Installer::Precondition::Package->new($config);
                        $self->logdie($retval) if $retval = $self->precondition_install($precondition, $package);
                }
                elsif ($precondition->{precondition_type} eq 'copyfile')
                {
                        my $copyfile = Artemis::Installer::Precondition::Copyfile->new($config);
                        $self->logdie($retval) if $retval = $self->precondition_install($precondition, $copyfile);
                }
                elsif ($precondition->{precondition_type} eq 'fstab')
                {
                        my $fstab = Artemis::Installer::Precondition::Fstab->new($config);
                        $self->logdie($retval) if $retval = $self->precondition_install($precondition, $fstab);
                }
                elsif ($precondition->{precondition_type} eq 'prc')
                {
                        my $prc=Artemis::Installer::Precondition::PRC->new($config);
                        $self->logdie($retval) if $retval = $self->precondition_install($precondition, $prc);
                }
                elsif ($precondition->{precondition_type} eq 'rawimage')
                {
                        my $rawimage=Artemis::Installer::Precondition::Rawimage->new($config);
                        $self->logdie($retval) if $retval = $self->precondition_install($precondition, $rawimage);
                }
                elsif ($precondition->{precondition_type} eq 'repository')
                {
                        my $repository=Artemis::Installer::Precondition::Repository->new($config);
                        $self->logdie($retval) if $retval = $self->precondition_install($precondition, $repository);
                }
                elsif ($precondition->{precondition_type} eq 'exec')
                {
                        my $exec=Artemis::Installer::Precondition::Exec->new($config);
                        $self->logdie($retval) if $retval = $self->precondition_install($precondition, $exec);
                }
        }

        my $image=Artemis::Installer::Precondition::Image->new($config);
        $self->logdie($retval) if $retval = $image->prepare_boot();

        $self->mcp_inform("end-install");
        $self->log->info("Finished installation of test machine");

        system("reboot") if not $config->{installer_stop};
        return 0;
};


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

