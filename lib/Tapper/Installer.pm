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

sub BUILD
{
        my ($self, $config) = @_;
        $self->{cfg}=$config;
}


=head2 mcp_inform

Tell the MCP server our current status. This is done using a TCP connection.

@param hash ref - message to send to MCP

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

@param hash ref - message to send to MCP

@return success - 0
@return error   - error string

=cut

sub mcp_send
{
        my ($self, $message) = @_;
        my $server = $self->cfg->{mcp_host} or return "MCP host unknown";
        my $port   = $self->cfg->{mcp_port} or return "MCP port unknown";
        $message->{testrun_id} ||= $self->cfg->{testrun_id};
        my %headers;

        my $url = "GET /state/";
        
        # state always needs to be first URL part because server uses it as filter
        $url   .= $message->{state} || 'unknown';
        delete $message->{state};

        foreach my $key (keys %$message) {
                if ($message->{$key} =~ m|/| ) {
                        $headers{$key} = $message->{$key};
                } else {
                        $url .= "/$key/";
                        $url .= uri_escape($message->{$key});
                }
        }
        $url .= " HTTP/1.0\r\n";
        foreach my $header (keys %headers) {
                $url .= "X-Tapper-$header: ";
                $url .= $headers{$header};
                $url .= "\r\n";
        }

	if (my $sock = IO::Socket::INET->new(PeerAddr => $server,
					     PeerPort => $port,
					     Proto    => 'tcp')){
		$sock->print("$url\r\n");
		close $sock;
	} else {
                $self->log->error("Can't connect to MCP: $!");
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


