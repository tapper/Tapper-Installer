#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 24;

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

my $obj;

$obj = new Artemis::Installer;
isa_ok($obj, "Artemis::Installer", "Object");

$obj = new Artemis::Installer::Config;
isa_ok($obj, "Artemis::Installer::Config", "Object");

$obj = new Artemis::Installer::Precondition;
isa_ok($obj, "Artemis::Installer::Precondition", "Object");

$obj = new Artemis::Installer::Precondition::Copyfile;
isa_ok($obj, "Artemis::Installer::Precondition::Copyfile", "Object");

$obj = new Artemis::Installer::Precondition::Exec;
isa_ok($obj, "Artemis::Installer::Precondition::Exec", "Object");

$obj = new Artemis::Installer::Precondition::Fstab;
isa_ok($obj, "Artemis::Installer::Precondition::Fstab", "Object");

$obj = new Artemis::Installer::Precondition::Image;
isa_ok($obj, "Artemis::Installer::Precondition::Image", "Object");

$obj = new Artemis::Installer::Precondition::Package;
isa_ok($obj, "Artemis::Installer::Precondition::Package", "Object");

$obj = new Artemis::Installer::Precondition::PRC;
isa_ok($obj, "Artemis::Installer::Precondition::PRC", "Object");

$obj = new Artemis::Installer::Precondition::Rawimage;
isa_ok($obj, "Artemis::Installer::Precondition::Rawimage", "Object");

$obj = new Artemis::Installer::Precondition::Repository;
isa_ok($obj, "Artemis::Installer::Precondition::Repository", "Object");

$obj = new Artemis::Installer::Base;
isa_ok($obj, "Artemis::Installer::Base", "Object");




diag( "Testing Artemis $Artemis::VERSION, Perl $], $^X" );
