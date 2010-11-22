#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

my @modules = (
               'Artemis::Installer',
               'Artemis::Installer::Base',
               'Artemis::Installer::Precondition',
               'Artemis::Installer::Precondition::Copyfile',
               'Artemis::Installer::Precondition::Exec',
               'Artemis::Installer::Precondition::Fstab',
               'Artemis::Installer::Precondition::Image',
               'Artemis::Installer::Precondition::Kernelbuild',
               'Artemis::Installer::Precondition::Package',
               'Artemis::Installer::Precondition::PRC',
               'Artemis::Installer::Precondition::Rawimage',
               'Artemis::Installer::Precondition::Repository',
               'Artemis::Installer::Precondition::Simnow',
              );

plan tests => 2*(int @modules);

foreach my $module(@modules) {
        require_ok($module);
        my $obj = $module->new;
        isa_ok($obj, $module, "Object");
}






diag( "Testing Artemis $Artemis::Installer::VERSION, Perl $], $^X" );
