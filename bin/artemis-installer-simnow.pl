#!/opt/artemis/bin/perl

use warnings;
use strict;
use Log::Log4perl;
use Artemis::Installer::Base;

BEGIN {
	Log::Log4perl::init('/etc/log4perl.cfg');
}

my $pid = fork();
die "Can not fork:$!" if not defined $pid;

if ($pid == 0) {
        my $client = new Artemis::Installer::Base;
        $client->system_install("simnow");
}


=pod

=head1 NAME

artemis-installer-client.pl - control the installation and setup of an automatic test system

=head1 SYNOPSIS

artemis-installer-client.pl 

=head1 DESCRIPTION

This program is the start script of the Artemis::Installer project. It calls
Artemis::Installer::Base which cares for the rest.

=cut
