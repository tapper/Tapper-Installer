package Artemis::Config::Consumer;

use strict;
use warnings;

use Getopt::Long;
use Log::Log4perl;
use Method::Signatures;
use Moose;
use Net::TFTP;
use Socket;
use Sys::Hostname;
use YAML::Syck;


=head1 NAME

Artemis::Config::Consumer - Get configuration from Artemis host

=head1 SYNOPSIS

 use Artemis::Config::Consumer;

=head1 FUNCTIONS

=cut


=head2 get_artemis_host

Get hostname of artemis MCP host from kernel boot parameters.

@returnlist ($host,port) - string, int - hostname and port of MCP server

=cut

method get_artemis_host()
{
        # try options set on command line
        my ($host,$port);
        Getopt::Long::GetOptions("host=s" => \$host,
                                 "port=s" => \$port,);
        return($host,$port) if $host;

        # try kernel command line
        open FH,'<','/proc/cmdline';
        my $cmd_line = <FH>;
        close FH;
        ($host,undef,$port) = $cmd_line =~ m/artemis_host\s*=\s*(\w+)(:(\d+))?/;
        return($host,$port);

        # try multicast
};


=head2 gethostname

This function returns the host name of the machine. When NFS root is
used together with DHCP the hostname set in the kernel usually equals
the IP address received from DHCP as a string. In this case the kernel
hostname is set to the DNS hostname associated to this IP address.

@return hostname of the machine as set in the kernel

=cut

method gethostname
{
	my $hostname = Sys::Hostname::hostname();
	if ($hostname   =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                ($hostname) = gethostbyaddr(inet_aton($hostname), AF_INET) or ( print("Can't get hostname: $!") and exit 1);
                $hostname   =~ s/^(\w+?)\..+$/$1/;
                system("hostname", "$hostname");
        }
	return $hostname;
};



=head2 img_cmp

Compare two images so that sort() can sort the root image (to be mounted on
"/") in front of all others. It expects no parameters but instead uses the
global variables $a and $b provided by sort().


@return -1 if left image is root image
         1 if right image is root image
         0 else

=cut

method img_cmp()
{
        return -1 if $a->{mount} eq '/';
        return  1 if $b->{mount} eq '/';
        return  0;
};



=head2 get_local_data

Get local data needed for all tools running locally on NFS. The function tries
to get the MCP host and fetches the config from there. This reduces any need
for configuration outside MCP host and thus allows to use unchanged NFS root
file systems for both testing and production, with different MCP servers and
so on. 

@return success - hash reference containing the config
@return error   - error string 

=cut

method get_local_data($state)
{
        # logger will usually be initialised by caller
        my $logger = Log::Log4perl->get_logger('installer.getconf');
        my $file;
        my $tmpcfg={}; # needed to set config options only used in some states

        my $hostname      = $self->gethostname();
        my ($server, $port) = $self->get_artemis_host();
        my $tftp          = Net::TFTP->new($server);
        $logger->debug("Fetching $hostname-$state from $server");
        $file             = $tftp->get("$hostname-$state") or return("Can't get local data.",$tftp->error);
        $tmpcfg->{server} = $server;
        $tmpcfg->{port}   = $port;

        my $config = YAML::Syck::LoadFile($file) or return ("Can't parse config received from server");
        $config->{hostname} = $hostname;
        # even though, this should always be set, provide as much information as we can 
        if ($config->{images} and ref($config->{images}) eq "ARRAY") {
                @{$config->{images}}=sort img_cmp @{$config->{images}}; # root partition has to be first
        }
        %$config=(%$config, %$tmpcfg);

        return $config;
}
;




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

