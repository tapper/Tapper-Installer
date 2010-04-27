#!/opt/artemis/bin/perl

use warnings;
use strict;
use Log::Log4perl;
use Daemon::Daemonize qw/:all/;

use Artemis::Installer::Base;

BEGIN {
	Log::Log4perl::init('/etc/log4perl.cfg');
}

# don't use the config of the last simnow session
system("rm","/etc/artemis") if -e "/etc/artemis";


Daemon::Daemonize->daemonize(close => "std");


my $client = new Artemis::Installer::Base;
$client->system_install("simnow");




=pod

=head1 NAME

artemis-installer-client.pl - control the installation and setup of an automatic test system

=head1 SYNOPSIS

artemis-installer-client.pl 

=head1 DESCRIPTION

This program is the start script of the Artemis::Installer project. It calls
Artemis::Installer::Base which cares for the rest.

=cut
