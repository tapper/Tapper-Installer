package Tapper::Installer;

use strict;
use warnings;

use Moose;
use Socket;
use YAML::Syck;

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
            default => sub { {server=>undef, port => 1337} },
           );

sub BUILD
{
        my ($self, $config) = @_;
        $self->{cfg}=$config;
}


=head2 mcp_inform

Tell the MCP server our current status. This is done using a TCP connection.

@param string - message to send to MCP

@return success - 0
@return error   - -1

=cut

sub mcp_inform
{
        my ($self, $msg) = @_;
        my $message = {state => $msg};
        return $self->mcp_send($message);
}



=head2 mcp_send

Tell the MCP server our current status. This is done using a TCP connection.

@param string - message to send to MCP

@return success - 0
@return error   - error string

=cut

sub mcp_send
{
        my ($self, $message) = @_;
        my $server = $self->cfg->{mcp_host} or return "MCP host unknown";
        my $port   = $self->cfg->{mcp_port} || 7357;
        $message->{testrun_id} ||= $self->cfg->{testrun_id};

        my $yaml = Dump($message);
	if (my $sock = IO::Socket::INET->new(PeerAddr => $server,
					     PeerPort => $port,
					     Proto    => 'tcp')){
		print $sock ("$yaml");
		close $sock;
	} else {
                return("Can't connect to MCP: $!");
	}
        return(0);
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


