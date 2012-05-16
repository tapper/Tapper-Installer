package Tapper::Installer;
# ABSTRACT: Tapper - Install everything needed for a test

use strict;
use warnings;

use Moose;
use Socket;
use URI::Escape "uri_escape";

extends 'Tapper::Base';
with 'MooseX::Log::Log4perl';

has cfg => (is      => 'rw',
            default => sub { {} },
           );
with 'Tapper::Remote::Net';

sub BUILD
{
        my ($self, $config) = @_;
        $self->{cfg}=$config;
}

=head1 FUNCTIONS

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
