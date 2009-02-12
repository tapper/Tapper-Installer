package Artemis::Installer;

use strict;
use warnings;

use Method::Signatures;
use Moose;
use Socket;

use Artemis;

with 'MooseX::Log::Log4perl';

our $VERSION = '2.000001';

=head1 NAME

Artemis::Installer - Install everything needed for a test.

=head1 SYNOPSIS

 use Artemis::Installer;

=head1 FUNCTIONS

=cut

has cfg => (is      => 'rw',
            default => sub { {server=>undef, port => 1337} },
           );

method BUILD($config) 
{
        $self->{cfg}=$config;
};



=head2 mcp_inform

Tell the MCP server our current status. This is done using a TCP connection.

@param string - message to send to MCP

@return success - 0
@return error   - -1

=cut

method mcp_inform($msg)
{
        my $server = $self->cfg->{mcp_host};
        my $port   = $self->cfg->{mcp_port};

        $self->log->debug(qq(Sending status message "$msg" to MCP host "$server" on port $port));

	if (my $sock = IO::Socket::INET->new(PeerAddr => $server,
					     PeerPort => $port,
					     Proto    => 'tcp')){
		$sock->print($msg,"\n");
		close $sock;
	} else {
		$self->log->warn("Can't connect to MCP: $!");
                return(-1);
	}
        return(0);
};

=head2  logdie

Tell the MCP server our current status, then die().

@param string - message to send to MCP

=cut


method logdie($msg)
{
        if ($self->cfg->{mcp_host}) {
                $self->mcp_inform("error-install:$msg");
        } else {
                $self->log->error("Can't inform MCP, no server is set");
        }
        die $msg;
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


