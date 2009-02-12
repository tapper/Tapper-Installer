#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
        use_ok( 'Artemis::Installer' );
        use_ok( 'Artemis::Installer::Config' );
        use_ok( 'Artemis::Installer::Precondition' );
        use_ok( 'Artemis::Installer::Precondition::Copyfile' );
        use_ok( 'Artemis::Installer::Precondition::Exec' );
        use_ok( 'Artemis::Installer::Precondition::Fstab' );
        use_ok( 'Artemis::Installer::Precondition::Image' );
        use_ok( 'Artemis::Installer::Precondition::Package' );
        use_ok( 'Artemis::Installer::Precondition::PRC' );
        use_ok( 'Artemis::Installer::Precondition::Rawimage' );
        use_ok( 'Artemis::Installer::Precondition::Repository' );
        use_ok( 'Artemis::Installer::Base' );

}

diag( "Testing Artemis $Artemis::VERSION, Perl $], $^X" );
