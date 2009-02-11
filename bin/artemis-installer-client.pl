#!/home/artemis/perl510/bin/perl

use warnings;
use strict;
use Log::Log4perl;
use Artemis;
use Artemis::Installer::Client::Installer;

BEGIN {
	Log::Log4perl::init('/etc/log4perl.cfg');
}


my $client = new Artemis::Installer::Client::Installer;
$client->system_install();


=pod

=head1 NAME

local_control.pl - control the installation and setup of an automatic test system

=head1 SYNOPSIS

local_control.pl [--exec-dir=directory] [--mcp-host=hostname|IP address]
[--mcp-port=port number]  [--final=[0|1]] [--label=name] --test-run=number

=head1 DESCRIPTION


=head1 OPTIONS

Note: All options can be abbrevated as long as this abbrevations are not ambigious.

=over

=item --exec-dir=directory

All programs executed by this program are placed in this directory.

=item --mcp-host=hostname|IP address

This server is contacted to send our status information. Default is siegfried.amd.com. 

=item --mcp-port=port number

This is the destination port used to send status information. Default is 1337.

=item --test-run=number

The id of the test run to be used. There is no default for this.

=item --final=0|1

local_control.pl is used in two stages of the automatic test system:
installation of the test system and saving of log files. If --final is 0, the
installation will be executed, if any other number is given, log files are
saved. Default value is zero.

=item --label=name

Sets the label of the partition to use. Default is testing.


=back

=cut
