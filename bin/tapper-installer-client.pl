#! /usr/bin/perl
# PODNAME: tapper-installer-client
# ABSTRACT: cmdline frontend to Installer

use warnings;
use strict;
use Log::Log4perl;
use Tapper::Installer::Base;
use Tapper::Config;

BEGIN {
        Tapper::Config::_switch_context; # reload config
        my $l4p_cfg = Tapper::Config->subconfig->{files}{log4perl_cfg};
        Log::Log4perl::init($l4p_cfg);
}


my $client = Tapper::Installer::Base->new();
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
