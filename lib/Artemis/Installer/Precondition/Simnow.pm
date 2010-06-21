package Artemis::Installer::Precondition::Simnow;

use Moose;
use common::sense;

use Artemis::Installer::Precondition::PRC;

extends 'Artemis::Installer::Precondition';


=head1 NAME

Artemis::Installer::Precondition::Simnow - Generate configs for Simnow

=head1 SYNOPSIS

 use Artemis::Installer::Precondition::Simnow;

=head1 FUNCTIONS

=cut

=head2 create_simnow_config

=cut

sub create_simnow_config
{
        my ($self, $config) = @_;
        my $simnow_script = $config->{files}{simnow_script} || 'startup.simnow';
        $config->{files}{config_file} = $config->{paths}{simnow_path}."/scripts/$simnow_script";
        return $config;
}



=head2 install

Install the tools used to control running of programs on the test
system. This function is implemented to fullfill the needs of kernel
testing and is likely to change dramatically in the future due to
limited extensibility. Furthermore, it has the name of the PRC hard
coded which isn't a good thing either.

@param hash ref - contains all information about the simnow instance

@return success - 0
@return error   - error string

=cut

sub install
{
        my ($self, $simnow) = @_;

        my $config;
        my $prc = Artemis::Installer::Precondition::PRC->new($self->cfg);
        $config = $prc->create_common_config();
        $config = $self->create_simnow_config($config);

        my $config_file = $self->cfg->{files}{simnow_config};

        YAML::DumpFile($config_file, $config);

        return 0;
}


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
