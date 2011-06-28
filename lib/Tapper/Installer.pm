package Tapper::Installer;

use strict;
use warnings;

use Moose;
use Socket;
use URI::Escape "uri_escape";

extends 'Tapper::Base';
with 'MooseX::Log::Log4perl';

our $VERSION = '3.000010';

=head1 NAME

Tapper::Installer - Tapper - Install everything needed for a test

=head1 SYNOPSIS

 use Tapper::Installer;

=head1 FUNCTIONS

=cut

has cfg => (is      => 'rw',
            default => sub { {} },
           );
with 'Tapper::Remote::Net';

sub BUILD
{
        my ($self, $config) = @_;
        $self->{cfg}=$config;
}

=head2  logdie

Tell the MCP server our current status, then die().

@param string - message to send to MCP

=cut


sub logdie
{
        my ($self, $msg) = @_;
        if ($self->cfg->{mcp_host}) {
                $self->mcp_send({state => 'error-install', error => $msg});
        } else {
                $self->log->error("Can't inform MCP, no server is set");
        }
        die $msg;
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


