#!/opt/tapper/bin/perl

use warnings;
use strict;
use Log::Log4perl;
use Tapper::Installer::Base;

BEGIN {
	Log::Log4perl::init('/etc/log4perl.cfg');
}


my $client = new Tapper::Installer::Base;
$client->system_install("");


=pod

=head1 NAME

tapper-installer-client.pl - control the installation and setup of an automatic test system

=head1 SYNOPSIS

tapper-installer-client.pl 

=head1 DESCRIPTION

This program is the start script of the Tapper::Installer project. It calls
Tapper::Installer::Base which cares for the rest.

=cut
